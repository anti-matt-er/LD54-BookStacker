extends Node


const WORDLIST_PATH := "res://assets/misc/wordlists/"
const WORDLIST_SOURCES := {
	"nouns": [
		"mostly-nouns",
		"mostly-nouns-ment",
		"mostly-plural-nouns"
	],
	"adjectives": [
		"mostly-adjectives",
		"ly-adverbs",
		"mostly-adverbs"
	]
}
const NOUN_PATTERNS := {
	"{N}": 16,
	"the {N}": 19,
	"{A} {N}": 6,
	"the {A} {N}": 9
}
const TITLE_PATTERNS := {
	"{P}": 5,
	"{P1} and {P2}": 2,
	"{P1} of {P2}": 3,
	"{P1} in {P2}": 1,
	"{P1} from {P2}": 2,
	"{P1}: {P2}": 1
}

var nouns: Array[String] = []
var adjectives: Array[String] = []
var weighted_noun_patterns := {}
var weighted_title_patterns := {}


func _ready() -> void:
	for noun_file in WORDLIST_SOURCES.nouns:
		nouns.append_array(wordlist_to_array(noun_file))
	for adjective_file in WORDLIST_SOURCES.adjectives:
		adjectives.append_array(wordlist_to_array(adjective_file))
	
	weighted_noun_patterns = calculate_weighted_dict(NOUN_PATTERNS)
	weighted_title_patterns = calculate_weighted_dict(TITLE_PATTERNS)
	
	randomize()


func wordlist_to_array(filename: String) -> Array[String]:
	var f = FileAccess.open(WORDLIST_PATH + filename + ".txt", FileAccess.READ)
	var array: Array[String] = []
	while not f.eof_reached():
		array.append(f.get_line().capitalize())
	f.close()
	return array


func calculate_weighted_dict(input: Dictionary) -> Dictionary:
	var sum = 0
	var output = {}
	
	for item in input:
		sum += input[item]
		
	for item in input:
		output[item] = input[item] / float(sum)
	
	return output


func pick_weighted_random(input: Dictionary) -> String:
	var rng = randf()
	var sum = 0.0
	
	for item in input:
		var weight = input[item]
		sum += weight
		if sum > rng:
			return item
		
	return input.keys()[0]


func generate_title_part() -> String:
	var pattern = pick_weighted_random(weighted_noun_patterns)
	var noun = nouns.pick_random()
	var adj1 = adjectives.pick_random()
	var adj2 = ""
	
	if "{A2}" in pattern:
		adj2 = adjectives.pick_random()
	
	return pattern.format({
		"N": noun,
		"A": adj1,
		"A1": adj1,
		"A2": adj2
	})


func generate_title() -> String:
	var pattern = pick_weighted_random(weighted_title_patterns)
	var part1 = generate_title_part()
	var part2 = ""
	
	if "{P2}" in pattern:
		part2 = generate_title_part()
	
	var title = pattern.format({
		"P": part1,
		"P1": part1,
		"P2": part2
	})
	
	title[0] = title[0].to_upper()
	
	return title
