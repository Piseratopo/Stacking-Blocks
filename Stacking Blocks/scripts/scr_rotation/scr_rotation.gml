function kick_in_grid_bounds(_kx) {
	return (bbox_left  + _kx >= GRID_START_X) &&
	       (bbox_right + _kx <= GRID_START_X + GRID_WIDTH * CELL_SIZE);
}

function srs_plus_wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
	if (_shape_name == "O") {
		if (!place_meeting(x, y, obj_border)) {
			return [0, 0];
		}
		return undefined;
	}
	
	var _key = string(_old_orientation) + "->" + string(_new_orientation);
	
	// JLSTZ Tetromino Wall Kick Data
	static _kicks_jlstz = {
		"0->1": [ [0, 0], [-1,  0], [-1,  1], [ 0, -2], [-1, -2] ],
		"1->0": [ [0, 0], [ 1,  0], [ 1, -1], [ 0,  2], [ 1,  2] ],
		"1->2": [ [0, 0], [ 1,  0], [ 1, -1], [ 0,  2], [ 1,  2] ],
		"2->1": [ [0, 0], [-1,  0], [-1,  1], [ 0, -2], [-1, -2] ],
		"2->3": [ [0, 0], [ 1,  0], [ 1,  1], [ 0, -2], [ 1, -2] ],
		"3->2": [ [0, 0], [-1,  0], [-1, -1], [ 0,  2], [-1,  2] ],
		"3->0": [ [0, 0], [-1,  0], [-1, -1], [ 0,  2], [-1,  2] ],
		"0->3": [ [0, 0], [ 1,  0], [ 1,  1], [ 0, -2], [ 1, -2] ],
		"0->2": [ [0, 0], [ 0,  1], [ 1,  1], [-1,  1], [ 1,  0], [-1, 0] ],
		"2->0": [ [0, 0], [ 0, -1], [-1, -1], [ 1, -1], [-1,  0], [ 1, 0] ],
		"1->3": [ [0, 0], [ 1,  0], [ 1,  2], [ 1,  1], [ 0,  2], [ 0, 1] ],
		"3->1": [ [0, 0], [-1,  0], [-1,  2], [-1,  1], [ 0,  2], [ 0, 1] ]
	};
	
	// I Tetromino Wall Kick Data
	static _kicks_i = {
		"0->1": [ [0, 0], [-2,  0], [ 1,  0], [ 1,  2], [-2, -1] ],
		"1->0": [ [0, 0], [ 2,  0], [-1,  0], [ 2,  1], [-1, -2] ],
		"1->2": [ [0, 0], [-1,  0], [ 2,  0], [-1,  2], [ 2, -1] ],
		"2->1": [ [0, 0], [-2,  0], [ 1,  0], [-2,  1], [ 1, -1] ],
		"2->3": [ [0, 0], [ 2,  0], [-1,  0], [ 2,  1], [-1, -1] ],
		"3->2": [ [0, 0], [ 1,  0], [-2,  0], [ 1,  2], [-2, -1] ],
		"3->0": [ [0, 0], [-2,  0], [ 1,  0], [-2,  1], [ 1, -2] ],
		"0->3": [ [0, 0], [ 2,  0], [-1,  0], [-1,  2], [ 2, -1] ]
	};
	
	var _table = (_shape_name == "I") ? _kicks_i : _kicks_jlstz;
	var _kicks = struct_get(_table, _key);
	
	if (is_undefined(_kicks)) {
		_kicks = [ [0, 0] ];
	}
	
	for (var _k = 0; _k < array_length(_kicks); _k++) {
		var _kx =  _kicks[_k][0] * CELL_SIZE;
		var _ky = -_kicks[_k][1] * CELL_SIZE;
		
		if (!place_meeting(x + _kx, y + _ky, obj_border) && kick_in_grid_bounds(_kx)) {
			return [_kx, _ky];
		}
	}
	
	return undefined;
}

function simple_wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
	var _diff = (_new_orientation - _old_orientation + NUM_ORIENTATIONS) % NUM_ORIENTATIONS;
	
	var _kicks;
	if (_diff == ROTATION_CCW) {
		_kicks = [
			[0, 0],
			[1, 0],
			[-1, 0]
		];
	} else {
		_kicks = [
			[0, 0],
			[-1, 0],
			[1, 0]
		];
	}
	
	for (var _k = 0; _k < array_length(_kicks); _k++) {
		var _kx = _kicks[_k][0] * CELL_SIZE;
		var _ky = _kicks[_k][1] * CELL_SIZE;
		
		if (!place_meeting(x + _kx, y + _ky, obj_border) && kick_in_grid_bounds(_kx)) {
			return [_kx, _ky];
		}
	}
	
	return undefined;
}

function wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
	return srs_plus_wall_kick(_shape_name, _old_orientation, _new_orientation);
}
