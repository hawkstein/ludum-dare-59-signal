extends Node2D

@onready var map_layer: CanvasLayer = $MapLayer
@onready var player: CharacterBody2D = $Player
@onready var triangulation_map: TriangulationMap = $MapLayer/TriangulationMap
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
const TRANSMITTER = preload("uid://c7v1iqui8bx7a")
var _transmitter_location := Vector2(626, -44)

func _ready() -> void:
	map_layer.visible = false
	
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
	var transmitter = TRANSMITTER.instantiate()
	transmitter.position = _transmitter_location
	add_child(transmitter)
