event_inherited();

orientation = 0;

if (sprite_xoffset % CELL_SIZE != 0) {
	x = round((x - (CELL_SIZE / 2) - GRID_START_X) / CELL_SIZE) * CELL_SIZE + GRID_START_X + (CELL_SIZE / 2);
}
if (sprite_yoffset % CELL_SIZE != 0) {
	y = round((y - (CELL_SIZE / 2)) / CELL_SIZE) * CELL_SIZE + (CELL_SIZE / 2);
}

alarm[2] = lock_delay;

rotate = function(_type = ROTATION_CW) {
	if (is_locked) return false;
	if (num_orientations <= 1) return false;
	
	var _step = 1;
	if (_type == ROTATION_CW) _step = 1;
	else if (_type == ROTATION_CCW) _step = -1;
	else if (_type == ROTATION_180) _step = 2;
	else _step = _type;
	
	var _old_orientation = orientation;
	var _old_angle = image_angle;
	var _new_orientation = (orientation + _step) % num_orientations;
	if (_new_orientation < 0) _new_orientation += num_orientations;
	
	var _new_angle = (360 - _new_orientation * 90) % 360;
	
	// Wall kick test offsets: (dx, dy)
	var _kicks = [
		[0, 0],
		[-CELL_SIZE, 0],
		[CELL_SIZE, 0],
		[0, -CELL_SIZE],
		[-CELL_SIZE, -CELL_SIZE],
		[CELL_SIZE, -CELL_SIZE],
		[-2 * CELL_SIZE, 0],
		[2 * CELL_SIZE, 0]
	];
	
	// Temporarily set new angle to check collision with rotated precise mask
	image_angle = _new_angle;
	
	var _success = false;
	var _chosen_dx = 0;
	var _chosen_dy = 0;
	
	for (var _k = 0; _k < array_length(_kicks); _k++) {
		var _kx = _kicks[_k][0];
		var _ky = _kicks[_k][1];
		
		if (!place_meeting(x + _kx, y + _ky, obj_border)) {
			_success = true;
			_chosen_dx = _kx;
			_chosen_dy = _ky;
			break;
		}
	}
	
	if (_success) {
		x += _chosen_dx;
		y += _chosen_dy;
		orientation = _new_orientation;
		image_angle = _new_angle;
		return true;
	} else {
		// Restore previous angle on failure
		image_angle = _old_angle;
		return false;
	}
};

//rotate_cw = function() {
//	return rotate(ROTATION_CW);
//};

//rotate_ccw = function() {
//	return rotate(ROTATION_CCW);
//};

//rotate_180 = function() {
//	return rotate(ROTATION_180);
//};

lock_shape = function() {
	if (array_length(lock_id) > 0) {
		var _current_matrix = lock_id[orientation];
		var _top_left_x = x + offsets[orientation][0];
		var _top_left_y = y + offsets[orientation][1];
		
		var _rows = array_length(_current_matrix);
		for (var _r = 0; _r < _rows; _r++) {
			var _cols = array_length(_current_matrix[_r]);
			for (var _c = 0; _c < _cols; _c++) {
				var _sub_img = _current_matrix[_r][_c];
				if (_sub_img >= 0) {
					var _bx = _top_left_x + _c * CELL_SIZE;
					var _by = _top_left_y + _r * CELL_SIZE;
					var _b = instance_create_layer(_bx, _by, "Blocks", obj_block);
					_b.is_locked = true;
					_b.alarm[0] = -1;
					_b.alarm[1] = -1;
					_b.image_index = _sub_img;
					_b.image_speed = 0;
					
					obj_controller.grid_set(
						grid_x_to_col(_bx), 
						grid_y_to_row(_by), 
						_sub_img
					);
				}
			}
		}
	}
	
	obj_controller.clear_lines();
	instance_destroy();
};
