extends VBoxContainer
class_name TooltipStack

## The object that is currently being explained.
var current_owner = null

static var instance: TooltipStack = null

func _ready() -> void:
	instance = self
	
static func update_label(label, global_pos: Vector2, do_show: bool) -> void:
	if not instance:
		return
	if do_show:
		instance.show_for_label(label, global_pos)
	else:
		instance.hide_for(label)

#func _process(delta: float) -> void:
	#global_position = get_global_mouse_position()
	
func hide_for(maybe_owner) -> void:
	if maybe_owner == current_owner:
		for child in get_children():
			child.queue_free()
		current_owner = null
	
func show_for_label(label, global_pos: Vector2) -> void:
	# Don't repeatedly do the same owner
	if current_owner == label:
		# In case the position is moving
		global_position = global_pos
		return
		
	# Check if the new one is visible in tree?
	if not label.is_visible_in_tree():
		return
		
	# Clear children
	if current_owner != label:
		hide_for(current_owner)
	current_owner = label
	global_position = global_pos
	render_keyword_tooltips(label.text)
	
func add_tooltip(title: String, contents: String) -> void:
	var tooltip: Tooltip = preload("res://ui/tooltips/tooltip.tscn").instantiate()
	add_child(tooltip)
	tooltip.setup(title, contents)
	
func render_keyword(keyword: String) -> void:
	match keyword:
		"Ethereal": add_tooltip("Ethereal", "An Ethereal imp is temporary. They will automatically die after 4 seconds, and cannot be resurrected.")
		"Shield": add_tooltip("Shield", "A Buff that prevents the next damage that would kill the imp.")
		"Buff": add_tooltip("Buff", "A helpful effect that can be temporarily applied to an imp. Each imp can hold up to 3 Buffs.")
	
func render_keyword_tooltips_in_string(key_string: String, avail: Dictionary[String, bool]) -> void:
	for key in avail.keys():
		if key in key_string:
			render_keyword(key)
			avail.erase(key)
	
func render_keyword_tooltips(key_string: String) -> void:
	var avail: Dictionary[String, bool] = {
		"Ethereal": true,
		"Shield": true,
		"Buff": true,
	}
	
	render_keyword_tooltips_in_string(key_string, avail)
	
	for child in get_children():
		# Skip the children we just deleted
		if not child.is_queued_for_deletion():
			render_keyword_tooltips_in_string(child.get_description(), avail)
	
