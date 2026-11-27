extends "res://Tools/verify_dish_drop.gd"
## Actual gravity-driven ceramic contacts rather than a solved static stack.

func verify() -> void:
	await load_game()
	var pieces: Array[DishBody] = []
	for name: String in ["TrayPlate01", "TrayPlate02", "TrayMug01"]:
		var dish: DishBody = await take_initial(name)
		await view_point(Vector3(-0.18, 0.65, 0.04), Vector3(-0.18, 0.03, 0.65))
		tap(&"game_drop")
		check(dish.location == DishBody.Location.WORLD, "G releases into real overlapping ceramic contacts.")
		await ticks(180)
		check(dish.global_position.y > 0.58 and dish.global_position.y < 0.9 and absf(dish.global_position.x) < 0.52, "Each real dish must settle in the basin rather than falling through its support.")
		pieces.append(dish)
	check(pieces[1].global_position.y > pieces[0].global_position.y + 0.003, "The second plate must physically rest above the first.")
	check(carry.held_count() == 0 and registry.slots.size() == 11, "A physical stack does not create basin slots or duplicate held dishes.")
	for dish in pieces:
		check(registry.find_occupied_slot(dish.instance_id) == null, "Physics owns support without basin slot occupancy.")
	await aim(pieces[2])
	tap(&"game_interact")
	check(carry.selected_dish == pieces[2], "The top mug can be repicked after its physical motion stops.")
	game.free()
	if failures == 0:
		print("BASIN_STACKING_OK: original plates/mug, gravity and ceramic collisions, settled basin overlap, no fixed slots/static dependencies, repick.")
		quit(0)
	else:
		quit(1)
