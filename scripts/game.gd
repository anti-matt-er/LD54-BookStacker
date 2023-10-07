extends Node3D

const BOX_SIZE := 0.4 - 0.00001
const MAX_RAY_POS := Vector3(BOX_SIZE, 0, BOX_SIZE) / 2
const CAMERA_RAY_LENGTH := 10.0
const WATCH_PROJECTION_DEPTH := 0.25

@onready var camera: Camera3D = $Camera
@onready var place_ray := $PlaceCast
@onready var book_ray := $BookRay
@onready var box := $Scenery/box
@onready var ray_origin := Vector3(
	box.global_position.x,
	camera.box_angle.global_position.y,
	box.global_position.z
)
@onready var box_animation := box.get_node("AnimationPlayer")
@onready var box_limit := $BoxLimit
@onready var y_limit: float = box_limit.global_position.y
@onready var shelf_arrow := %ShelfArrow
@onready var box_arrow := %BoxArrow
@onready var music := $Music
@onready var stopwatch := %Stopwatch
@onready var stopwatch_scene := %StopwatchScene
@onready var stopwatch_anchor: Control = %StopwatchAnchor
@onready var timer_display := %TimerDisplay

var placing := false
var book_bounds_limit := Vector3.ZERO


func _ready() -> void:
	box_limit.hide()
	await get_tree().process_frame
	music.play()
	stopwatch.set_timer(60, true)
	stopwatch.running_out.connect(func(): timer_display.set_low(true))


func _physics_process(_delta: float) -> void:
	if placing:
		var mouse_pos = get_viewport().get_mouse_position()
		place_ray.transform.origin = camera.project_ray_origin(mouse_pos)
		place_ray.target_position = camera.project_ray_normal(mouse_pos) * CAMERA_RAY_LENGTH
		if place_ray.is_colliding():
			book_ray.global_position = place_ray.get_collision_point().clamp(
				ray_origin - MAX_RAY_POS + book_bounds_limit,
				ray_origin + MAX_RAY_POS - book_bounds_limit
			)


func _process(_delta: float) -> void:
	position_stopwatch()
	timer_display.text = str(floori(stopwatch.remaining / 60)) + ":" + str(stopwatch.remaining % 60).pad_zeros(2)


func position_stopwatch() -> void:
	var anchor_rect = stopwatch_anchor.get_global_rect()
	
	var top_left = camera.project_position(anchor_rect.position, WATCH_PROJECTION_DEPTH)
	var top_right = camera.project_position(anchor_rect.position + Vector2(anchor_rect.size.x, 0), WATCH_PROJECTION_DEPTH)
	var bottom_left = camera.project_position(anchor_rect.position + Vector2(0, anchor_rect.size.y), WATCH_PROJECTION_DEPTH)
	var center = camera.project_position(anchor_rect.get_center(), WATCH_PROJECTION_DEPTH)
	
	var width = top_left.distance_to(top_right)
	var height = top_left.distance_to(bottom_left)
	var anchor_min_dimension = minf(width, height)
	var watch_max_dimension = stopwatch.max_dimension
	
	stopwatch_scene.look_at_from_position(center, camera.global_position,
	Vector3.UP.rotated(
		Vector3.BACK, camera.rotation.z
	).rotated(
		Vector3.RIGHT, camera.rotation.x
	).rotated(
		Vector3.UP, camera.rotation.y
	), true)
	stopwatch.scale = Vector3.ONE * anchor_min_dimension / watch_max_dimension
