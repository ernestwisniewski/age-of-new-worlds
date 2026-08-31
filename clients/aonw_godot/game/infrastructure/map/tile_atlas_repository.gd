class_name AonwTileAtlasRepository
extends AonwMapTextureAssembler

const MANIFEST_NAME := "map_texture_manifest.json"
const MAX_ATLAS_SIZE := 16_384
const MAX_DECODED_PIXELS := 64 * 1024 * 1024
const MAP_HEX_RADIUS := 60.0
const SQRT_3 := 1.7320508075688772

func load_atlas(map: AonwMapView, source_directory: String) -> Dictionary:
	var reference := _load_reference_atlas(
		map,
		_resolve_path(source_directory),
	)
	if not reference["ok"]:
		return reference

	var atlas_size: Vector2i = reference["atlas_size"]
	var reference_atlas: Image = reference["image"]
	reference_atlas.generate_mipmaps()
	var reference_texture := ImageTexture.create_from_image(reference_atlas)
	return {
		"ok": true,
		"reference_texture": reference_texture,
		"atlas_size": atlas_size,
	}

func _load_reference_atlas(
	map: AonwMapView,
	source_directory: String,
) -> Dictionary:
	var manifest_path := source_directory.path_join(MANIFEST_NAME)
	if source_directory.is_empty() or not FileAccess.file_exists(manifest_path):
		return _failure("map asset bundle is required: %s" % manifest_path)

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		return _failure("cannot open map texture manifest: %s" % manifest_path)
	var manifest: Variant = JSON.parse_string(manifest_file.get_as_text())
	var error := _manifest_error(manifest, map)
	if not error.is_empty():
		return _failure("invalid map texture manifest: %s" % error)

	var scale := float(manifest["compiledScale"])
	var atlas_size := Vector2i(
		ceili(float(manifest["worldWidth"]) * scale),
		ceili(float(manifest["worldHeight"]) * scale),
	)
	var atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for page in manifest["pages"]:
		var asset := str(page["asset"])
		var page_path := source_directory.path_join(str(page["file"]))
		var image_result := _load_page(page_path, str(page["sha256"]), asset)
		if not image_result["ok"]:
			return image_result
		var image: Image = image_result["image"]
		if (
			image.is_empty()
			or image.get_width() != int(page["pixelWidth"])
			or image.get_height() != int(page["pixelHeight"])
		):
			return _failure("map asset bundle page is invalid: %s" % asset)
		image.convert(Image.FORMAT_RGBA8)
		if not _blit_page(atlas, image, page["destination"], scale):
			return _failure("map asset bundle page is outside the atlas: %s" % asset)

	return {
		"ok": true,
		"image": atlas,
		"atlas_size": atlas_size,
	}

func _load_page(path: String, expected_hash: String, asset: String) -> Dictionary:
	if OS.has_feature("editor"):
		if not FileAccess.file_exists(path):
			return _failure("missing map asset bundle page: %s" % asset)
		if FileAccess.get_sha256(path) != expected_hash:
			return _failure("map asset bundle page hash does not match: %s" % asset)
		var source_image := Image.load_from_file(path)
		if source_image == null:
			return _failure("map asset bundle page cannot be decoded: %s" % asset)
		return {"ok": true, "image": source_image}
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		return _failure("missing imported map asset bundle page: %s" % asset)
	var imported_image := texture.get_image()
	if imported_image == null:
		return _failure("imported map asset bundle page cannot be decoded: %s" % asset)
	return {"ok": true, "image": imported_image}

