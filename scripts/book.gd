extends RigidBody3D
class_name Book


const MAX_DIMENSIONS := Vector3(0.05, 0.315, 0.222)
const MIN_DIMENSIONS := Vector3(0.01, 0.105, 0.074)
const MIN_RANGE := Vector3(-0.5, -0.5, -0.5)
const MAX_RANGE := Vector3(1.5, 0.5, 0.5)
const WIDTH_VARIANCE := 0.25
const MAX_MARGIN := 32
const DPI := 4000
const TITLE_YMARGIN := 10
const COLOR_SATURATION_RANGE := Vector2(0.05, 0.9)
const COLOR_VALUE_RANGE := Vector2(0.2, 0.5)
const ROTATION_TIME := 0.35
const CUBIC_WEIGHT := 1201.0
const INVALID_MATERIAL := preload("res://assets/materials/invalid.material")
const OFFSCREEN_Y_OFFSET := 1.0
const TILT_ANGLE := deg_to_rad(10)
const TILT_TIME := 0.25
const TILT_OFFSET := 0.05

@export var fonts: Array[Font]
@export var font_uppercase_disable: Array[bool]

@onready var game := find_parent("Game")

var mesh: MeshInstance3D
var collider: CollisionShape3D
var spineVP: SubViewport
var spineDesign: Container
var spineDecal: Decal
var coverVP: SubViewport
var coverDesign: Container
var coverDecal: Decal
var title := ""
var size: Vector3
var dimensions: Vector3
var initial_position: Vector3
var shelf: Node3D
var coverMaterial: StandardMaterial3D
var target_quaternion := Quaternion.IDENTITY
var tween: Tween
var picked_up := false
var placed := false
var can_place := false
var invalid := false
var font_index: int
var titleFontSize: int
var tilt_pivot: Vector3
var pivot_helper: Node3D

signal generated


func setup() -> void:
	hide()
	
	mesh = $Book
	collider = $Collider
	spineVP = $SpineVP
	spineDesign = $SpineVP/Spine
	spineDecal = $SpineDecal
	coverVP = $CoverVP
	coverDesign = $CoverVP/Cover
	coverDecal = $CoverDecal
	
	collider.shape = collider.shape.duplicate()
	
	coverMaterial = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, coverMaterial)
	
	input_event.connect(pick_up)
	mouse_entered.connect(func(): tilt(false))
	mouse_exited.connect(func(): tilt(true))
	
	await get_tree().process_frame
	game.shelf_arrow.clicked.connect(cancel_placement)


func generate() -> void:
	randomize()
	
	title = TitleGenerator.generate_title()
	font_index = randi() % fonts.size()
	if !font_uppercase_disable[font_index] && randi() % 2:
		title = title.to_upper()
	var thickness = randf_range(MIN_RANGE.x, MAX_RANGE.x)
	var height = randf_range(MIN_RANGE.y, MAX_RANGE.y)
	var width = clampf((height + randf_range(-WIDTH_VARIANCE, WIDTH_VARIANCE)), MIN_RANGE.z, MAX_RANGE.z)
	size = Vector3(thickness, height, width)
	dimensions = Vector3(
		remap(size.x, MIN_RANGE.x, MAX_RANGE.x, MIN_DIMENSIONS.x, MAX_DIMENSIONS.x),
		remap(size.y, -1.0, 1.0, MIN_DIMENSIONS.y, MAX_DIMENSIONS.y),
		remap(size.z, -1.0, 1.0, MIN_DIMENSIONS.z, MAX_DIMENSIONS.z)
	)
	mass = dimensions.x * dimensions.y * dimensions.z
	
	modify_mesh()
	modify_spine()
	modify_cover()
	
	await RenderingServer.frame_post_draw
	
	generated.emit()


func modify_mesh() -> void:
	mesh.set_blend_shape_value(
		mesh.find_blend_shape_by_name("Thickness"),
		size.x
	)
	mesh.set_blend_shape_value(
		mesh.find_blend_shape_by_name("Height"),
		size.y
	)
	mesh.set_blend_shape_value(
		mesh.find_blend_shape_by_name("Width"),
		size.z
	)
	
	collider.shape.size = dimensions
	
	coverMaterial.albedo_color = Color.from_hsv(
		randf(),
		randf_range(COLOR_SATURATION_RANGE.x, COLOR_SATURATION_RANGE.y),
		randf_range(COLOR_VALUE_RANGE.x, COLOR_VALUE_RANGE.y)
	)


