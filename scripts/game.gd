extends Node3D

const BOX_SIZE := 0.4 - 0.00001
const MAX_RAY_POS := Vector3(BOX_SIZE, 0, BOX_SIZE) / 2
const CAMERA_RAY_LENGTH := 10.0
const WATCH_PROJECTION_DEPTH := 0.25
const TIME_BONUS_MULTIPLIER := 0.1
const BASE_BOX_SCORE := 100
const BOX_OFFSCREEN_OFFSET := 2.25
const BOX_OFFSCREEN_TRANSITION := 0.5
const FLYTEXT_GROW := Vector2.ONE * 2.0
const FLYTEXT_GROW_RATIO :=  0.5
const FLYTEXT_TRANSITION := 0.75
const FLYTEXT_HOLD := 0.65
const MENU_TRANSITION := 1.5
const TIMEOUT_HOLD := 2.0
const TUTORIAL_TRANSITION := 0.5
const FULLSCREEN_MODE := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
const TUTORIALS := {
	"pickup": "Click a book on the shelf to pick it up!",
	"place": "Click anywhere in the bounds of the box to place the book!",
	"cancel": "Right click, or click the upwards arrow to cancel placement!",
	"rotate": "Use the WASD keys to rotate the book!"
}

@export var difficulty: Difficulty

@onready var start_screen := %StartScreen
@onready var game_ui := %GameUI
@onready var timeout_screen := %Timeout
@onready var results_screen := %ResultsScreen
@onready var blur := %Blur
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
@onready var box_confetti := box.get_node("Confetti")
@onready var box_limit := $BoxLimit
@onready var y_limit: float = box_limit.global_position.y
@onready var shelf_arrow := %ShelfArrow
@onready var box_arrow := %BoxArrow
@onready var music := $Music
@onready var box_complete_sfx := $BoxCompleteSFX
@onready var score_increment_sfx := $ScoreIncrementSFX
@onready var stopwatch := %Stopwatch
@onready var stopwatch_scene := %StopwatchScene
@onready var stopwatch_anchor: Control = %StopwatchAnchor
@onready var timer_display := %TimerDisplay
@onready var score_display := %ScoreValue
@onready var box_score_flytext := %BoxScore
@onready var menu_animation := $Camera/MenuAnimation
@onready var results_boxes := %BoxesValue
@onready var results_timebonus := %TimeBonusValue
@onready var results_total := %TotalValue
@onready var results_highscore := %NewHighScore
@onready var tutorial_box := %Tutorial
@onready var tutorial_text := %TutorialText
@onready var pause_screen := %PauseScreen

var started := false
var fullscreen := false
var fullscreen_hack_firstrun := true
var placing := false
var box_ready := false
var book_bounds_limit := Vector3.ZERO
var score := 0
var last_score_update := 0
var level := 0
var total_time_bonus := 0
var tween: Tween
var flytext_tween: Tween
var score_tween: Tween
var active_tutorial: String

signal menu_enabled(enabled: bool)


