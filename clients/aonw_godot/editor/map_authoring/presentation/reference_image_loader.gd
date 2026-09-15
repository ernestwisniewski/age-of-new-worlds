@tool
extends RefCounted
## Use imported Texture2D resources, including compressed desktop imports.
## No raw-file image reads in the preview, and no implicit network downloads.

static func read(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	if image.is_compressed() and image.decompress() != OK:
		return null
	return image
