extends Node3D

const BOX_SIZE := 0.4 - 0.00001
const MAX_RAY_POS := Vector3(BOX_SIZE, 0, BOX_SIZE) / 2
const CAMERA_RAY_LENGTH := 10.0

@onready var camera := $Camera
@onready var place_ray := $PlaceCast
@onready var book_ray := $BookRay
@onready var ray_origin := Vector3(
	$Scenery/box.global_position.x,
	camera.box_angle.global_position.y,
	$Scenery/box.global_position.z
)

var placing := false
var book_bounds_limit := Vector3.ZERO


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
