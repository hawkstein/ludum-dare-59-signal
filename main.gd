extends Node2D

@export var target_to_find := 3

@onready var map_layer: CanvasLayer = $MapLayer
@onready var player: CharacterBody2D = $Player
@onready var triangulation_map: TriangulationMap = $MapLayer/TriangulationMap
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
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
		_transmitter_location = _next_transmitter_location()
		triangulation_map.clear()

func _switch_to_win() -> void:
	get_tree().change_scene_to_file("res://narrative/win.tscn")
