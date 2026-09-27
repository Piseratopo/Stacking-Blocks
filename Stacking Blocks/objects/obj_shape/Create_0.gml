event_inherited();

orientation = 0;

if (sprite_xoffset % CELL_SIZE != 0) {
	x = round((x - (CELL_SIZE / 2) - GRID_START_X) / CELL_SIZE) * CELL_SIZE + GRID_START_X + (CELL_SIZE / 2);
}
if (sprite_yoffset % CELL_SIZE != 0) {
	y = round((y - (CELL_SIZE / 2)) / CELL_SIZE) * CELL_SIZE + (CELL_SIZE / 2);
}

alarm[2] = lock_delay;

rotate = function(_step = ROTATION_CW) {
	var _old_orientation = orientation;
	var _old_angle = image_angle;
	var _new_orientation = (orientation + _step) % NUM_ORIENTATIONS;
	
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

lock_shape = function() {
	var _lock_spr = lock_spr;
	var _half = CELL_SIZE / 2;
	
	var _rows = (bbox_bottom - bbox_top) div CELL_SIZE;
	var _cols = (bbox_right  - bbox_left) div CELL_SIZE;
	
	for (var _r = 0; _r < _rows; _r++) {
		for (var _c = 0; _c < _cols; _c++) {
			// Sample the CENTER of the cell — safe for pixel-perfect masks
			var _cx = bbox_left + _c * CELL_SIZE + _half;
			var _cy = bbox_top  + _r * CELL_SIZE + _half;
			
			if (position_meeting(_cx, _cy, self)) {
				// Block sits at the grid-aligned TOP-LEFT of the cell
				var _bx = bbox_left + _c * CELL_SIZE;
				var _by = bbox_top  + _r * CELL_SIZE;
				
				instance_create_layer(_bx, _by, "Blocks", obj_block, {
					is_locked:    true,
					sprite_index: _lock_spr,
					image_index:  0,
					image_speed:  0,
               block_name: shape_name 
				});
				
				obj_controller.grid_set(
					grid_x_to_col(_bx),
					grid_y_to_row(_by),
					shape_name
				);
			}
		}
	}
	
	obj_controller.clear_lines();
	obj_controller.finished_locking_shape = true;
	instance_destroy();
};

hard_drop = function() {
	// Move down one cell at a time until grounded
	while (!place_meeting(x, y + CELL_SIZE, obj_border)) {
		y += CELL_SIZE;
	}
	// Cancel fall / lock timers and lock immediately
	alarm[0] = -1;
	alarm[2] = -1;
	lock_shape();
};