func _manifest_error(
	value: Variant,
	map: AonwMapView,
) -> String:
	if value is not Dictionary:
		return "root must be an object"
	var manifest: Dictionary = value
	if not _has_exact_fields(manifest, [
		"mapId", "mapContentHash", "gridLayout", "cols", "rows",
		"worldWidth", "worldHeight", "compiledScale", "filterQuality",
		"pageSizeLimit", "gutter", "pages", "averageColors",
	]):
		return "fields do not match the map asset bundle contract"
	if manifest.get("mapId") != map.map_id():
		return "map identity does not match"
	if manifest.get("mapContentHash") != map.content_hash():
		return "map content hash does not match"
	if manifest.get("gridLayout") != "oddQFlatTop":
		return "grid layout does not match"
	if manifest.get("cols") != map.cols() or manifest.get("rows") != map.rows():
		return "map dimensions do not match"
	for field in ["worldWidth", "worldHeight", "compiledScale"]:
		if not _is_positive_number(manifest.get(field)):
			return "%s must be a positive number" % field
	if manifest.get("filterQuality") != "medium":
		return "filterQuality is unsupported"
	if not _is_positive_integer(manifest.get("pageSizeLimit")):
		return "pageSizeLimit is invalid"
	if (
		not _is_non_negative_integer(manifest.get("gutter"))
		or int(manifest["gutter"]) > 64
	):
		return "gutter is invalid"
	var colors: Variant = manifest.get("averageColors")
	if colors is not Dictionary or colors.size() != map.cols() * map.rows():
		return "averageColors do not cover the map"
	for col in map.cols():
		for row in map.rows():
			var color: Variant = colors.get("%d,%d" % [col, row])
			if (
				not _is_non_negative_integer(color)
				or int(color) > 0xffffffff
			):
				return "averageColors contain an invalid value"
	var expected_width := MAP_HEX_RADIUS * 2.0 + float(map.cols() - 1) * 1.5 * MAP_HEX_RADIUS
	var expected_height := (
		SQRT_3 * MAP_HEX_RADIUS * (float(map.rows()) + (0.5 if map.cols() > 1 else 0.0))
	)
	if (
		absf(float(manifest["worldWidth"]) - expected_width) > 0.000001
		or absf(float(manifest["worldHeight"]) - expected_height) > 0.000001
	):
		return "world bounds do not match MapView geometry"
	var scale := float(manifest["compiledScale"])
	if (
		ceili(float(manifest["worldWidth"]) * scale) > MAX_ATLAS_SIZE
		or ceili(float(manifest["worldHeight"]) * scale) > MAX_ATLAS_SIZE
	):
		return "atlas exceeds the supported size"
	var pages: Variant = manifest.get("pages")
	if pages is not Array or pages.is_empty():
		return "pages must be a non-empty array"
	var expected_prefix := "assets/runtime/maps/%s/" % map.map_id()
	var seen := {}
	for page_value in pages:
		if page_value is not Dictionary:
			return "page must be an object"
		var page: Dictionary = page_value
		if not _has_exact_fields(page, [
			"file", "asset", "format", "sha256", "pixelWidth", "pixelHeight",
			"destination",
		]):
			return "page fields do not match the map asset bundle contract"
		var asset: Variant = page.get("asset")
		var page_name: Variant = page.get("file")
		if asset is not String or page_name is not String:
			return "page paths must be strings"
		if (
			str(page_name).get_file() != page_name
			or not _is_page_file(str(page_name))
			or str(asset) != expected_prefix + str(page_name)
		):
			return "page asset is outside the map runtime directory"
		if seen.has(page_name):
			return "page asset is duplicated"
		seen[page_name] = true
		if page.get("format") != "jpeg":
			return "%s has an unsupported format" % page_name
		if not _is_sha256(page.get("sha256")):
			return "%s has an invalid SHA-256" % page_name
		if not _is_positive_integer(page.get("pixelWidth")):
			return "%s has an invalid width" % page_name
		if not _is_positive_integer(page.get("pixelHeight")):
			return "%s has an invalid height" % page_name
		if (
			int(page["pixelWidth"]) > int(manifest["pageSizeLimit"])
			or int(page["pixelHeight"]) > int(manifest["pageSizeLimit"])
		):
			return "%s exceeds pageSizeLimit" % page_name
		var destination: Variant = page.get("destination")
		if destination is not Array or destination.size() != 4:
			return "%s has an invalid destination" % page_name
		if not destination.all(_is_number):
			return "%s has a non-numeric destination" % page_name
		if float(destination[2]) <= 0.0 or float(destination[3]) <= 0.0:
			return "%s has an invalid destination size" % page_name
		if (
			absf(float(destination[2]) * scale - float(page["pixelWidth"])) > 0.01
			or absf(float(destination[3]) * scale - float(page["pixelHeight"])) > 0.01
		):
			return "%s destination does not match its pixel size" % page_name
	return _page_layout_error(manifest)

