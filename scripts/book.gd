extends Node3D


const MAX_DIMENSIONS := Vector3(0.05, 0.315, 0.222)
const MIN_DIMENSIONS := Vector3(0.01, 0.105, 0.074)
const MIN_RANGE := Vector3(-0.5, -1, -1)
const MAX_RANGE := Vector3(1.5, 1, 1)
const MAX_MARGIN := 32
const DPI := 4000
const COLOR_SATURATION_RANGE := Vector2(0.05, 0.9)
const COLOR_VALUE_RANGE := Vector2(0.2, 0.5)


@onready var mesh := $Book
@onready var spineVP := $SpineVP
@onready var spineDesign := $SpineVP/Spine
@onready var spineDecal := $SpineDecal

var title := ""
var size: Vector3
var dimensions: Vector3


func _ready() -> void:
	generate()


func generate() -> void:
	randomize()
	
	title = TitleGenerator.generate_title()
	size = Vector3(
		randf_range(MIN_RANGE.x, MAX_RANGE.x),
		randf_range(MIN_RANGE.y, MAX_RANGE.y),
		randf_range(MIN_RANGE.z, MAX_RANGE.z)
	)
	dimensions = Vector3(
		remap(size.x, MIN_RANGE.x, MAX_RANGE.x, MIN_DIMENSIONS.x, MAX_DIMENSIONS.x),
		remap(size.y, MIN_RANGE.y, MAX_RANGE.y, MIN_DIMENSIONS.y, MAX_DIMENSIONS.y),
		remap(size.z, MIN_RANGE.z, MAX_RANGE.z, MIN_DIMENSIONS.z, MAX_DIMENSIONS.z)
	)
	
	modify_mesh()
	modify_spine()


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
	mesh.get_surface_override_material(0).albedo_color = Color.from_hsv(
		randf(),
		randf_range(COLOR_SATURATION_RANGE.x, COLOR_SATURATION_RANGE.y),
		randf_range(COLOR_VALUE_RANGE.x, COLOR_VALUE_RANGE.y)
	)


func modify_spine() -> void:
	var res = Vector2i(dimensions.y * DPI, dimensions.x * DPI)
	spineVP.size = res
	spineVP.size_2d_override = res
	spineDesign.size = res
	
	spineDesign.get_node("Title").text = title
	
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
	
	await RenderingServer.frame_post_draw
	
	spineDecal.set_texture(Decal.TEXTURE_ALBEDO, spineVP.get_texture())
	spineDecal.size.x = dimensions.y
	spineDecal.size.z = dimensions.x
	spineDecal.position.z = dimensions.z / 2.0
