extends RefCounted

class_name RichTooltip

static func make(bbcode: String) -> Control:
	if bbcode.strip_edges().is_empty():
		return null
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(260, 0)
	label.text = bbcode
	return label
