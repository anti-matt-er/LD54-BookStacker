extends MeshInstance3D


const BOOK_PREFAB := preload("res://assets/prefabs/book.tscn")
const MARGIN := 0.002
const DISTANCE_FROM_WALL := 0.02
const BOOK_PLACE_TRANSITION := 0.25
const BOOK_PLACE_DELAY := 0.025

@onready var length: float = mesh.size.x
@onready var remaining_length := length

var books: Array[Book] = []

signal stacked


func reset() -> void:
	remaining_length = length
	for book in books:
		book.pivot_helper.remove_child(book)
		book.queue_free()
	
	books = []


func stack_until_full() -> void:
	while remaining_length > Book.MAX_DIMENSIONS.x + MARGIN:
		stack_new_book()
	
	for book in books:
		book.position.x += remaining_length / 2
		book.initial_position = book.global_position
		book.pivot_helper.position = book.initial_position + Vector3(
			0, -book.dimensions.y / 2, book.dimensions.z / 2
		)
	
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
		(length + book.dimensions.x - 2 * remaining_length + MARGIN) / 2,
		(book.dimensions.y + mesh.size.y) / 2,
		-mesh.size.z / 2 + book.dimensions.z / 2 + DISTANCE_FROM_WALL 
	)
	remaining_length -= book.dimensions.x + MARGIN
