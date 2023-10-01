extends MeshInstance3D


const BOOK_PREFAB := preload("res://assets/prefabs/book.tscn")

@onready var length: float = mesh.size.x
@onready var remaining_length := length

var books: Array[Book]


func _ready() -> void:
	reset()
	stack_until_full()


func reset() -> void:
	for book in books:
		remove_child(book)
		book.queue_free()
	
	books = []


func stack_until_full() -> void:
	while remaining_length > Book.MAX_DIMENSIONS.x:
		stack_new_book()
	
	for book in books:
		book.position.x += remaining_length / 2


func stack_new_book() -> void:
	var book = BOOK_PREFAB.instantiate()
	
	books.append(book)
	add_child(book)
	
	book.setup()
	book.generate()
	book.position = Vector3(
		(length + book.dimensions.x - 2 * remaining_length) / 2,
		(book.dimensions.y + mesh.size.y) / 2,
		0
	)
	remaining_length -= book.dimensions.x
