#include "gamepad.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

namespace {

bool read_event(int descriptor, js_event* event) {
  ssize_t bytes;
  do {
    bytes = read(descriptor, event, sizeof(*event));
  } while (bytes < 0 && errno == EINTR);
  return bytes == sizeof(*event);
}

int read_sysfs_hex(const std::string& path) {
  std::ifstream file(path);
  int value = 0;
  if (file.is_open()) {
    file >> std::hex >> value;
  }
  return value;
}

std::string device_name(const std::string& device_id) {
  const auto separator = device_id.rfind('/');
  return separator == std::string::npos ? device_id
                                        : device_id.substr(separator + 1);
}

}  // namespace

namespace gamepad {

std::shared_ptr<GamepadInfo> get_gamepad_info(
    const std::string& device_id) {
  const int descriptor = open(device_id.c_str(), O_RDONLY | O_CLOEXEC);
  if (descriptor == -1) {
    std::cerr << "Unable to open joystick " << device_id << ": "
              << strerror(errno) << std::endl;
    return nullptr;
  }

  char name[128] = "Unknown";
  if (ioctl(descriptor, JSIOCGNAME(sizeof(name)), name) < 0) {
    std::cerr << "Unable to read joystick name for " << device_id << ": "
              << strerror(errno) << std::endl;
  }

  const std::string sysfs_base =
      "/sys/class/input/" + device_name(device_id) + "/device/id/";
  return std::make_shared<GamepadInfo>(
      device_id, name, descriptor, read_sysfs_hex(sysfs_base + "vendor"),
      read_sysfs_hex(sysfs_base + "product"));
}

void listen(
    std::shared_ptr<GamepadInfo> gamepad,
    const std::function<void(const js_event&)>& event_consumer) {
  while (gamepad->alive.load()) {
    js_event event{};
    if (!read_event(gamepad->file_descriptor, &event)) {
      break;
    }
    event_consumer(event);
  }
  gamepad->alive.store(false);
  close(gamepad->file_descriptor);
}

}  // namespace gamepad
