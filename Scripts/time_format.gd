extends RefCounted

class_name TimeFormat

static func short(seconds: float) -> String:
	var total: int = int(ceil(seconds))
	if total >= 60:
		return "%d:%02d" % [floori(total / 60.0), total % 60]
	return str(total)
