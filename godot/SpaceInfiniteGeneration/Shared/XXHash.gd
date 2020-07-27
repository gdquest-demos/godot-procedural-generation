# Generates a pseudo-random number from a seed and one or more integers.
# 
# GDScript adaptation of XXHash.
# Adapted from Rune Skovbo Johansen's C# code
# Original xxHash C code by Yann Collet

class_name XXHash
extends Reference

var hash_seed: int

const PRIME_1 := 2654435761
const PRIME_2 := 2246822519
const PRIME_3 := 3266489917
const PRIME_4 := 668265263
const PRIME_5 := 374761393


func get_hash(buffer: int) -> int:
	var hash_32 := hash_seed + PRIME_5
	hash_32 += 4
	hash_32 += buffer * PRIME_3
	hash_32 = _rotate_left(hash_32, 17) * PRIME_4
	hash_32 = (hash_32 ^ hash_32) >> 15
	hash_32 *= PRIME_2
	hash_32 = (hash_32 ^ hash_32) >> 13
	hash_32 *= PRIME_3
	hash_32 = (hash_32 ^ hash_32) >> 16

	return hash_32


func get_hash_array(buffer: PoolIntArray) -> int:
	var hash_32: int
	var index := 0
	var length := buffer.size()

	if length >= 16:
		var limit := length - 4
		var v1 := hash_seed + PRIME_1 + PRIME_2
		var v2 := hash_seed + PRIME_2
		var v3 := hash_seed + 0
		var v4 := hash_seed - PRIME_1

		while true:
			v1 = _calculate_sub_hash(v1, buffer[index])
			index += 1
			v2 = _calculate_sub_hash(v2, buffer[index])
			index += 1
			v3 = _calculate_sub_hash(v3, buffer[index])
			index += 1
			v4 = _calculate_sub_hash(v4, buffer[index])
			index += 1
			if index > limit:
				break

		hash_32 = (
			_rotate_left(v1, 1)
			+ _rotate_left(v2, 7)
			+ _rotate_left(v3, 12)
			+ _rotate_left(v4, 18)
		)
	else:
		hash_32 = hash_seed + PRIME_5

	hash_32 += length * 4

	while index <= length - 4:
		hash_32 += buffer[index] * PRIME_3
		hash_32 = _rotate_left(hash_32, 17) * PRIME_4
		index += 1

	hash_32 = (hash_32 ^ hash_32) >> 15
	hash_32 *= PRIME_2
	hash_32 = (hash_32 ^ hash_32) >> 13
	hash_32 *= PRIME_3
	hash_32 = (hash_32 ^ hash_32) >> 16

	return hash_32


func _calculate_sub_hash(value: int, read_value: int) -> int:
	value += read_value * PRIME_2
	value = _rotate_left(value, 13)
	value *= PRIME_1
	return value


func _rotate_left(value: int, count: int):
	return (value << count) | (value >> (32 - count))
