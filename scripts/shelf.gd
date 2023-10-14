extends Node3D


const BOOK_PREFAB := preload("res://assets/prefabs/book.tscn")
const LENGTH := 1.0
const DEPTH := 0.25
const THICKNESS := 0.015
const MARGIN := 0.002
const DISTANCE_FROM_WALL := 0.02
const BOOK_PLACE_TRANSITION := 0.25
const BOOK_PLACE_DELAY := 0.025

@export var bookstopper_prefab: PackedScene

@onready var remaining_length := LENGTH

var books: Array[Book] = []
var bookstopper_l: Node3D
var bookstopper_r: Node3D
var bookstopper_dimensions: Vector3

signal stacked


func _ready() -> void:
	spawn_bookstoppers()


func reset() -> void:
	bookstopper_l.hide()
	bookstopper_r.hide()
	
	remaining_length = LENGTH
	for book in books:
		book.pivot_helper.remove_child(book)
		remove_child(book.pivot_helper)
		book.queue_free()
	
	books = []


func stack_until_full() -> void:
	while remaining_length > Book.MAX_DIMENSIONS.x * Book.MAX_RANGE.x + MARGIN:
		stack_new_book()
	
	for book in books:
		book.position.x += remaining_length / 2
		book.initial_position = book.global_position
		book.pivot_helper = Node3D.new()
		add_child(book.pivot_helper)
		book.pivot_helper.global_position = book.initial_position + Vector3(
			0, -book.dimensions.y / 2, book.dimensions.z / 2
		)
		book.reparent(book.pivot_helper)
	
	for book in books:
		book.animate_show(BOOK_PLACE_TRANSITION)
		await get_tree().create_timer(BOOK_PLACE_DELAY).timeout
	
	position_bookstoppers()
	
	stacked.emit()


func stack_new_book() -> void:
	var book = BOOK_PREFAB.instantiate()
	
	books.append(book)
	add_child(book)
	book.shelf = self
	
	book.setup()
	book.generate()
	book.global_position = Vector3(
		LENGTH / 2 - remaining_length + book.dimensions.x / 2,
		book.dimensions.y / 2 + THICKNESS / 2 + global_position.y,
		-DEPTH / 2 + book.dimensions.z / 2 + DISTANCE_FROM_WALL 
	)
	remaining_length -= book.dimensions.x + MARGIN


func spawn_bookstoppers() -> void:
	bookstopper_l = bookstopper_prefab.instantiate()
	bookstopper_r = bookstopper_prefab.instantiate()
	
	add_child(bookstopper_l)
	add_child(bookstopper_r)
	
	bookstopper_dimensions = bookstopper_l.get_child(0, true).get_aabb().size
	
	bookstopper_l.global_position.y = global_position.y + (bookstopper_dimensions.y + THICKNESS) / 2
	bookstopper_r.global_position.y = global_position.y + (bookstopper_dimensions.y + THICKNESS) / 2
	
	bookstopper_l.rotation.y = PI
	
	bookstopper_l.hide()
	bookstopper_r.hide()


func position_bookstoppers() -> void:
	var distance = (LENGTH - remaining_length + bookstopper_dimensions.x) / 2
	
	bookstopper_l.global_position.x = global_position.x - distance
	bookstopper_r.global_position.x = global_position.x + distance
	
	bookstopper_l.show()
	bookstopper_r.show()
