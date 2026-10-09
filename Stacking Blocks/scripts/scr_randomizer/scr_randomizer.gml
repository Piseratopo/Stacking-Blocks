function randomizer_all_random() {
	var _keys = struct_get_names(global.shape_properties);
	return _keys[irandom(array_length(_keys) - 1)];
}

function randomizer_7_bag() {
	if (array_length(global.randomizer_bag) == 0) {
		var _keys = ["I", "J", "L", "O", "S", "T", "Z"];
		array_shuffle_ext(_keys);
	
		global.randomizer_bag = _keys;
	}
	
	return array_pop(global.randomizer_bag);
}

function randomizer_custom() {
	var _keys = ["I2", "I", "O"];
	return _keys[irandom(array_length(_keys) - 1)];
}

function get_random_shape() {
	return randomizer_all_random();
}