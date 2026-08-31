#ifndef GAMEPADS_LINUX_GAMEPAD_H_
#define GAMEPADS_LINUX_GAMEPAD_H_

#include <linux/joystick.h>

#include <atomic>
#include <functional>
#include <memory>
#include <string>
#include <utility>

namespace gamepad {

struct GamepadInfo {
  GamepadInfo(std::string id, std::string display_name, int descriptor,
              int vendor, int product)
      : device_id(std::move(id)),
        name(std::move(display_name)),
        file_descriptor(descriptor),
        vendor_id(vendor),
        product_id(product) {}

  std::string device_id;
  std::string name;
  int file_descriptor;
  std::atomic_bool alive{true};
  int vendor_id;
  int product_id;
};

std::shared_ptr<GamepadInfo> get_gamepad_info(const std::string& device);

void listen(
    std::shared_ptr<GamepadInfo> gamepad,
    const std::function<void(const js_event&)>& event_consumer);

}  // namespace gamepad

#endif
