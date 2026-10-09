function kick_in_grid_bounds(_kx, _ky = 0) {
	return (bbox_left   + _kx >= board_owner.grid_start_x) &&
	       (bbox_right  + _kx <= board_owner.grid_start_x + board_owner.grid_width * CELL_SIZE) &&
	       (bbox_bottom + _ky <= board_owner.grid_bottom_y);
}

function srs_plus_wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
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
	
	// I2 Domino Wall Kick Data
	static _kicks_i2 = {
		"0->1": [ [0, 0], [ 0,  1], [-1,  0], [-1,  1] ],
		"1->2": [ [0, 0], [ 1,  0], [ 0,  1], [ 1,  0] ],
		"2->3": [ [0, 0], [ 0, -1], [ 1,  0], [ 1,  1] ],
		"3->0": [ [0, 0], [-1,  0], [ 0, -1], [-1, -2] ],
		"0->3": [ [0, 0], [ 1,  0], [ 0,  1], [ 1,  2] ],
		"1->0": [ [0, 0], [ 0, -1], [ 1,  0], [ 1, -1] ],
		"2->1": [ [0, 0], [-1,  0], [ 0, -1], [-1,  0] ],
		"3->2": [ [0, 0], [ 0,  1], [-1,  0], [-1, -1] ]
	};
	
	var _table = _kicks_jlstz;
	if (_shape_name == "I") {
		_table = _kicks_i;
	} else if (_shape_name == "I2") {
		_table = _kicks_i2;
	}
	var _kicks = struct_get(_table, _key);
	
	if (is_undefined(_kicks)) {
		_kicks = [ [0, 0] ];
	}
	
	for (var _k = 0; _k < array_length(_kicks); _k++) {
		var _kx =  _kicks[_k][0] * CELL_SIZE;
		var _ky = -_kicks[_k][1] * CELL_SIZE;
		
		if (!place_meeting(x + _kx, y + _ky, obj_border) && kick_in_grid_bounds(_kx, _ky)) {
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
		
		if (!place_meeting(x + _kx, y + _ky, obj_border) && kick_in_grid_bounds(_kx, _ky)) {
			return [_kx, _ky];
		}
	}
	
	return undefined;
}

function zig_zag_wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
   var _diff = (_new_orientation - _old_orientation + NUM_ORIENTATIONS) % NUM_ORIENTATIONS;
   var _kicks_ccw = [
      [ 0,  0], [ 0,  1], [ 1,  0], [ 2,  0], [ 1,  1], 
      [ 0,  2], [ 1,  2], [ 2,  1], [ 2,  2], [-1,  0],
      [-2,  0], [-1,  1], [-1,  2], [ 2, -1], [-2,  2],
      [-2,  1], [-2,  2], [-1,  1], [-1,  2], [ 0,  1],
      [ 0,  2], [ 1,  1], [ 1,  2], [ 2,  1], [ 2,  2]
   ];

   var _kicks_cw = [
      [ 0,  0], [ 0,  1], [-1,  0], [-2,  0], [-1,  1],
      [ 0,  2], [-1,  2], [-2,  1], [-2,  2], [ 1,  0],
      [ 2,  0], [ 1,  1], [ 1,  2], [-2, -1], [ 2,  2],
      [ 2,  1], [ 2,  2], [ 1,  1], [ 1,  2], [ 0,  1],
      [ 0,  2], [-1,  1], [-1,  2], [-2,  1], [-2,  2]
   ];

   
   var _kicks;
	
   if (_diff == ROTATION_CCW) {
		_kicks = _kicks_ccw;
	} else {
		_kicks = _kicks_cw;
	}
   
   for (var _k = 0; _k < array_length(_kicks); _k++) {
		var _kx = _kicks[_k][0] * CELL_SIZE;
		var _ky = _kicks[_k][1] * CELL_SIZE;
		
		if (!place_meeting(x + _kx, y + _ky, obj_border) && kick_in_grid_bounds(_kx, _ky)) {
			return [_kx, _ky];
		}
	}
	
	return undefined;
}

function wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
	return zig_zag_wall_kick(_shape_name, _old_orientation, _new_orientation);
}
