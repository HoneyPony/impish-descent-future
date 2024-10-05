extends ColorRect

func setup(data):
	var klass = data[0]
	var item = data[1]
	var description = data[2]
	
	$Body.texture = GS.get_body_tex(klass)
	$Item.texture = GS.get_item_tex(item)
	$Label.text = description
