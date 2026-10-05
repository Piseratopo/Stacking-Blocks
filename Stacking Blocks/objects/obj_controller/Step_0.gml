if (instance_exists(obj_shape) && can_hold && get_key_hold_pressed()) {
	can_hold = false;
	var _current_shape = obj_shape.shape_name;
	instance_destroy(obj_shape);
	
	if (hold_shape_name == "") {
		hold_shape_name = _current_shape;
		var _chosen_key = next_shape_name;
		next_shape_name = get_random_shape();
		spawn_shape(_chosen_key);
	} else {
		var _to_spawn = hold_shape_name;
		hold_shape_name = _current_shape;
		spawn_shape(_to_spawn);
	}
} else if (!instance_exists(obj_shape)) {
	var _chosen_key = next_shape_name;
	next_shape_name = get_random_shape();
	spawn_shape(_chosen_key);
	can_hold = true;
}

if (finished_locking_shape) {
	with (obj_block) {
		if (is_locked) {
			set_block_lock_sprite();
		}
	}
	finished_locking_shape = false;
	can_hold = true;
}