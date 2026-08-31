use aonw_map_workbench::MapWorkbenchProtocol;
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

#[derive(GodotClass)]
#[class(tool, base=RefCounted)]
struct AonwMapWorkbenchBridge {
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwMapWorkbenchBridge {
    fn init(base: Base<RefCounted>) -> Self {
        Self { base }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value, clippy::unused_self)]
impl AonwMapWorkbenchBridge {
    #[func]
    fn request_json(&self, request_json: GString) -> GString {
        GString::from(dispatch_json(&request_json.to_string()).as_str())
    }
}

fn dispatch_json(input: &str) -> String {
    MapWorkbenchProtocol::dispatch_json(input)
}

#[cfg(test)]
mod tests;
