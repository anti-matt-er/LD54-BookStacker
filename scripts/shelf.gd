extends Node3D


const BOOK_PREFAB := preload("res://assets/prefabs/book.tscn")
const LENGTH := 1.0
const DEPTH := 0.25
const THICKNESS := 0.015
const MARGIN := 0.002
const DISTANCE_FROM_WALL := 0.02
const BOOK_PLACE_TRANSITION := 0.25
const BOOK_PLACE_DELAY := 0.025

@onready var remaining_length := LENGTH

var books: Array[Book] = []

signal stacked


func reset() -> void:
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