func _ready() -> void:
	box_limit.hide()
	
	await get_tree().process_frame
	
	if "fullscreen" in SaveManager.options:
		fullscreen = SaveManager.options.fullscreen
		set_fullscreen(fullscreen)
	else:
		var window_mode = DisplayServer.window_get_mode()
		fullscreen = (window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN || window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		if fullscreen && window_mode != FULLSCREEN_MODE:
			set_fullscreen(true)
		SaveManager.options["fullscreen"] = fullscreen
	
	menu_animation.play("pulse")
	stopwatch.running_out.connect(func(): timer_display.set_low(true))
	stopwatch.finished.connect(time_over)


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
	
	if Input.is_action_just_pressed("debug_complete"):
		complete_box()
	
	if Input.is_action_just_pressed("debug_timeout"):
		stopwatch.set_timer(0)
		stopwatch.stop()
	
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()


func set_fullscreen(state: bool) -> void:
	if state:
		DisplayServer.window_set_mode(FULLSCREEN_MODE)
	else:
		if fullscreen_hack_firstrun:
			fullscreen_hack_firstrun = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(Helper.viewport_size)
	
	fullscreen = state
	SaveManager.options.fullscreen = fullscreen


func toggle_fullscreen() -> void:
	set_fullscreen(!fullscreen)


func start() -> void:
	score = 0
	level = 0
	total_time_bonus = 0
	update_score(0)
	music.play()
	
	menu_animation.stop(true)
	start_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_enabled.emit(false)
	
	camera.start()
	start_screen.animate(0.0, MENU_TRANSITION)
	results_screen.animate(0.0, MENU_TRANSITION)
	blur.animate(0.0, MENU_TRANSITION)
	
	await get_tree().create_timer(camera.SLOW_PAN_TIME).timeout
	
	started = true
	ready_box()
	
	await get_tree().process_frame
	
	game_ui.animate(1.0, MENU_TRANSITION)
	stopwatch_scene.show()
	position_stopwatch()
	
	await get_tree().create_timer(MENU_TRANSITION).timeout
	
	show_tutorial("pickup")


func show_tutorial(tutorial: String) -> void:
	if tutorial_box.onscreen || SaveManager.tutorials[tutorial]:
		return
	
	if tutorial_box.tween && tutorial_box.tween.is_running():
		await tutorial_box.tween.finished
	
	active_tutorial = tutorial
	tutorial_text.text = TUTORIALS[tutorial]
	tutorial_box.animate(true, TUTORIAL_TRANSITION)


func complete_tutorial(tutorial: String) -> void:
	if !tutorial_box.onscreen || tutorial != active_tutorial || SaveManager.tutorials[tutorial]:
		return

	if tutorial_box.tween && tutorial_box.tween.is_running():
		await tutorial_box.tween.finished
	
	SaveManager.tutorials[tutorial] = true
	SaveManager.save_tutorials()
	tutorial_box.animate(false, TUTORIAL_TRANSITION)


func start_stopwatch(time: int) -> void:
	stopwatch.set_timer(time, true)
	timer_display.set_low(false)


func ready_box() -> void:
	shelf.stack_until_full()
	
	await shelf.stacked
	
	start_stopwatch(max(difficulty.min_time, difficulty.start_time - difficulty.time_decrement * level))
	box_ready = true


func award_score(value: int, bonus: int) -> void:
	total_time_bonus += bonus
	
	box_confetti.emitting = true
	box_complete_sfx.play()
	
	await animate_flytext(value, camera.unproject_position(box.global_position) - box_score_flytext.size / 2)
	animate_score(value)
	
	if bonus > 0:
		await animate_flytext(bonus, timer_display.get_global_rect().position)
		animate_score(bonus)
	
	return


func animate_flytext(value: int, start_pos: Vector2) -> void:	
	box_score_flytext.text = "+" + str(value)
	box_score_flytext.position = start_pos
	
	await RenderingServer.frame_post_draw
	
	var center_offset = box_score_flytext.size / 2
	var score_screen_pos = score_display.get_global_rect().position
	var center_screen_pos = get_viewport().get_visible_rect().size / 2 - center_offset
	
	box_score_flytext.modulate.a = 1
	box_score_flytext.pivot_offset = center_offset
	box_score_flytext.scale = Vector2.ZERO
	
	if flytext_tween:
		flytext_tween.kill()
	
	flytext_tween = create_tween()
	flytext_tween.set_trans(Tween.TRANS_SPRING)
	flytext_tween.set_ease(Tween.EASE_OUT)
	flytext_tween.tween_property(box_score_flytext, "position", center_screen_pos, FLYTEXT_TRANSITION * FLYTEXT_GROW_RATIO)
	flytext_tween.parallel().tween_property(box_score_flytext, "scale", FLYTEXT_GROW, FLYTEXT_TRANSITION * FLYTEXT_GROW_RATIO)
	flytext_tween.tween_interval(FLYTEXT_HOLD)
	flytext_tween.set_trans(Tween.TRANS_QUINT)
	flytext_tween.set_ease(Tween.EASE_IN)
	flytext_tween.tween_property(box_score_flytext, "position", score_screen_pos, FLYTEXT_TRANSITION * (1.0 - FLYTEXT_GROW_RATIO))
	flytext_tween.parallel().tween_property(box_score_flytext, "scale", Vector2.ZERO, FLYTEXT_TRANSITION * (1.0 - FLYTEXT_GROW_RATIO))
	
	await flytext_tween.finished
	box_score_flytext.modulate.a = 0
	return


func animate_score(value: int) -> void:
	score += value
	last_score_update = 0
	
	if score_tween:
		score_tween.kill()
	
	score_tween = create_tween()
	score_tween.set_trans(Tween.TRANS_SINE)
	score_tween.set_ease(Tween.EASE_OUT)
	score_tween.tween_method(update_score_from_tween, value, 0, FLYTEXT_TRANSITION + FLYTEXT_HOLD / 2.0)


func update_score(value: int) -> void:
	var to_add = ""
	if value:
		to_add = "+ " + str(value)
	
	score_display.text = str(score - value) + to_add


func update_score_from_tween(value: int) -> void:
	if value != last_score_update:
		update_score(value)
		score_increment_sfx.play()
		last_score_update = value


func complete_box() -> void:
	box_ready = false
	stopwatch.stop()
	camera.switch_to_complete()
	
	await get_tree().create_timer(camera.TRANSITION_TIME).timeout
	
	box_animation.play("Animation")
	await box_animation.animation_finished
	
	await award_score(BASE_BOX_SCORE, floori(stopwatch.remaining * TIME_BONUS_MULTIPLIER))
	
	shelf.reset()
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(box, "position:x", BOX_OFFSCREEN_OFFSET, BOX_OFFSCREEN_TRANSITION)
	
	await get_tree().create_timer(BOX_OFFSCREEN_TRANSITION).timeout
	
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
	if !stopwatch_scene.visible:
		return
	
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


func end_game() -> void:
	if pause_screen.paused:
		pause_screen.toggle_pause(true)
	
	started = false
	music.stop()
	box_ready = false


func time_over() -> void:
	end_game()
	
	timeout_screen.transition_in()
	camera.switch_to_complete()
	
	await get_tree().create_timer(TIMEOUT_HOLD).timeout
	
	timeout_screen.transition_out()
	
	show_results()


func show_results() -> void:
	results_boxes.text = str(level)
	results_timebonus.text = str(total_time_bonus)
	results_total.text = str(score)
	
	if score > SaveManager.highscore:
		results_highscore.show()
		SaveManager.highscore = score
		SaveManager.save_score()
	else:
		results_highscore.hide()
	
	menu_enabled.emit(true)
	
	results_screen.animate(1.0, MENU_TRANSITION)
	game_ui.animate(0.0, MENU_TRANSITION)
	blur.animate(1.0, MENU_TRANSITION)
	
	await get_tree().create_timer(MENU_TRANSITION).timeout
	
	stopwatch_scene.hide()
	shelf.reset()


func main_menu() -> void:
	end_game()
	
	stopwatch_scene.hide()
	shelf.reset()
	start_screen.mouse_filter = Control.MOUSE_FILTER_PASS
	menu_enabled.emit(true)
	
	camera.end()
	start_screen.animate(1.0, MENU_TRANSITION)
	results_screen.animate(0.0, MENU_TRANSITION)
	game_ui.animate(0.0, MENU_TRANSITION)
	blur.animate(1.0, MENU_TRANSITION)
	
	await get_tree().create_timer(camera.SLOW_PAN_TIME).timeout
	
	menu_animation.play("pulse")
