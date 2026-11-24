extends SceneTree
## Import first, then run:
## godot --headless --path . --script Tools/verify_player_movement.gd
## Uses the real gameplay scene and physics; takes about 20 seconds.

const FORWARD: StringName = &"game_move_forward"
const BACK: StringName = &"game_move_back"
const LEFT: StringName = &"game_move_left"
const RIGHT: StringName = &"game_move_right"

var failures: int = 0
var kitchen: Node3D
var player: PlayerController
var router: GameInput
var original_tick_rate: int

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func advance_ticks(count: int) -> void:
	for index in range(count):
		await physics_frame
	# physics_frame precedes node movement; read positions after that tick completes.
	await process_frame

func send_move(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	root.push_input(event)

func reset_player(position: Vector3 = Vector3(0, 0.03, 2.0), yaw: float = 0.0, pitch: float = -0.46) -> void:
	router.set_interface_open(false)
	router.set_context(GameInput.HandMode.EMPTY, GameInput.Target.NONE)
	player.global_position = position
	player.velocity = Vector3.ZERO
	player.view_camera.rotation = Vector3(pitch, yaw, 0)
	await advance_ticks(8)

func walk_for(actions: Array[StringName], seconds: float) -> Vector3:
	var start: Vector3 = player.global_position
	for action in actions:
		send_move(action, true)
	await advance_ticks(roundi(seconds * Engine.physics_ticks_per_second))
	var displacement: Vector3 = player.global_position - start
	for action in actions:
		send_move(action, false)
	await advance_ticks(1)
	return displacement

func check_ground(context: String) -> void:
	check(player.is_on_floor(), "%s: player lost floor contact." % context)
	check(absf(player.global_position.y) < 0.005, "%s: feet must remain at floor height." % context)
	check(absf(player.view_camera.global_position.y - 1.62) < 0.005, "%s: eye height changed." % context)

func verify() -> void:
	original_tick_rate = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 60
	var packed := load("res://Scenes/kitchen-game.tscn") as PackedScene
	if packed == null:
		push_error("Could not load the gameplay scene.")
		Engine.physics_ticks_per_second = original_tick_rate
		quit(1)
		return
	kitchen = packed.instantiate() as Node3D
	root.add_child(kitchen)
	player = kitchen.get_node("Player") as PlayerController
	router = kitchen.get_node("GameInput") as GameInput
	var spawn: Vector3 = player.global_position
	await advance_ticks(8)
	check(spawn.is_equal_approx(Vector3(0, 0.03, 1.18)), "Player did not start at the safe spawn.")
	check_ground("Spawn")
	check(root.get_camera_3d() == player.view_camera, "The active camera must belong to the moving player.")
	check(not (kitchen.get_node("ViewCamera") as Camera3D).current, "The inherited viewer camera must be inactive.")
	var shape_node := player.get_node("BodyShape") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = player.collision_mask
	check(player.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Spawn capsule intersects a walk blocker.")

	var directions: Dictionary[StringName, Vector3] = {
		FORWARD: Vector3(0, 0, -1), BACK: Vector3(0, 0, 1),
		LEFT: Vector3(-1, 0, 0), RIGHT: Vector3(1, 0, 0),
	}
	for action in directions:
		await reset_player()
		var displacement: Vector3 = await walk_for([action], 0.4)
		var expected: Vector3 = directions[action] * player.walk_speed * 0.4
		check(displacement.distance_to(expected) < 0.04, "Incorrect movement direction or speed: %s." % action)
		check_ground("WASD")
	await reset_player()
	var diagonal: Vector3 = await walk_for([FORWARD, RIGHT], 0.5)
	check(absf(diagonal.length() - player.walk_speed * 0.5) < 0.04, "Diagonal movement is faster than straight movement.")
	check(diagonal.x > 0.0 and diagonal.z < 0.0, "Diagonal movement faces the wrong direction.")

	var distances: Array[float] = []
	for rate in [30, 120]:
		Engine.physics_ticks_per_second = rate
		await reset_player(Vector3(0, 0.03, 2.65))
		var displacement: Vector3 = await walk_for([FORWARD], 1.0)
		distances.append(displacement.length())
		check(absf(displacement.length() - player.walk_speed) < 0.065, "Walking speed depends on the physics tick rate.")
	check(absf(distances[0] - distances[1]) < 0.065, "30 Hz and 120 Hz travel distances differ.")
	Engine.physics_ticks_per_second = 60

	await reset_player(Vector3(0, 0.03, 2.0), PI / 2.0)
	var turned: Vector3 = await walk_for([FORWARD], 0.4)
	check(turned.distance_to(Vector3(-player.walk_speed * 0.4, 0, 0)) < 0.04, "Movement must follow the camera's horizontal heading.")
	for pitch in [deg_to_rad(-70.0), deg_to_rad(70.0)]:
		await reset_player(Vector3(0, 0.03, 2.0), 0.0, pitch)
		var displacement: Vector3 = await walk_for([FORWARD], 0.4)
		check(displacement.distance_to(Vector3(0, 0, -player.walk_speed * 0.4)) < 0.04, "Camera pitch must not alter walking speed or height.")
		check_ground("Camera pitch")

	for mode in [GameInput.HandMode.CARRYING, GameInput.HandMode.SOAP_BOTTLE]:
		await reset_player()
		router.set_context(mode, GameInput.Target.NONE)
		var displacement: Vector3 = await walk_for([FORWARD], 0.2)
		check(displacement.z < -0.25, "Carrying a dish or soap must allow walking.")
	for mode in [GameInput.HandMode.CLOSE_UP, GameInput.HandMode.TRANSITION]:
		await reset_player()
		router.set_context(mode, GameInput.Target.NONE)
		var displacement: Vector3 = await walk_for([FORWARD], 0.15)
		check(displacement.length() < 0.005, "Close-up and transitions must block walking.")
	await reset_player()
	send_move(FORWARD, true)
	await advance_ticks(8)
	router.set_interface_open(true)
	var stopped: Vector3 = player.global_position
	await advance_ticks(8)
	check(player.global_position.distance_to(stopped) < 0.005, "Opening UI must stop the moving player.")
	router.set_interface_open(false)
	await advance_ticks(8)
	check(player.global_position.distance_to(stopped) < 0.005, "Resuming must not restore a held movement key.")
	send_move(FORWARD, false)
	send_move(RIGHT, true)
	await advance_ticks(4)
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	stopped = player.global_position
	await advance_ticks(8)
	check(player.global_position.distance_to(stopped) < 0.005, "Focus loss must stop horizontal movement.")

	await reset_player(Vector3(0, 0.03, 1.18))
	await walk_for([FORWARD], 1.8)
	check(player.global_position.z > 0.619 and player.global_position.z < 0.65, "Player must stop in front of the cabinet and counter.")
	check_ground("Counter collision")
	for action in [LEFT, RIGHT]:
		await reset_player()
		await walk_for([action], 1.8)
		check(absf(player.global_position.x) > 2.25 and absf(player.global_position.x) < 2.282, "Side boundary must stop the player before the floor edge.")
		check_ground("Side boundary")
	await reset_player()
	await walk_for([BACK], 1.8)
	check(player.global_position.z > 2.8 and player.global_position.z < 2.832, "Front boundary must prevent walking off the floor.")
	check_ground("Front boundary")
	await reset_player(Vector3(1.9, 0.03, 1.5))
	await walk_for([FORWARD], 1.8)
	check(player.global_position.z > -0.182 and player.global_position.z < -0.15, "Back wall must stop the player beside the cabinet.")
	check_ground("Back wall")
	await reset_player(Vector3(0, 0.5, 2.0))
	await advance_ticks(45)
	check_ground("Landing on the floor")

	# Walk along the counter face to the tray, sink, rack and order board.
	await reset_player(Vector3(-0.89, 0.03, 1.18))
	await walk_for([FORWARD], 0.5)
	for station_x in [0.0, 0.88, 1.22]:
		var seconds: float = (station_x - player.global_position.x) / player.walk_speed
		await walk_for([RIGHT], seconds)
		check(absf(player.global_position.x - station_x) < 0.04, "The path between task areas is obstructed.")
		check(player.global_position.z > 0.619 and player.global_position.z < 0.65, "Walking along the counter entered the cabinet.")
		check_ground("Task area path")

	Engine.physics_ticks_per_second = original_tick_rate
	kitchen.free()
	if failures == 0:
		print("PLAYER_MOVEMENT_OK: WASD, camera-relative speed, mode blocking, safe spawn and kitchen collisions.")
		quit(0)
	else:
		push_error("PLAYER_MOVEMENT_FAILED: %d check(s) failed." % failures)
		quit(1)
