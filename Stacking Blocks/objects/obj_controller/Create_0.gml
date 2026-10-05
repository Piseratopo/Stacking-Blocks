randomise();

grid_width = GRID_WIDTH;
grid_height = GRID_HEIGHT;
grid_start_x = GRID_START_X;
grid_bottom_y = GRID_BOTTOM_Y;

play_grid = array_create(grid_height);
for (var _r = 0; _r < grid_height; _r++) {
	play_grid[_r] = array_create(grid_width, GRID_EMPTY);
}

total_lines_cleared = 0;

depth = -100;


get_spawn_y = function() {
	var _top_y = GRID_BOTTOM_Y - (GRID_HEIGHT + 1) * CELL_SIZE;
	with (obj_block) {
		if (is_locked && y - 5 * CELL_SIZE < _top_y) {
			_top_y = y - 5 * CELL_SIZE;
		}
	}

	return _top_y;
};

// Spawn helper
spawn_shape = function(_shape_name) {
	var _spawn_y = get_spawn_y();
	var _shape_props = global.shape_properties;
	var _inst = instance_create_layer(SHAPE_SPAWN_X, _spawn_y, "Blocks", obj_shape, {
		shape_name: _shape_name,
		shape_data: _shape_props[$ _shape_name],
		sprite_index: _shape_props[$ _shape_name].display_spr,
		lock_spr: _shape_props[$ _shape_name].lock_spr,
		orientation: 0,
		image_angle: 0,
		image_speed: 0,
	});
	
	with (obj_camera) {
		target_y = _spawn_y + 10 * CELL_SIZE - camera_height / 2;
	}
	return _inst;
};

next_shape_name = get_random_shape();

hold_shape_name = "";
can_hold = true;

var _right_border_x = GRID_START_X + (GRID_WIDTH + 1) * CELL_SIZE;
var _top_border_y = GRID_BOTTOM_Y - (GRID_HEIGHT + 1) * CELL_SIZE;

next_piece_frame_x = _right_border_x + sprite_get_xoffset(spr_next_piece_frame);
next_piece_frame_y = _top_border_y + sprite_get_yoffset(spr_next_piece_frame);

var _left_border_x = GRID_START_X - CELL_SIZE;
hold_piece_frame_x = _left_border_x - (sprite_get_width(spr_hold_frame) - sprite_get_xoffset(spr_hold_frame));
hold_piece_frame_y = _top_border_y + sprite_get_yoffset(spr_hold_frame);

grid_set = function(_col, _row, _shape_name) {
	if (_row < 0 || _col < 0) exit;
	
	while (array_length(play_grid) <= _row) {
		array_push(play_grid, array_create(max(grid_width, _col + 1), GRID_EMPTY));
	}
	
	if (_col >= array_length(play_grid[_row])) {
		var _old_len = array_length(play_grid[_row]);
		array_resize(play_grid[_row], _col + 1);
		for (var _i = _old_len; _i <= _col; _i++) {
			play_grid[_row][_i] = GRID_EMPTY;
		}
	}
	
	play_grid[_row][_col] = _shape_name;
};

grid_get = function(_col, _row) {
	if (_row < 0 || _row >= array_length(play_grid)) return GRID_EMPTY;
	if (_col < 0 || _col >= array_length(play_grid[_row])) return GRID_EMPTY;
	return play_grid[_row][_col];
};

is_row_full = function(_row) {
	if (_row < 0 || _row >= array_length(play_grid)) return false;
	var _row_arr = play_grid[_row];
	if (array_length(_row_arr) < grid_width) return false;
	
	for (var _c = 0; _c < grid_width; _c++) {
		if (_row_arr[_c] == GRID_EMPTY) {
			return false;
		}
	}
	return true;
};

clear_lines = function() {
	var _lines_cleared = 0;
	var _r = 0;
	
	while (_r < array_length(play_grid)) {
		if (is_row_full(_r)) {
			var _row_y = grid_row_to_y(_r);
			
			// 1. Destroy locked blocks in this row
			with (obj_block) {
				if (is_locked && y == _row_y) {
					instance_destroy();
				}
			}
			
			// 2. Shift all locked blocks above this row down by one cell
			with (obj_block) {
				if (is_locked && y < _row_y) {
					y += CELL_SIZE;
				}
			}
			
			// 3. Delete this row from the dynamic play_grid array
			array_delete(play_grid, _r, 1);
			
			_lines_cleared++;
		} else {
			_r++;
		}
	}
	
	total_lines_cleared += _lines_cleared;
	return _lines_cleared;
};

grid_clear_lines = clear_lines;
