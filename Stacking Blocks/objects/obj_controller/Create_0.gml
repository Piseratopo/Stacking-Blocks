randomise();

// Board identity & settings
board_id = 0;
is_local = true;
player_name = "Player 1";
grid_width = GRID_WIDTH;
grid_height = GRID_HEIGHT;
grid_start_x = GRID_START_X;
grid_bottom_y = GRID_BOTTOM_Y;

current_shape = noone;
finished_locking_shape = false;
incoming_garbage = 0;

play_grid = array_create(grid_height);
for (var _r = 0; _r < grid_height; _r++) {
	play_grid[_r] = array_create(grid_width, GRID_EMPTY);
}

total_lines_cleared = 0;

depth = -100;

get_spawn_y = function() {
	var _top_y = grid_bottom_y - (grid_height + 1) * CELL_SIZE;
	var _owner = id;
	with (obj_block) {
		if (board_owner == _owner && is_locked && y - 5 * CELL_SIZE < _top_y) {
			_top_y = y - 5 * CELL_SIZE;
		}
	}

	return _top_y;
};


// Spawn helper
spawn_shape = function(_shape_name) {
	var _spawn_y = get_spawn_y();
	var _spawn_x = grid_start_x + CELL_SIZE * (grid_width / 2);
	var _shape_props = global.shape_properties;
	var _inst = instance_create_layer(_spawn_x, _spawn_y, "Blocks", obj_shape, {
		board_owner: id,
		shape_name: _shape_name,
		shape_data: _shape_props[$ _shape_name],
		sprite_index: _shape_props[$ _shape_name].display_spr,
		lock_spr: _shape_props[$ _shape_name].lock_spr,
		orientation: 0,
		image_angle: 0,
		image_speed: 0,
	});
	
	current_shape = _inst;

	if (is_local) {
		with (obj_camera) {
			target_y = _spawn_y + 10 * CELL_SIZE - camera_height / 2;
		}
	}
	return _inst;
};

next_shape_name = get_random_shape();

hold_shape_name = "";
can_hold = true;

// UI Next & Hold Frame coordinates
var _right_border_x = grid_start_x + (grid_width + 1) * CELL_SIZE;
var _top_border_y = grid_bottom_y - (grid_height + 1) * CELL_SIZE;

next_piece_frame_x = _right_border_x + sprite_get_xoffset(spr_next_piece_frame);
next_piece_frame_y = _top_border_y + sprite_get_yoffset(spr_next_piece_frame);

var _left_border_x = grid_start_x - CELL_SIZE;
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
	var _owner = id;
	
	while (_r < array_length(play_grid)) {
		if (is_row_full(_r)) {
			var _row_y = grid_row_to_y(_r, grid_bottom_y);
			
			// 1. Destroy locked blocks in this row belonging to this board
			with (obj_block) {
				if (board_owner == _owner && is_locked && y == _row_y) {
					instance_destroy();
				}
			}
			
			// 2. Shift all locked blocks above this row down by one cell
			with (obj_block) {
				if (board_owner == _owner && is_locked && y < _row_y) {
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

// Garbage lines mechanism for multiplayer
receive_garbage = function(_lines, _hole_col = -1) {
	incoming_garbage += _lines;
};

apply_garbage = function() {
	if (incoming_garbage <= 0) return;
	var _lines_to_push = incoming_garbage;
	incoming_garbage = 0;
	var _owner = id;

	// Shift locked blocks up
	with (obj_block) {
		if (board_owner == _owner && is_locked) {
			y -= _lines_to_push * CELL_SIZE;
		}
	}

	// Insert garbage rows at bottom of grid
	for (var _g = 0; _g < _lines_to_push; _g++) {
		var _hole = irandom(grid_width - 1);
		var _row = array_create(grid_width, "I");
		_row[_hole] = GRID_EMPTY;
		array_insert(play_grid, 0, _row);

		var _row_y = grid_row_to_y(0, grid_bottom_y) - _g * CELL_SIZE;
		for (var _c = 0; _c < grid_width; _c++) {
			if (_c != _hole) {
				var _bx = grid_col_to_x(_c, grid_start_x);
				instance_create_layer(_bx, _row_y, "Blocks", obj_block, {
					board_owner:  _owner,
					is_locked:    true,
					sprite_index: spr_lock_I,
					image_index:  0,
					image_speed:  0,
					image_blend:  c_dkgray,
					block_name:   "I"
				});
			}
		}
	}
};

