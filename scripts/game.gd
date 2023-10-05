extends Node3D

const BOX_SIZE := 0.4 - 0.00001
const MAX_RAY_POS := Vector3(BOX_SIZE, 0, BOX_SIZE) / 2
const CAMERA_RAY_LENGTH := 10.0

@onready var camera := $Camera
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

var placing := false
var book_bounds_limit := Vector3.ZERO


func _ready() -> void:
	box_limit.hide()


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