func get_text_bounds(text: String, font_size: int, style: Dictionary, width: float) -> Vector2:
	return style.font.get_multiline_string_size(
		text, style.halign, width, font_size, -1, style.breaks, style.justify
	)


func modify_spine() -> void:
	var res = (Vector2(dimensions.y, dimensions.x) * DPI).round()
	spineVP.size = res
	spineVP.size_2d_override = res
	spineDesign.size = res
	
	await get_tree().process_frame
	
	var titleLabel = spineDesign.get_node("Title")
	var titleBoxSize = titleLabel.size
	titleBoxSize.y -= TITLE_YMARGIN
	var titleSettings = titleLabel.label_settings.duplicate()
	titleSettings.font = fonts[font_index]
	var titleStyle = {
		"font": titleSettings.font,
		"halign": titleLabel.horizontal_alignment,
		"breaks": TextServer.BREAK_WORD_BOUND, # Should get this from auto-wrap settings instead
		"justify": titleLabel.justification_flags
	}
	titleFontSize = titleSettings.font_size
	var titleBounds = get_text_bounds(title, titleFontSize, titleStyle, titleBoxSize.x)
	
	if titleBounds.y > titleBoxSize.y:
		while titleBounds.y > titleBoxSize.y:
			titleFontSize -= 1
			titleBounds = get_text_bounds(title, titleFontSize, titleStyle, titleBoxSize.x)
			# When shrinking, we should know as soon as it fits
	elif titleBounds.y < titleBoxSize.y:
		while titleBounds.y < titleBoxSize.y:
			titleFontSize += 1
			titleBounds = get_text_bounds(title, titleFontSize, titleStyle, titleBoxSize.x)
		
		if titleBounds.y > titleBoxSize.y:
			titleFontSize -= 1
			# When growing, we need to check that it fits once more and adjust accordingly
	
	titleLabel.text = title
	titleSettings.font_size = titleFontSize
	titleLabel.label_settings = titleSettings
	
	if randi() % 2:
		spineDesign.get_node("Top Dot").hide()
		spineDesign.get_node("Bottom Dot").hide()
	if randi() % 2:
		spineDesign.get_node("Top Line1").hide()
		spineDesign.get_node("Bottom Line1").hide()
	if randi() % 2:
		spineDesign.get_node("Top Line2").hide()
		spineDesign.get_node("Bottom Line2").hide()
	if randi() % 2:
		spineDesign.get_node("Top Line3").hide()
		spineDesign.get_node("Bottom Line3").hide()
	
	var margin = randi_range(0, MAX_MARGIN)
	spineDesign.get_node("Top Margin1").custom_minimum_size.x = margin
	spineDesign.get_node("Top Margin2").custom_minimum_size.x = margin
	spineDesign.get_node("Bottom Margin1").custom_minimum_size.x = margin
	spineDesign.get_node("Bottom Margin2").custom_minimum_size.x = margin
	
	spineVP.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	await RenderingServer.frame_post_draw
	
	spineDecal.set_texture(Decal.TEXTURE_ALBEDO, spineVP.get_texture())
	spineDecal.size.x = dimensions.y
	spineDecal.size.z = dimensions.x
	spineDecal.position.z = dimensions.z / 2.0
	coverVP.render_target_update_mode = SubViewport.UPDATE_DISABLED


func modify_cover() -> void:
	var res = (Vector2(dimensions.z, dimensions.y) * DPI).round()
	coverVP.size = res
	coverVP.size_2d_override = res
	coverDesign.size = res
	
	await get_tree().process_frame
	
	var titleLabel = coverDesign.get_node("Title")
	var titleSettings = titleLabel.label_settings.duplicate()
	titleSettings.font = fonts[font_index]

	titleLabel.text = title
	titleSettings.font_size = titleFontSize
	titleLabel.label_settings = titleSettings
	
	if randi() % 2:
		coverDesign.get_node("Top Line").hide()
		coverDesign.get_node("Bottom Line").hide()
	
	if randi() % 2:
		coverDesign.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	coverVP.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	await RenderingServer.frame_post_draw
	
	coverDecal.set_texture(Decal.TEXTURE_ALBEDO, coverVP.get_texture())
	coverDecal.size.x = dimensions.z
	coverDecal.size.z = dimensions.y
	coverDecal.position.x = dimensions.x / 2
	coverVP.render_target_update_mode = SubViewport.UPDATE_DISABLED


