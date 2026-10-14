if (instance_exists(obj_player_board)) {
	if (instance_number(obj_player_board) > 1) {
		var _min_x = 999999;
		var _max_x = -999999;
		with (obj_player_board) {
			_min_x = min(_min_x, grid_start_x);
			_max_x = max(_max_x, grid_start_x + grid_width * CELL_SIZE);
		}
		target_x = (_min_x + _max_x) / 2 - (camera_width / 2);
	} else {
		var _board = instance_find(obj_player_board, 0);
		target_x = _board.grid_start_x + (_board.grid_width * CELL_SIZE) / 2 - (camera_width / 2);
	}
}

camera_x = lerp(camera_x, target_x, 0.08);
camera_y = lerp(camera_y, target_y, 0.08);
camera_set_view_pos(camera, camera_x, camera_y);
