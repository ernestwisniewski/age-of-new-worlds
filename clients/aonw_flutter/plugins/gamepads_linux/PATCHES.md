# AoNW patches to gamepads_linux 0.1.2

The package is vendored temporarily because the published Linux backend can
terminate the application when `/dev/input` is not exposed and stores pointers
to map entries that are erased during hotplug.

Local changes:

- treat a missing or inaccessible `/dev/input` as no available controllers;
- contain native listener failures instead of allowing a detached thread to
  call `std::terminate`;
- ignore unrelated inotify entries without dropping later events;
- never dispatch a joystick event after a short or failed read;
- keep gamepads alive with `shared_ptr` while worker threads finish;
- synchronize the device registry and dispatch Flutter events on GLib's main
  context.

Remove this override after an upstream release contains equivalent fixes and
the Steam Deck hardware matrix passes against it.
