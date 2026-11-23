extends SceneTree
## Render actual Godot previews. Requires a graphics display (not --headless).

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Preview capture requires the graphics display driver.")
		quit(1)
		return
	var scene := load("res://Scenes/kitchen-demo.tscn").instantiate() as Node3D
	root.add_child(scene)
	root.size = Vector2i(1600, 900)
	for number in [1, 2]:
		scene.set_view(number)
		for frame in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		assert(not picture.is_empty())
		var suffix := "player" if number == 1 else "overview"
		var path := "res://Docs/scenes/kitchen-demo/godot-" + suffix + ".png"
		assert(picture.save_png(path) == OK)
		print("GODOT_PREVIEW_SAVED ", path)
	quit(0)
