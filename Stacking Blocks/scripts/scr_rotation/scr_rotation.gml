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
		
		if (!place_meeting(x + _kx, y + _ky, obj_border)) {
			return [_kx, _ky];
		}
	}
	
	return undefined;
}

function wall_kick(_shape_name = shape_name, _old_orientation = orientation, _new_orientation = 0) {
	return simple_wall_kick(_shape_name, _old_orientation, _new_orientation);
}
