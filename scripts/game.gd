extends Node3D

const BOX_SIZE := 0.4 - 0.00001
const MAX_RAY_POS := Vector3(BOX_SIZE, 0, BOX_SIZE) / 2
const CAMERA_RAY_LENGTH := 10.0
const WATCH_PROJECTION_DEPTH := 0.25
const TIME_BONUS_MULTIPLIER := 0.1
const BASE_BOX_SCORE := 100
const BOX_OFFSCREEN_OFFSET := 2.25
const BOX_OFFSCREEN_TRANSITION := 0.5

@export var difficulty: Difficulty

@onready var camera: Camera3D = $Camera
@onready var place_ray := $PlaceCast
@onready var book_ray := $BookRay
@onready var box := $Scenery/box
@onready var shelf := $Scenery/Shelf
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
@onready var score_display := %ScoreValue

var placing := false
var box_ready := false
var book_bounds_limit := Vector3.ZERO
var score := 0
var level := 0
var tween: Tween


func _ready() -> void:
	box_limit.hide()
	await get_tree().process_frame
	music.play()
	stopwatch.running_out.connect(func(): timer_display.set_low(true))
	start()


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


func start() -> void:
	score = 0
	update_score()
	ready_box()


func start_stopwatch(time: int) -> void:
	stopwatch.set_timer(time, true)
	timer_display.set_low(false)


func ready_box() -> void:
	shelf.stack_until_full()
	start_stopwatch(max(difficulty.min_time, difficulty.start_time - difficulty.time_decrement * level))
	box_ready = true


func update_score() -> void:
	score_display.text = str(score)


func complete_box() -> void:
	box_ready = false
	stopwatch.stop()
	camera.switch_to_complete()
	
	await get_tree().create_timer(camera.TRANSITION_TIME).timeout
	
	box_animation.play("Animation")
	
	await box_animation.animation_finished
	
	shelf.reset()
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(box, "position:x", BOX_OFFSCREEN_OFFSET, BOX_OFFSCREEN_TRANSITION)
	
	await get_tree().create_timer(BOX_OFFSCREEN_TRANSITION).timeout
	
	var bonus_score = floori(stopwatch.remaining * TIME_BONUS_MULTIPLIER)
	score += BASE_BOX_SCORE + bonus_score
	update_score()
	level += 1
	new_box()


func new_box() -> void:
	if tween:
		tween.kill()
	
	box_animation.play("Animation")
	box_animation.seek(0)
	box_animation.stop()
	box.position.x = -BOX_OFFSCREEN_OFFSET
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(box, "position:x", 0, BOX_OFFSCREEN_TRANSITION)
	
	await get_tree().create_timer(BOX_OFFSCREEN_TRANSITION).timeout
	
	camera.switch_to_idle()
	
	await get_tree().create_timer(camera.TRANSITION_TIME).timeout
	
	ready_box()


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