func animate_show(time: float) -> void:
	position.y += OFFSCREEN_Y_OFFSET
	show()
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "position:y", position.y - OFFSCREEN_Y_OFFSET, time)


func tilt(reverse: bool) -> void:
	if picked_up || placed || !game.box_ready:
		return
	
	if tween:
		if tween.is_running():
			await tween.finished
		
		tween.kill()
	
	var rot_to = 0.0 if reverse else TILT_ANGLE
	var move_to = initial_position.z + dimensions.z / 2 + (0.0 if reverse else TILT_OFFSET)
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_parallel(true)
	tween.tween_property(pivot_helper, "rotation:x", rot_to, TILT_TIME)
	tween.tween_property(pivot_helper, "global_position:z", move_to, TILT_TIME)


func rotate_vector3(input: Vector3, rot: Vector3) -> Vector3:
	return input.rotated(
		Vector3.BACK, rot.z
	).rotated(
		Vector3.RIGHT, rot.x
	).rotated(
		Vector3.UP, rot.y
	)


func get_rotated_dimensions() -> Vector3:
	return rotate_vector3(dimensions, rotation).abs()


func set_picked_up(state: bool, placing: bool = false) -> void:
	picked_up = state
	game.placing = state
	game.book_ray.enabled = state
	can_place = false
	
	if tween:
		tween.kill()
	
	pivot_helper.rotation.x = 0
	
	if picked_up:
		collision_layer = 0
		game.camera.switch_to_box()
		rotation = Vector3.ZERO
		target_quaternion = Quaternion.IDENTITY
		set_shapecast()
	else:
		collision_layer = 1
		
		placed = placing
		var all_placed = placed
		if placed:

			for book in shelf.books:
				if book.placed:
					book.freeze = false
			
			await sleeping_state_changed
			
			for book in shelf.books:
				if book.placed:
					book.freeze = true
				else:
					all_placed = false
		
		if all_placed:
			game.complete_box()
		else:
			game.camera.switch_to_idle()


func set_shapecast() -> void:
	var rotated_dimensions = get_rotated_dimensions()
	game.book_bounds_limit = rotated_dimensions / 2
	game.book_bounds_limit.y = 0
	game.book_ray.shape = BoxShape3D.new()
	game.book_ray.shape.size = rotated_dimensions


func set_invalid(state: bool) -> void:
	invalid = state
	if invalid:
		mesh.material_override = INVALID_MATERIAL
	else:
		mesh.material_override = null


func pick_up(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if !game.placing && game.box_ready && !picked_up && event.is_action_pressed("pick_up"):
		set_picked_up(true)
		set_invalid(false)


func cancel_placement() -> void:
	if !picked_up:
		return
	
	set_picked_up(false)
	set_invalid(false)
	global_position = initial_position
	rotation = Vector3.ZERO
	target_quaternion = Quaternion.IDENTITY


func rotate_by(axis: Vector3, angle: float) -> void:
	if !picked_up:
		return
	
	quaternion = target_quaternion
	target_quaternion = basis.rotated(axis, angle).get_rotation_quaternion()
	
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "quaternion", target_quaternion, ROTATION_TIME)
	
	await tween.finished
	
	set_shapecast()


func _process(_delta) -> void:
	if !picked_up:
		return
		
	global_position = game.book_ray.global_position + game.book_ray.target_position * game.book_ray.get_closest_collision_safe_fraction()
	set_invalid(global_position.y > game.y_limit - get_rotated_dimensions().y / 2)
	
	if Input.is_action_just_pressed("cancel"):
		cancel_placement()
	
	if Input.is_action_just_pressed("place") && can_place && !invalid && game.box_ready && (!tween || !tween.is_running()):
		set_picked_up(false, true)
		set_invalid(false)
	
	if Input.is_action_just_pressed("rotate_right"):
		rotate_by(Vector3.UP, -PI / 2)
	if Input.is_action_just_pressed("rotate_left"):
		rotate_by(Vector3.UP, PI / 2)
	if Input.is_action_just_pressed("rotate_up"):
		rotate_by(Vector3.RIGHT, -PI / 2)
	if Input.is_action_just_pressed("rotate_down"):
		rotate_by(Vector3.RIGHT, PI / 2)
	
	can_place = true
