use std::collections::{BTreeMap, BTreeSet};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, RecvTimeoutError, SyncSender, TryRecvError};
use std::thread::{self, JoinHandle};
use std::time::Duration;

use aonw_ai::StrategicPlanner;
use aonw_contracts::client::CLIENT_API_VERSION;
use aonw_local_runtime::{ClientProtocol, LocalRuntime};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

const BUILD_IDENTITY: &str = match option_env!("AONW_GODOT_BUILD_IDENTITY") {
    Some(identity) => identity,
    None => "aonw_godot/development",
};
const MAX_OUTSTANDING_JOBS: usize = 8;
const WORKER_IDLE_POLL_INTERVAL: Duration = Duration::from_millis(1);

#[derive(GodotClass)]
#[class(tool, base=RefCounted)]
struct AonwLocalSession {
    worker: SessionWorker,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwLocalSession {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            worker: SessionWorker::new(),
            base,
        }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value, clippy::unused_self)]
impl AonwLocalSession {
    #[func]
    fn client_api_version(&self) -> i64 {
        i64::from(CLIENT_API_VERSION)
    }

    #[func]
    fn build_identity(&self) -> GString {
        GString::from(adapter_build_identity())
    }

    #[func]
    fn request_json(&mut self, request_json: GString) -> GString {
        let response = self.worker.request_sync(request_json.to_string());
        GString::from(response.as_str())
    }

    /// Queues one request on the serial engine worker and returns its job id.
    #[func]
    fn request_json_async(&mut self, request_json: GString) -> i64 {
        self.worker
            .enqueue(request_json.to_string())
            .and_then(|job_id| i64::try_from(job_id).ok())
            .unwrap_or(-1)
    }

    /// Queues latency-sensitive user interaction ahead of queued background work.
    #[func]
    fn request_json_async_interactive(&mut self, request_json: GString) -> i64 {
        self.worker
            .enqueue_interactive(request_json.to_string())
            .and_then(|job_id| i64::try_from(job_id).ok())
            .unwrap_or(-1)
    }

    /// Returns whether a queued response can be collected without blocking.
    #[func]
    fn is_response_ready(&mut self, job_id: i64) -> bool {
        u64::try_from(job_id)
            .ok()
            .is_some_and(|job_id| self.worker.is_ready(job_id))
    }

    /// Collects one ready response, or an empty string while it is pending.
    #[func]
    fn poll_response_json(&mut self, job_id: i64) -> GString {
        let response = u64::try_from(job_id)
            .ok()
            .and_then(|job_id| self.worker.poll(job_id))
            .unwrap_or_default();
        GString::from(response.as_str())
    }

    /// Cancels collection of one queued response without blocking the main thread.
    #[func]
    fn cancel_request(&mut self, job_id: i64) -> bool {
        u64::try_from(job_id)
            .ok()
            .is_some_and(|job_id| self.worker.cancel(job_id))
    }
}

fn dispatch_json(runtime: &mut LocalRuntime, input: &str) -> String {
    let mut ai_driver = StrategicPlanner;
    if let Ok(response) = catch_unwind(AssertUnwindSafe(|| {
        ClientProtocol::dispatch_json_with_ai(runtime, input, &mut ai_driver)
    })) {
        response
    } else {
        runtime.poison();
        ClientProtocol::failure_json("native_panic", "native request failed; session invalidated")
    }
}

struct WorkerRequest {
    job_id: u64,
    input: String,
    cancelled: Arc<AtomicBool>,
}

struct WorkerResponse {
    job_id: u64,
    output: Option<String>,
}

#[derive(Clone, Copy)]
enum WorkerPriority {
    Background,
    Interactive,
}