func _page_layout_error(manifest: Dictionary) -> String:
	var scale := float(manifest["compiledScale"])
	var gutter := int(manifest["gutter"])
	var atlas_size := Vector2i(
		ceili(float(manifest["worldWidth"]) * scale),
		ceili(float(manifest["worldHeight"]) * scale),
	)
	var decoded_pixels := 0
	var rectangles: Array[Rect2i] = []
	for page in manifest["pages"]:
		var width := int(page["pixelWidth"])
		var height := int(page["pixelHeight"])
		decoded_pixels += width * height
		if decoded_pixels > MAX_DECODED_PIXELS:
			return "decoded page pixel budget is exceeded"
		var destination: Array = page["destination"]
		var start := Vector2i(
			roundi(float(destination[0]) * scale),
			roundi(float(destination[1]) * scale),
		)
		var end := start + Vector2i(width, height)
		if (
			start.x < -gutter
			or start.y < -gutter
			or end.x > atlas_size.x + gutter
			or end.y > atlas_size.y + gutter
		):
			return "%s is outside the atlas" % page["file"]
		var clipped_start := start.max(Vector2i.ZERO)
		var clipped_end := end.min(atlas_size)
		rectangles.append(Rect2i(clipped_start, clipped_end - clipped_start))
	var allowed_overlap := gutter * 2
	for first in rectangles.size():
		for second in range(first + 1, rectangles.size()):
			var overlap := rectangles[first].intersection(rectangles[second])
			if overlap.size.x > allowed_overlap and overlap.size.y > allowed_overlap:
				return "pages overlap excessively"
	var x_boundaries := [0, atlas_size.x]
	var y_boundaries := [0, atlas_size.y]
	for rectangle in rectangles:
		x_boundaries.append(rectangle.position.x)
		x_boundaries.append(rectangle.end.x)
		y_boundaries.append(rectangle.position.y)
		y_boundaries.append(rectangle.end.y)
	x_boundaries.sort()
	y_boundaries.sort()
	for x_index in x_boundaries.size() - 1:
		for y_index in y_boundaries.size() - 1:
			var cell := Rect2i(
				Vector2i(x_boundaries[x_index], y_boundaries[y_index]),
				Vector2i(
					x_boundaries[x_index + 1] - x_boundaries[x_index],
					y_boundaries[y_index + 1] - y_boundaries[y_index],
				),
			)
			if not cell.has_area():
				continue
			var covered := false
			for rectangle in rectangles:
				if rectangle.encloses(cell):
					covered = true
					break
			if not covered:
				return "page coverage has a gap"
	return ""

func _blit_page(atlas: Image, page: Image, destination: Array, scale: float) -> bool:
	var target := Vector2i(
		roundi(float(destination[0]) * scale),
		roundi(float(destination[1]) * scale),
	)
	var source := Vector2i.ZERO
	if target.x < 0:
		source.x = -target.x
		target.x = 0
	if target.y < 0:
		source.y = -target.y
		target.y = 0
	var size := Vector2i(
		mini(page.get_width() - source.x, atlas.get_width() - target.x),
		mini(page.get_height() - source.y, atlas.get_height() - target.y),
	)
	if size.x <= 0 or size.y <= 0:
		return false
	atlas.blit_rect(page, Rect2i(source, size), target)
	return true

static func _is_positive_number(value: Variant) -> bool:
	return _is_number(value) and float(value) > 0.0

static func _is_positive_integer(value: Variant) -> bool:
	return (
		_is_number(value)
		and float(value) > 0.0
		and float(value) <= MAX_ATLAS_SIZE
		and float(value) == floorf(float(value))
	)

static func _is_non_negative_integer(value: Variant) -> bool:
	return (
		typeof(value) in [TYPE_INT, TYPE_FLOAT]
		and float(value) >= 0.0
		and float(value) == floorf(float(value))
	)

static func _is_number(value: Variant) -> bool:
	return (
		typeof(value) in [TYPE_INT, TYPE_FLOAT]
		and absf(float(value)) <= 1_000_000.0
	)

static func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)

static func _is_page_file(value: String) -> bool:
	if not value.begins_with("page_") or not value.ends_with(".jpg"):
		return false
	var index := value.trim_prefix("page_").trim_suffix(".jpg")
	return not index.is_empty() and not index.begins_with("-") and index.is_valid_int()

static func _has_exact_fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

static func _resolve_path(path: String) -> String:
	if OS.has_feature("editor") and (
		path.begins_with("res://") or path.begins_with("user://")
	):
		return ProjectSettings.globalize_path(path)
	return path
