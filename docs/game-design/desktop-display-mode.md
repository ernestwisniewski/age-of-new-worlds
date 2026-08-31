# Desktop display mode

Linux, macOS, and Windows start in native full-screen mode. The player can choose windowed mode in **Settings > Graphics**; the preference is stored locally and applied before the next desktop window is shown.

Display mode belongs to the application shell:

- `DisplaySettings` — persisted preference;
- `DisplaySettingsController` — application coordination;
- `GameWindow` — platform port;
- `PlatformGameWindow` — desktop adapter;
- `DisplayBootstrap` — applies the preference before `HexApp` mounts.

Mobile and web do not expose the setting. A failed transition restores the previous UI/window state and does not persist the failed choice.

Changing mode changes the Flutter viewport. It does not add a virtual resolution, reset camera zoom, or scale the entire HUD manually. Layout code continues to use available constraints and should be checked on short, standard, and ultrawide desktop viewports.
