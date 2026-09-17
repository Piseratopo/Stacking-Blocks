randomise();

grid_width = GRID_WIDTH;
grid_height = GRID_HEIGHT;
grid_start_x = GRID_START_X;
grid_bottom_y = GRID_BOTTOM_Y;

// Store the grid as a dynamic array containing arrays of length 10,
// stored from bottom to top. Index 0 represents the bottom-most row.
play_grid = array_create(grid_height);
for (var _r = 0; _r < grid_height; _r++) {
	play_grid[_r] = array_create(grid_width, GRID_EMPTY);
}

total_lines_cleared = 0;

grid_set = function(_col, _row, _dead_sprite_id) {
	if (_row < 0 || _col < 0) exit;
	
	// Expand rows
	while (array_length(play_grid) <= _row) {
		array_push(play_grid, array_create(max(grid_width, _col + 1), GRID_EMPTY));
	}
	
	// Expand columns
	if (_col >= array_length(play_grid[_row])) {
		var _old_len = array_length(play_grid[_row]);
		array_resize(play_grid[_row], _col + 1);
		for (var _i = _old_len; _i <= _col; _i++) {
			play_grid[_row][_i] = GRID_EMPTY;
		}
	}
	
	play_grid[_row][_col] = _dead_sprite_id;
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
				if (is_locked && abs(y - _row_y) < 2) {
					instance_destroy();
				}
			}
			
			// 2. Shift all locked blocks above this row down by one cell
			with (obj_block) {
				if (is_locked && (y < _row_y - 2)) {
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
