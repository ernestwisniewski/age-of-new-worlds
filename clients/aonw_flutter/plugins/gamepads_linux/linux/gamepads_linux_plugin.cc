#include "include/gamepads_linux/gamepads_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <atomic>
#include <cstring>
#include <exception>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "connection_listener.h"
#include "gamepad.h"

#define GAMEPADS_LINUX_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), gamepads_linux_plugin_get_type(), \
                              GamepadsLinuxPlugin))

struct _GamepadsLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(GamepadsLinuxPlugin, gamepads_linux_plugin, g_object_get_type())

namespace {

FlMethodChannel* channel = nullptr;
std::atomic_bool keep_reading_events{false};
std::mutex gamepads_mutex;
std::map<std::string, std::shared_ptr<gamepad::GamepadInfo>> gamepads;

std::optional<const char*> event_type_name(const js_event& event) {
  switch (event.type & ~JS_EVENT_INIT) {
    case JS_EVENT_BUTTON:
      return "button";
    case JS_EVENT_AXIS:
      return "analog";
    default:
      return std::nullopt;
  }
}

struct PendingEvent {
  std::shared_ptr<gamepad::GamepadInfo> gamepad;
  js_event event;
};

gboolean emit_gamepad_event(gpointer data) {
  std::unique_ptr<PendingEvent> pending(static_cast<PendingEvent*>(data));
  const auto type = event_type_name(pending->event);
  if (channel == nullptr || !type.has_value()) {
    return G_SOURCE_REMOVE;
  }

  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string(
      map, "gamepadId",
      fl_value_new_string(pending->gamepad->device_id.c_str()));
  fl_value_set_string(map, "time", fl_value_new_int(pending->event.time));
  fl_value_set_string(map, "type", fl_value_new_string(*type));
  fl_value_set_string(
      map, "key",
      fl_value_new_string(std::to_string(pending->event.number).c_str()));
  fl_value_set_string(map, "value",
                      fl_value_new_float(pending->event.value));
  fl_value_set_string(
      map, "vendorId", fl_value_new_int(pending->gamepad->vendor_id));
  fl_value_set_string(
      map, "productId", fl_value_new_int(pending->gamepad->product_id));
  fl_method_channel_invoke_method(channel, "onGamepadEvent", map, nullptr,
                                  nullptr, nullptr);
  return G_SOURCE_REMOVE;
}

void process_gamepad(std::shared_ptr<gamepad::GamepadInfo> info) {
  gamepad::listen(info, [info](const js_event& event) {
    g_main_context_invoke(
        nullptr, emit_gamepad_event, new PendingEvent{info, event});
  });
}

void handle_connection_event(
    const connection_listener::ConnectionEvent& event) {
  const std::string& key = event.device_id;
  if (event.type == connection_listener::ConnectionEventType::DISCONNECTED) {
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    const auto existing = gamepads.find(key);
    if (existing != gamepads.end()) {
      existing->second->alive.store(false);
      gamepads.erase(existing);
    }
    return;
  }

  {
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    const auto existing = gamepads.find(key);
    if (existing != gamepads.end() && existing->second->alive.load()) {
      return;
    }
  }

  auto info = gamepad::get_gamepad_info(key);
  if (info == nullptr) {
    return;
  }
  {
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    gamepads[key] = info;
  }
  std::thread(process_gamepad, std::move(info)).detach();
}

void event_loop_start() {
  try {
    connection_listener::listen(&keep_reading_events, handle_connection_event);
  } catch (const std::exception& error) {
    std::cerr << "Gamepad listener stopped: " << error.what() << std::endl;
  } catch (...) {
    std::cerr << "Gamepad listener stopped after an unknown native error."
              << std::endl;
  }
}

void respond_not_found(FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(method_call, response, nullptr);
}

void respond(FlMethodCall* method_call, FlValue* value) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_method_call_respond(method_call, response, nullptr);
}

void handle_method_call(FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "listGamepads") != 0) {
    respond_not_found(method_call);
    return;
  }

  std::vector<std::pair<std::string, std::string>> connected;
  {
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    for (const auto& [device_id, info] : gamepads) {
      if (info->alive.load()) {
        connected.emplace_back(device_id, info->name);
      }
    }
  }

  g_autoptr(FlValue) list = fl_value_new_list();
  for (const auto& [device_id, name] : connected) {
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set(map, fl_value_new_string("id"),
                 fl_value_new_string(device_id.c_str()));
    fl_value_set(map, fl_value_new_string("name"),
                 fl_value_new_string(name.c_str()));
    fl_value_append(list, map);
  }
  respond(method_call, list);
}

void method_call_cb([[maybe_unused]] FlMethodChannel* flutter_channel,
                    FlMethodCall* method_call,
                    [[maybe_unused]] gpointer user_data) {
  handle_method_call(method_call);
}

}  // namespace

void gamepads_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  GamepadsLinuxPlugin* plugin = GAMEPADS_LINUX_PLUGIN(
      g_object_new(gamepads_linux_plugin_get_type(), nullptr));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                  "xyz.luan/gamepads", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}

static void gamepads_linux_plugin_dispose(GObject* object) {
  keep_reading_events.store(false);
  {
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    for (const auto& [_, info] : gamepads) {
      info->alive.store(false);
    }
    gamepads.clear();
  }
  channel = nullptr;
  G_OBJECT_CLASS(gamepads_linux_plugin_parent_class)->dispose(object);
}

static void gamepads_linux_plugin_class_init(GamepadsLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = gamepads_linux_plugin_dispose;
}

static void gamepads_linux_plugin_init(
    [[maybe_unused]] GamepadsLinuxPlugin* self) {
  keep_reading_events.store(true);
  std::thread(event_loop_start).detach();
}
