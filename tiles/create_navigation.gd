extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	var grid = AStarGrid2D.new()
	var rect = get_used_rect()
	#rect.size.x /= 128
	#rect.size.y /= 128
	grid.region = rect
	#print(grid.region)
	grid.cell_size = Vector2(128, 128)
	grid.update()

	for cell in get_used_cells():
		print(cell)
		grid.set_point_solid(cell)
	print("---------------")
	#print(grid)
		
	GS.nav = grid

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
