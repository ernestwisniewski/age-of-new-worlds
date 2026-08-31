//! Godot adapter for the shared deterministic local client protocol.

mod local_session;
#[cfg(feature = "editor-tools")]
mod map_workbench;

mod extension_entrypoint {
    #![allow(unsafe_code)]

    use godot::prelude::*;

    struct AonwGodotExtension;

    // SAFETY: Godot requires this marker implementation to register the extension entrypoint.
    #[gdextension]
    unsafe impl ExtensionLibrary for AonwGodotExtension {}
}
