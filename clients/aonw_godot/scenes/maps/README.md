# Generated Map Scenes

The AoNW Map Workbench writes one stable authored Godot 3D scene per map in
this directory. It preserves manually added nodes while the `AonwMap3D`
surface references an immutable generated mesh/settings generation under
`res://assets/generated_maps`.

Logical source content remains in `content/maps/`; Flutter sources remain
unchanged. Godot may reuse their JPG slices as reference artwork, but it loads
logical JSON only from the versioned content root.
