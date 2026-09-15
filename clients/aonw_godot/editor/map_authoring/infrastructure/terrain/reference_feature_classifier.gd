@tool
extends RefCounted
## Reference colours refine a smooth semantic prior, never replace the water mask.
## Scores are evidence, not botanical/image-segmentation ground truth.

static func luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722

static func classify(prior: PackedFloat32Array, color: Color, average: Color,
		forest_context: float, threshold: float, strength: float) -> Dictionary:
	var green := smoothstep(0.015, 0.15, average.g - average.b)
	green *= 1.0 - smoothstep(0.03, 0.15, average.r - average.g)
	var darkness := 1.0 - smoothstep(threshold, threshold + 0.22, luminance(average))
	var texture := clampf(absf(luminance(color) - luminance(average)) * 8.0, 0.0, 1.0)
	var evidence := green * darkness * (0.8 + 0.2 * texture)
	# Neighbouring forest tags allow a continuous boundary, without rectangular/hex patches.
	var supported := smoothstep(0.02, 0.3, maxf(prior[1], forest_context))
	var canopy := lerpf(prior[1], evidence * supported, strength)
	var snow := smoothstep(0.63, 0.88, average.v) * (1.0 - smoothstep(0.12, 0.38, average.s))
	var rock := (1.0 - smoothstep(0.18, 0.55, average.s)) * (1.0 - snow)
	var dry := smoothstep(0.07, 0.24, average.r - average.b)
	var evidence_weights := PackedFloat32Array([
		maxf(0.06, green * (1.0 - canopy)), canopy,
		dry * maxf(prior[2], 0.05), snow * maxf(prior[3], prior[4]),
		rock * maxf(0.15, prior[4]), prior[5] * (1.0 - green * 0.5),
	])
	var result := prior.duplicate()
	var sum := 0.0
	for weight in evidence_weights:
		sum += weight
	for index in result.size():
		result[index] = lerpf(prior[index], evidence_weights[index] / maxf(sum, 0.0001), strength)
	# Snow can cover forest floor while the dark canopy above it remains visible.
	if prior[3] > 0.5:
		result[3] = maxf(result[3], prior[3] * 0.8)
		result[1] *= 0.1
	sum = 0.0
	for weight in result:
		sum += weight
	for index in result.size():
		result[index] /= maxf(sum, 0.0001)
	return {"weights": result, "canopy": clampf(canopy, 0.0, 1.0)}
