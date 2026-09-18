// Horizontal-movement timer

if (is_locked) exit;

if (move_dir == -1 && !get_key_move_left()) {
	move_dir = 0;
} else if (move_dir == 1 && !get_key_move_right()) {
	move_dir = 0;
}

if (move_dir != 0) {
	var _can_move = (move_dir == -1) ? is_touching_left() : is_touching_right();
	if (_can_move) {
		x += move_dir * CELL_SIZE;
		
		// Reset lock timer on horizontal move while grounded
		if (place_meeting(x, y + CELL_SIZE, obj_border) && lock_resets < lock_delay_reset) {
			lock_timer = lock_delay;
			lock_resets += 1;
		}
	}
	alarm[1] = move_ARR;
}