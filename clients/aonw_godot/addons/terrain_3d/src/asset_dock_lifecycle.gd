@tool
extends "res://addons/terrain_3d/src/asset_dock.gd"
## Local Terrain3D 1.0.2 compatibility fix for the Godot 4.6+ EditorDock API.
## remove_dock unregisters the wrapper but does not free it. The upstream plugin
## frees only this PanelContainer, leaking its former EditorDock and icon.
## Keep the vendor implementation intact; remove this shim once upstream fixes it.

func remove_dock(p_force: bool = false) -> void:
	if not is_instance_valid(_dock):
		return
	super.remove_dock(p_force)
	if p_force:
		# The plugin separately queues this panel for deletion after this call.
		# Detach it before releasing its wrapper so neither object owns the other.
		if get_parent() == _dock:
			_dock.remove_child(self)
		_dock.queue_free()
		_dock = null
