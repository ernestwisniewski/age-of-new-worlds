extends SceneTree
const City := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")
const Preview := preload("res://editor/map_authoring/presentation/city_hex_preview.gd")
const Forest := preload("res://editor/map_authoring/presentation/reference_forest.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")

class Ground extends RefCounted:
	var slope := 0.0
	var invalid := false
	func get_height(point: Vector3) -> float:
		return NAN if invalid else 2.0 + slope * point.x

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source := _source()
	var p := Parameters.defaults()
	var original := p.duplicate(true)
	for radius in [5.0, 10.0, 40.0]:
		source.hex_radius_meters = radius
		var resolved := City.forest_parameters(source, p)
		assert(is_equal_approx(resolved["tree_height"] / (2.0 * radius), 8.0 / 240.0))
		assert(is_equal_approx(resolved["tree_spacing"] / (2.0 * radius), 6.0 / 240.0))
	assert(p == original, "Scale must not rewrite saved recipe values")
	p["city_scale_enabled"] = 0.0
	assert(City.forest_parameters(source, p) == p, "Legacy numeric overrides must survive")
	assert(not Parameters.validate({"city_scale_enabled": 0.2}).is_empty())
	p = original.duplicate(true)
	var geometry_recipe := Parameters.geometry(p)
	p["city_hex_diameter"] = 320.0
	p["city_reserve_enabled"] = 1.0
	assert(geometry_recipe == Parameters.geometry(p), "City appearance must not switch draft workspaces")
	source.hex_radius_meters = 10.0
	p = original.duplicate(true)
	p["city_reserve_enabled"] = 1.0
	var water := Image.create(source.width, source.height, false, Image.FORMAT_L8)
	water.fill(Color.BLACK)
	var ground := Ground.new()
	var coordinate := Vector2i(2, 2)
	var document := {"tiles": [{"col": 2, "row": 2, "terrainTags": ["forest"]}]}
	var site := City.prepare(source, coordinate, p, water, ground, document)
	assert(site["ok"], str(site.get("message", "")))
	assert(is_equal_approx(site["core_radius"], 4.2))
	assert(is_equal_approx(site["outskirts_radius"], 7.6))
	assert(site["outskirts_radius"] < source.hex_radius_meters * sqrt(3.0) * 0.5)
	var expected := Geometry.new(5, 5, 10.0).tile_center(coordinate)
	var center: Vector3 = site["center"]
	assert(is_equal_approx(center.x, expected.x + source.world_origin_meters.x - source.world_min_meters.x))
	assert(is_equal_approx(center.z, expected.y + source.world_origin_meters.z - source.world_min_meters.y))
	assert(center.y == 2.0)
	assert(not City.layout(source, Vector2i(-1, 0), p)["ok"])
	assert(City.vegetation_weight(site, center + Vector3(4.5, 0, 0), 0.5) == 0.0,
		"An outside trunk must not let its crown enter the building core")
	assert(City.vegetation_weight(site, center + Vector3(9, 0, 0), 0.5) == 1.0)
	for i in 80:
		var point := center + Vector3(i * 0.2, 0, 0)
		assert(City.accepts_vegetation(site, point, 0.5) == City.accepts_vegetation(site, point, 0.5))
		assert(City.accepts_vegetation({}, point, 0.5), "Disabled reservations must restore all candidates")
	var old_site := site.duplicate(true)
	var pixel := Vector2i(roundi(center.x + 2), roundi(center.z))
	water.set_pixelv(pixel, Color.WHITE)
	assert(not City.prepare(source, coordinate, p, water, ground, document)["ok"], "Catch water away from the centre")
	water.set_pixelv(pixel, Color.BLACK)
	ground.slope = 1.0
	assert(not City.prepare(source, coordinate, p, water, ground, document)["ok"], "No implicit flattening of cliffs")
	ground.slope = 0.0
	ground.invalid = true
	assert(not City.prepare(source, coordinate, p, water, ground, document)["ok"])
	ground.invalid = false
	document["tiles"][0]["terrainTags"] = ["lake"]
	assert(not City.prepare(source, coordinate, p, water, ground, document)["ok"])
	p["city_reserve_enabled"] = 0.0
	assert(City.prepare(source, coordinate, p, water, ground, document).is_empty())
	assert(source.base_image == null, "No terrain writes")
	var box := BoxMesh.new()
	box.size = Vector3(2, 4, 2)
	var prototype := {"height": 4.0, "parts": [{"mesh": box, "transform": Transform3D(Basis.IDENTITY, Vector3(3, 0, 0))}]}
	assert(is_equal_approx(Forest.prototype_radius(prototype), sqrt(17.0) / 4.0), "Include the actual mesh offset and crown extent")
	var model := Node3D.new()
	model.name = "FutureCity"
	var packed := PackedScene.new()
	assert(packed.pack(model) == OK)
	model.free()
	var result := Preview.build(old_site, source, ground, packed)
	var view: Node3D = result["root"]
	root.add_child(view)
	var anchor := view.get_node("CityModelAnchor") as Node3D
	assert(anchor.get_node_or_null("FutureCity") != null)
	assert(anchor.scale == Vector3.ONE * (20.0 / 240.0))
	assert(is_equal_approx(anchor.position.y, 2.065))
	assert(view.owner == null and anchor.owner == null)
	assert(view.get_node("FootprintGuides").get_child_count() == 3)
	view.free()
	print("City hex: PASS (scale, layout, crown clearance, water/slope safety, anchor and isolation)")
	quit(0)

func _source() -> AonwTerrainCompiledArtifact:
	var source := AonwTerrainCompiledArtifact.new()
	source.cols = 5
	source.rows = 5
	source.width = 150
	source.height = 150
	source.sample_spacing_meters = 1.0
	source.hex_radius_meters = 10.0
	source.world_origin_meters = Vector3(4, 0, 5)
	source.world_min_meters = Vector2(-10, -9)
	return source
