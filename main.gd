extends Node2D

@export var target_to_find := 3

@onready var map_layer: CanvasLayer = $MapLayer
@onready var player: CharacterBody2D = $Player
@onready var triangulation_map: TriangulationMap = $MapLayer/TriangulationMap
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var message_layer: MessageLayer = $MessageLayer
@onready var spawn_timer: Timer = $SpawnTimer

const MAN_IN_BLACK = preload("uid://d2ag0ing1neyp")
const TRANSMITTER = preload("uid://c7v1iqui8bx7a")

var _transmitter_location := Vector2.ZERO
var _transmitters_found := 0

func _ready() -> void:
	map_layer.visible = false
	_transmitter_location = _next_transmitter_location()

func _next_transmitter_location() -> Vector2:
	var used_cells := tile_map_layer.get_used_cells()
	used_cells.shuffle()

	for cell in used_cells:
		var tile_data := tile_map_layer.get_cell_tile_data(cell)
		if tile_data and tile_data.get_collision_polygons_count(0) == 0:
			return to_global(tile_map_layer.map_to_local(cell))

	push_error("Could not find a tile")
	return Vector2.ZERO
	
func world_to_map(world_pos: Vector2) -> Vector2:
	var used_rect := tile_map_layer.get_used_rect()
	var tile_size := tile_map_layer.tile_set.tile_size

	# World bounds of the tilemap
	var origin := Vector2(used_rect.position * tile_size)
	var extent := Vector2(used_rect.size * tile_size)

	var normalized := (world_pos - origin) / extent
	# 600x320 current estimate of map
	return normalized * Vector2(600, 320)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("map"):
		if not map_layer.visible:
			map_layer.visible = true
			player.stop_moving()
			triangulation_map.show_map(world_to_map(_transmitter_location), world_to_map(player.position))
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
	var world_rect := Rect2(
		-canvas_transform.origin / canvas_transform.get_scale(),
		viewport_rect.size / canvas_transform.get_scale()
	)
	
	var margin: float = 64.0
	var max_attempts := 5
	for _i in max_attempts:
		var point := _point_in_front_of_player(world_rect, player.current_direction, margin)
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
