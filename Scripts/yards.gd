class_name Yards
extends RefCounted

const PIXELS: float = 25.0

static func to_px(yards: float) -> float:
	return yards * PIXELS