struct SessionWorker {
    background_requests: Option<SyncSender<WorkerRequest>>,
    interactive_requests: Option<SyncSender<WorkerRequest>>,
    responses: Receiver<WorkerResponse>,
    pending: BTreeMap<u64, String>,
    outstanding: BTreeSet<u64>,
    cancellation_tokens: BTreeMap<u64, Arc<AtomicBool>>,
    next_job_id: u64,
    shutdown: Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl SessionWorker {
    fn new() -> Self {
        let (background_sender, background_receiver) =
            mpsc::sync_channel::<WorkerRequest>(MAX_OUTSTANDING_JOBS);
        let (interactive_sender, interactive_receiver) =
            mpsc::sync_channel::<WorkerRequest>(MAX_OUTSTANDING_JOBS);
        let (response_sender, response_receiver) = mpsc::channel::<WorkerResponse>();
        let shutdown = Arc::new(AtomicBool::new(false));
        let worker_shutdown = Arc::clone(&shutdown);
        let thread = thread::spawn(move || {
            let mut runtime = LocalRuntime::default();
            while let Some(request) = receive_next_request(
                &interactive_receiver,
                &background_receiver,
                worker_shutdown.as_ref(),
            ) {
                if worker_shutdown.load(Ordering::Acquire) {
                    break;
                }
                let output = if request.cancelled.load(Ordering::Acquire) {
                    None
                } else {
                    let output = dispatch_json(&mut runtime, &request.input);
                    (!request.cancelled.load(Ordering::Acquire)).then_some(output)
                };
                if worker_shutdown.load(Ordering::Acquire) {
                    break;
                }
                if response_sender
                    .send(WorkerResponse {
                        job_id: request.job_id,
                        output,
                    })
                    .is_err()
                {
                    break;
                }
            }
        });
        Self {
            background_requests: Some(background_sender),
            interactive_requests: Some(interactive_sender),
            responses: response_receiver,
            pending: BTreeMap::new(),
            outstanding: BTreeSet::new(),
            cancellation_tokens: BTreeMap::new(),
            next_job_id: 1,
            shutdown,
            thread: Some(thread),
        }
    }

    fn enqueue(&mut self, input: String) -> Option<u64> {
        self.enqueue_with_priority(input, WorkerPriority::Background)
    }

    fn enqueue_interactive(&mut self, input: String) -> Option<u64> {
        self.enqueue_with_priority(input, WorkerPriority::Interactive)
    }

    fn enqueue_with_priority(&mut self, input: String, priority: WorkerPriority) -> Option<u64> {
        self.drain();
        if self.outstanding.len() >= MAX_OUTSTANDING_JOBS {
            return None;
        }
        let job_id = self.next_job_id;
        self.next_job_id = self.next_job_id.checked_add(1)?;
        let cancelled = Arc::new(AtomicBool::new(false));
        let sender = match priority {
            WorkerPriority::Background => self.background_requests.as_ref()?,
            WorkerPriority::Interactive => self.interactive_requests.as_ref()?,
        };
        sender
            .try_send(WorkerRequest {
                job_id,
                input,
                cancelled: Arc::clone(&cancelled),
            })
            .ok()?;
        self.outstanding.insert(job_id);
        self.cancellation_tokens.insert(job_id, cancelled);
        Some(job_id)
    }

    fn request_sync(&mut self, input: String) -> String {
        let Some(job_id) = self.enqueue(input) else {
            return ClientProtocol::failure_json(
                "engine_worker_unavailable",
                "engine worker is unavailable",
            );
        };
        loop {
            if let Some(output) = self.pending.remove(&job_id) {
                self.outstanding.remove(&job_id);
                return output;
            }
            if let Ok(response) = self.responses.recv() {
                self.store_response(response);
            } else {
                self.outstanding.clear();
                self.cancellation_tokens.clear();
                return ClientProtocol::failure_json(
                    "engine_worker_unavailable",
                    "engine worker stopped before returning a response",
                );
            }
        }
    }

    fn is_ready(&mut self, job_id: u64) -> bool {
        self.drain();
        self.pending.contains_key(&job_id)
    }

    fn poll(&mut self, job_id: u64) -> Option<String> {
        self.drain();
        let response = self.pending.remove(&job_id);
        if response.is_some() {
            self.outstanding.remove(&job_id);
        }
        response
    }

    fn cancel(&mut self, job_id: u64) -> bool {
        self.drain();
        if self.pending.remove(&job_id).is_some() {
            self.outstanding.remove(&job_id);
            return true;
        }
        if !self.outstanding.contains(&job_id) {
            return false;
        }
        self.cancellation_tokens.get(&job_id).is_some_and(|token| {
            token.store(true, Ordering::Release);
            true
        })
    }

    fn drain(&mut self) {
        while let Ok(response) = self.responses.try_recv() {
            self.store_response(response);
        }
    }

    fn store_response(&mut self, response: WorkerResponse) {
        let was_cancelled = self
            .cancellation_tokens
            .remove(&response.job_id)
            .is_some_and(|token| token.load(Ordering::Acquire));
        let Some(output) = response.output else {
            self.outstanding.remove(&response.job_id);
            return;
        };
        if was_cancelled {
            self.outstanding.remove(&response.job_id);
            return;
        }
        self.pending.insert(response.job_id, output);
    }
}

fn receive_next_request(
    interactive: &Receiver<WorkerRequest>,
    background: &Receiver<WorkerRequest>,
    shutdown: &AtomicBool,
) -> Option<WorkerRequest> {
    let mut interactive_connected = true;
    let mut background_connected = true;
    loop {
        if shutdown.load(Ordering::Acquire) {
            return None;
        }
        if interactive_connected {
            match interactive.try_recv() {
                Ok(request) => return Some(request),
                Err(TryRecvError::Empty) => {}
                Err(TryRecvError::Disconnected) => interactive_connected = false,
            }
        }
        if background_connected {
            match background.recv_timeout(WORKER_IDLE_POLL_INTERVAL) {
                Ok(request) => return Some(request),
                Err(RecvTimeoutError::Timeout) => continue,
                Err(RecvTimeoutError::Disconnected) => background_connected = false,
            }
        } else if interactive_connected {
            match interactive.recv_timeout(WORKER_IDLE_POLL_INTERVAL) {
                Ok(request) => return Some(request),
                Err(RecvTimeoutError::Timeout) => continue,
                Err(RecvTimeoutError::Disconnected) => interactive_connected = false,
            }
        }
        if !interactive_connected && !background_connected {
            return None;
        }
    }
}

impl Drop for SessionWorker {
    fn drop(&mut self) {
        self.shutdown.store(true, Ordering::Release);
        self.background_requests.take();
        self.interactive_requests.take();
        // Dropping a running handle detaches it. The shutdown flag stops queued work,
        // while the current bounded request may finish without blocking Godot's main thread.
        if let Some(thread) = self.thread.take()
            && thread.is_finished()
        {
            let _ = thread.join();
        }
    }
}

fn adapter_build_identity() -> &'static str {
    BUILD_IDENTITY
}

#[cfg(test)]
mod tests;
