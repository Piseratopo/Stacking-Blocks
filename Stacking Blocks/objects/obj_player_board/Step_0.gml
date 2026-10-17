if (!is_alive) exit;

if (instance_exists(obj_network_manager)) {
	infinite_mode = false;
	if (obj_network_manager.room_state == "COUNTDOWN" || obj_network_manager.room_state == "GAME_OVER") {
		exit;
	}
} else {
	infinite_mode = true;
}

var _owner = id;

if (finished_locking_shape) {
	apply_garbage();

	with (obj_block) {
		if (board_owner == _owner && is_locked) {
			set_block_lock_sprite();
		}
	}

	if (!infinite_mode) {
		check_ko();
	}

	finished_locking_shape = false;

	// Spawn next piece right after lock processing so next_shape_name advances
	if (is_alive && is_local && !instance_exists(current_shape)) {
		var _chosen_key = next_shape_name;
		next_shape_name = get_random_shape();
		spawn_shape(_chosen_key);
		can_hold = true;
	}

	if (is_local && instance_exists(obj_network_manager)) {
		var _grid_snapshot = [];
		var _grid = play_grid;
		for (var _r = 0; _r < array_length(_grid); _r++) {
			for (var _c = 0; _c < array_length(_grid[_r]); _c++) {
				var _cell = _grid[_r][_c];
				if (_cell != GRID_EMPTY) {
					array_push(_grid_snapshot, { col: _c, row: _r, shape: _cell });
				}
			}
		}
		obj_network_manager.send_piece_locked(total_lines_cleared, _grid_snapshot, next_shape_name, hold_shape_name);
	}
}

if (is_alive && is_local) {
	// Handle hold piece
	if (instance_exists(current_shape) && can_hold && get_key_hold_pressed()) {
		can_hold = false;
		var _current_shape_name = current_shape.shape_name;
		instance_destroy(current_shape);
		current_shape = noone;

		if (hold_shape_name == "") {
			hold_shape_name = _current_shape_name;
			var _chosen_key = next_shape_name;
			next_shape_name = get_random_shape();
			spawn_shape(_chosen_key);
		} else {
			var _to_spawn = hold_shape_name;
			hold_shape_name = _current_shape_name;
			spawn_shape(_to_spawn);
		}
	} else if (!instance_exists(current_shape)) {
		// Spawn initial piece or piece after lock
		var _chosen_key = next_shape_name;
		next_shape_name = get_random_shape();
		spawn_shape(_chosen_key);
		can_hold = true;
	}
}
