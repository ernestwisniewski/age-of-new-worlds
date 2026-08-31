#ifndef GAMEPADS_LINUX_CONNECTION_LISTENER_H_
#define GAMEPADS_LINUX_CONNECTION_LISTENER_H_

#include <atomic>
#include <functional>
#include <string>

namespace connection_listener {

enum class ConnectionEventType { CONNECTED, DISCONNECTED };

struct ConnectionEvent {
  ConnectionEventType type;
  std::string device_id;
};

void listen(
    const std::atomic_bool* keep_reading,
    const std::function<void(const ConnectionEvent&)>& event_consumer);

}  // namespace connection_listener

#endif
