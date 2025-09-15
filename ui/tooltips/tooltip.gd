extends PanelContainer
class_name Tooltip

func setup(title: String, description: String) -> void:
	%Title.text = title
	%Description.text = description
	# TODO: Render bbcode into description for keywords

func get_description() -> String:
	return %Description.text
