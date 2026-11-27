extends "res://Tools/verify_dish_drop.gd"
## Regression for the requested removal of placement previews.

func verify() -> void:
	await load_game()
	expect_no_preview()
	await take_initial("TrayPlate01")
	for point in [Vector3(-0.18, 0.65, 0.04), Vector3(0.3, 0, 1.3), Vector3(-0.9, 0.94, 0.04)]:
		await view_point(point, Vector3(-0.18, 0.03, 0.8))
		expect_no_preview()
		check(carry.held_count() == 1, "Aiming at surfaces cannot place or reserve a dish.")
	router.set_interface_open(true)
	expect_no_preview()
	router.set_interface_open(false)
	var viewer := (load("res://Scenes/kitchen-demo.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(viewer)
	check(viewer.get_node_or_null("DishCarry") == null, "The asset viewer remains independent of gameplay.")
	viewer.free()
	game.free()
	if failures == 0:
		print("PLACEMENT_PREVIEW_OK: preview removed from gameplay; no ghost, green/red placement label, reservations or viewer changes.")
		quit(0)
	else:
		quit(1)
