if (is_locked) exit; // Dead block-check
if (!board_owner.is_local) exit; // Remote player block


// Hard drop

if (get_key_hard_drop_pressed()) {
	hard_drop();
	exit;
}

// Soft drop

if (get_key_soft_drop()) {
	fall_delay = fall_fast;
	if (alarm[0] > fall_delay) {
		fall_delay = fall_fast;
		alarm[0] = fall_fast;
	}
} else {
	fall_delay = fall_normal;
}

// Horizontal movement

var _moved_horizontal = false;


if (get_key_move_left_pressed() && !get_key_move_right_pressed()) {
	move_dir = -1;
	if (is_touching_left()) {
		x -= CELL_SIZE;
		_moved_horizontal = true;
	}
	alarm[1] = move_DAS;
} else if (get_key_move_right_pressed() && !get_key_move_left_pressed()) {
	move_dir = 1;
	if (is_touching_right()) {
		x += CELL_SIZE;
		_moved_horizontal = true;
	}
	alarm[1] = move_DAS;
} else if (move_dir == -1) {
	if (!get_key_move_left()) {
		if (get_key_move_right()) {
			move_dir = 1;
			alarm[1] = move_DAS;
		} else {
			move_dir = 0;
			alarm[1] = -1;
		}
	}
} else if (move_dir == 1) {
	if (!get_key_move_right()) {
		if (get_key_move_left()) {
			move_dir = -1;
			alarm[1] = move_DAS;
		} else {
			move_dir = 0;
			alarm[1] = -1;
		}
	}
} else if (move_dir == 0) {
	if (get_key_move_left() && !get_key_move_right()) {
		move_dir = -1;
		if (is_touching_left()) {
			x -= CELL_SIZE;
			_moved_horizontal = true;
		}
		alarm[1] = move_DAS;
	} else if (get_key_move_right() && !get_key_move_left()) {
		move_dir = 1;
		if (is_touching_right()) {
			x += CELL_SIZE;
			_moved_horizontal = true;
		}
		alarm[1] = move_DAS;
	}
}

// Rotation

var _rotated = false;
if (get_key_rotate_cw_pressed()) {
	_rotated = rotate(ROTATION_CW);
} else if (get_key_rotate_ccw_pressed()) {
	_rotated = rotate(ROTATION_CCW);
} else if (get_key_rotate_180_pressed()) {
	_rotated = rotate(ROTATION_180);
}

if (_rotated) {
	rotation_count += 1;
	if (rotation_count >= rotation_limit) {
		hard_drop();
		exit;
	}
}

// Lock timer 

if (y > lowest_y) {
	lowest_y = y;
	lock_resets = 0;
}

var _grounded = place_meeting(x, y + CELL_SIZE, obj_border);
if (_grounded) {
	if ((_moved_horizontal || _rotated) && lock_resets < lock_delay_reset) {
		alarm[2] = lock_delay;
		lock_resets += 1;
		show_debug_message(lock_resets);
	}
} else {
	// Airborne piece: refresh lock delay without resetting lock_resets
	alarm[2] = lock_delay;
}

