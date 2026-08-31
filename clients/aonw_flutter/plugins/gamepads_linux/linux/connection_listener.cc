#include "connection_listener.h"

#include <dirent.h>
#include <errno.h>
#include <sys/inotify.h>
#include <unistd.h>

#include <array>
#include <cstring>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

#include "utils.h"

namespace {

constexpr char kInputDirectory[] = "/dev/input/";

std::optional<connection_listener::ConnectionEventType> parse_event_type(
    const inotify_event& event) {
  if ((event.mask & IN_CREATE) != 0 || (event.mask & IN_ATTRIB) != 0) {
    return connection_listener::ConnectionEventType::CONNECTED;
  }
  if ((event.mask & IN_DELETE) != 0) {
    return connection_listener::ConnectionEventType::DISCONNECTED;
  }
  return std::nullopt;
}

bool list_existing(
    const std::function<void(const connection_listener::ConnectionEvent&)>&
        event_consumer) {
  DIR* directory = opendir(kInputDirectory);
  if (directory == nullptr) {
    std::cerr << "Gamepad input unavailable at " << kInputDirectory << ": "
              << strerror(errno) << std::endl;
    return false;
  }

  std::vector<std::string> devices;
  while (dirent* entry = readdir(directory)) {
    if (!starts_with(entry->d_name, "js")) {
      continue;
    }
    devices.emplace_back(std::string(kInputDirectory) + entry->d_name);
  }
  closedir(directory);

  for (const std::string& device : devices) {
    event_consumer(
        {connection_listener::ConnectionEventType::CONNECTED, device});
  }
  return true;
}

bool wait_for_connections(
    int inotify_descriptor,
    const std::function<void(const connection_listener::ConnectionEvent&)>&
        event_consumer) {
  alignas(inotify_event) std::array<char, 4096> buffer{};
  ssize_t length;
  do {
    length = read(inotify_descriptor, buffer.data(), buffer.size());
  } while (length < 0 && errno == EINTR);

  if (length <= 0) {
    if (length < 0) {
      std::cerr << "Unable to read gamepad hotplug events: "
                << strerror(errno) << std::endl;
    }
    return false;
  }

  char* cursor = buffer.data();
  const char* end = buffer.data() + length;
  while (cursor < end) {
    const auto* event = reinterpret_cast<const inotify_event*>(cursor);
    const size_t event_size = sizeof(inotify_event) + event->len;
    if (event_size == 0 || cursor + event_size > end) {
      return false;
    }
    cursor += event_size;

    if (event->len == 0 || !starts_with(event->name, "js")) {
      continue;
    }
    const auto type = parse_event_type(*event);
    if (!type.has_value()) {
      continue;
    }
    event_consumer(
        {*type, std::string(kInputDirectory) + std::string(event->name)});
  }
  return true;
}

}  // namespace

namespace connection_listener {

void listen(
    const std::atomic_bool* keep_reading,
    const std::function<void(const ConnectionEvent&)>& event_consumer) {
  if (!list_existing(event_consumer)) {
    return;
  }

  const int inotify_descriptor = inotify_init1(IN_CLOEXEC);
  if (inotify_descriptor == -1) {
    std::cerr << "Unable to initialize gamepad hotplug monitoring: "
              << strerror(errno) << std::endl;
    return;
  }
  const int watcher = inotify_add_watch(
      inotify_descriptor, kInputDirectory,
      IN_CREATE | IN_DELETE | IN_ATTRIB);
  if (watcher == -1) {
    std::cerr << "Unable to monitor " << kInputDirectory << ": "
              << strerror(errno) << std::endl;
    close(inotify_descriptor);
    return;
  }

  while (keep_reading->load() &&
         wait_for_connections(inotify_descriptor, event_consumer)) {}

  inotify_rm_watch(inotify_descriptor, watcher);
  close(inotify_descriptor);
}

}  // namespace connection_listener
