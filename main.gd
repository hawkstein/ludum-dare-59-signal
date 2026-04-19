extends Node2D

@export var target_to_find := 3

@onready var map_layer: CanvasLayer = $MapLayer
@onready var player: CharacterBody2D = $Player
@onready var triangulation_map: TriangulationMap = $MapLayer/TriangulationMap
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var message_layer: MessageLayer = $MessageLayer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var message_timer: Timer = $MessageTimer

const MAN_IN_BLACK = preload("uid://d2ag0ing1neyp")
const TRANSMITTER = preload("uid://c7v1iqui8bx7a")

var _transmitter_location := Vector2.ZERO
var _transmitters_found := 0
var world_rect := Rect2(-2336, -1248, 4960, 2912)
var mini_rect := Rect2(0, 0, 600, 320)

var intro_messages := ["Wolfgang: Find the alien transmissions", "Wolfgang: Triangulate the signals on the map (Press M)", "Darren: and watch out for the men in black!"]
var current_message := 0

func _ready() -> void:
	map_layer.visible = false
	_transmitter_location = _next_transmitter_location()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	message_layer.display_message("Wolfgang: Ben come in! This is Wolfgang, over.")

func _next_transmitter_location() -> Vector2:
	var location:Vector2 = Vector2.ZERO
	while location == Vector2.ZERO:
		# TODO: do the rect calc properly
		var random_point := Vector2(
			randf_range(world_rect.position.x, world_rect.end.x),
			randf_range(world_rect.position.y, world_rect.end.y)
		)
		var tile_coords := tile_map_layer.local_to_map(tile_map_layer.to_local(random_point))
		if _tile_without_collision(tile_coords):
			location = random_point
	return location

	
func _remap_position(pos: Vector2, from: Rect2, to: Rect2) -> Vector2:
	var normalized := (pos - from.position) / from.size
	return to.position + normalized * to.size

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("map"):
		if not map_layer.visible:
			map_layer.visible = true
			triangulation_map.show_map(_remap_position(_transmitter_location, world_rect, mini_rect), _remap_position(player.position, world_rect, mini_rect), player.current_direction)
			player.stop_moving()
		else:
			map_layer.visible = false
			player.start_moving()
			triangulation_map.hide_map()

func _on_triangulation_map_map_closed() -> void:
	map_layer.visible = false
	player.start_moving()
	triangulation_map.hide_map()


func _on_triangulation_map_signal_triangulated() -> void:
	var transmitter:Transmitter = TRANSMITTER.instantiate()
	transmitter.position = _transmitter_location
	transmitter.connect("transmitter_found", _on_transmitter_found)
	add_child(transmitter)

func _on_transmitter_found() -> void:
	_transmitters_found += 1
	if _transmitters_found >= target_to_find:
		call_deferred("_switch_to_win")
	else:
		spawn_timer.wait_time = 3.5 - _transmitters_found
		_transmitter_location = _next_transmitter_location()
		triangulation_map.clear()
		var info := {"num_transmitters": target_to_find - _transmitters_found}
		message_layer.display_message("Wolfgang: Nice work! We only need to find {num_transmitters} more".format(info))

func _switch_to_win() -> void:
	get_tree().change_scene_to_file("res://narrative/win.tscn")


func _on_spawn_timer_timeout() -> void:
	if player.current_direction == Vector2i.ZERO:
		return
	var mib_position := _find_spawn_position()
	if mib_position != Vector2.ZERO:
		var mib := MAN_IN_BLACK.instantiate()
		add_child(mib)
		mib.position = mib_position
		mib.add_to_group("mib")
		#print("spawned man in black")
	#else:
		#print("could not find spawn position for mib")

func _find_spawn_position(
) -> Vector2:
	var viewport_rect := get_viewport().get_visible_rect()
	var canvas_transform := get_canvas_transform()
	var other_world_rect := Rect2(
		-canvas_transform.origin / canvas_transform.get_scale(),
		viewport_rect.size / canvas_transform.get_scale()
	)
	
	var margin: float = 64.0
	var max_attempts := 5
	for _i in max_attempts:
		var point := _point_in_front_of_player(other_world_rect, player.current_direction, margin)
		var tile_coords := tile_map_layer.local_to_map(tile_map_layer.to_local(point))

		if _tile_without_collision(tile_coords) and _away_from_transmitter(point):
			return point

	return Vector2.ZERO


func _point_in_front_of_player(
	rect: Rect2, facing: Vector2i, margin: float
) -> Vector2:
	var pos := Vector2.ZERO
	
	match facing:
		Vector2i.RIGHT:
			pos.x = rect.end.x + margin + randf() * margin
			pos.y = randf_range(rect.position.y, rect.end.y)
		Vector2i.LEFT:
			pos.x = rect.position.x - margin - randf() * margin
			pos.y = randf_range(rect.position.y, rect.end.y)
		Vector2i.DOWN:
			pos.y = rect.end.y + margin + randf() * margin
			pos.x = randf_range(rect.position.x, rect.end.x)
		Vector2i.UP:
			pos.y = rect.position.y - margin - randf() * margin
			pos.x = randf_range(rect.position.x, rect.end.x)
	
	return pos


func _tile_without_collision(coords: Vector2i) -> bool:
	var tile_data := tile_map_layer.get_cell_tile_data(coords)
	if tile_data == null:
		return false
	
	var physics_layers_count := tile_map_layer.tile_set.get_physics_layers_count()
	for i in physics_layers_count:
		if tile_data.get_collision_polygons_count(i) > 0:
			return false
	
	return true

func _away_from_transmitter(mib_position: Vector2) -> bool:
	var min_distance := 96 # 64 radius of mib + 1 tile 32px
	return _transmitter_location.distance_to(mib_position) > min_distance

func _on_bounds_warning_body_entered(body: Node2D) -> void:
	if body.has_method("reverse_direction"):
		body.reverse_direction()
		message_layer.display_message("Darren: You're heading out of town bud, turn around now!")


func _on_message_timer_timeout() -> void:
	message_layer.display_message(intro_messages[current_message])
	current_message += 1
	if current_message < intro_messages.size():
		message_timer.start()
