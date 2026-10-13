// ─── Board identity & positioning ──────────────────────────────────────────
is_local      = true;
slot_index    = 0;
player_id     = "";
player_name   = "Player 1";
is_alive      = true;

grid_width    = GRID_WIDTH;
grid_height   = GRID_HEIGHT;
grid_start_x  = GRID_START_X;
grid_bottom_y = GRID_BOTTOM_Y;
cell_size     = CELL_SIZE;

// ─── Board state ─────────────────────────────────────────────────────────────
current_shape          = noone;
finished_locking_shape = false;
incoming_garbage       = 0;
total_lines_cleared    = 0;

play_grid = array_create(grid_height);
for (var _r = 0; _r < grid_height; _r++) {
	play_grid[_r] = array_create(grid_width, GRID_EMPTY);
}

// ─── Versus state ────────────────────────────────────────────────────────────
combo_count        = -1;   // -1 so first clear gives combo_count = 0 (no bonus yet)
b2b_count          = 0;    // Consecutive difficult-clear chain length (0 = no active B2B)
pending_garbage    = 0;    // Incoming lines queued for next piece-lock (cancellable)
_last_garbage_hole = -1;   // Server-supplied hole column; -1 means use random
past_sixths        = 0;    // Leftover sixth-counters carried into next attack

depth = -100;

// ─── Next & Hold piece queue ─────────────────────────────────────────────────
next_shape_name = get_random_shape();
hold_shape_name = "";
can_hold        = true;

// UI Next & Hold Frame coordinates
var _right_border_x = grid_start_x + (grid_width + 1) * CELL_SIZE;
var _top_border_y   = grid_bottom_y - (grid_height + 1) * CELL_SIZE;

next_piece_frame_x = _right_border_x + sprite_get_xoffset(spr_next_piece_frame);
next_piece_frame_y = _top_border_y   + sprite_get_yoffset(spr_next_piece_frame);

var _left_border_x = grid_start_x - CELL_SIZE;
hold_piece_frame_x = _left_border_x - (sprite_get_width(spr_hold_frame) - sprite_get_xoffset(spr_hold_frame));
hold_piece_frame_y = _top_border_y  + sprite_get_yoffset(spr_hold_frame);

target_y = next_piece_frame_y;

// ─── Borders Setup ───────────────────────────────────────────────────────────
borders = [];
spawn_borders = function() {
	var _owner = id;
	var _top_y = grid_bottom_y - (grid_height + 1) * CELL_SIZE;
	var _h     = grid_height + 1;
	
	// Left wall
	var _left = instance_create_layer(grid_start_x - CELL_SIZE, _top_y, "Blocks", obj_border);
	_left.image_yscale = _h;
	_left.board_owner  = _owner;
	array_push(borders, _left);
	
	// Right wall
	var _right = instance_create_layer(grid_start_x + grid_width * CELL_SIZE, _top_y, "Blocks", obj_border);
	_right.image_yscale = _h;
	_right.board_owner  = _owner;
	array_push(borders, _right);
	
	// Floor
	var _floor = instance_create_layer(grid_start_x, grid_bottom_y, "Blocks", obj_border);
	_floor.image_xscale = grid_width;
	_floor.board_owner  = _owner;
	array_push(borders, _floor);
	
	// Corners
	var _bl = instance_create_layer(grid_start_x - CELL_SIZE, grid_bottom_y, "Blocks", obj_border);
	_bl.board_owner = _owner;
	array_push(borders, _bl);
	
	var _br = instance_create_layer(grid_start_x + grid_width * CELL_SIZE, grid_bottom_y, "Blocks", obj_border);
	_br.board_owner = _owner;
	array_push(borders, _br);
};

// Check if static borders already exist at this board's position in rm_play
var _existing_border = instance_position(grid_start_x - CELL_SIZE, grid_bottom_y, obj_border);
if (!_existing_border) {
	spawn_borders();
} else {
	var _owner = id;
	with (obj_border) {
		if (x >= other.grid_start_x - CELL_SIZE && x <= other.grid_start_x + other.grid_width * CELL_SIZE) {
			board_owner = _owner;
		}
	}
}

// ─── Spawn Helpers ───────────────────────────────────────────────────────────
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

spawn_shape = function(_shape_name) {
	var _spawn_y = get_spawn_y();
	var _spawn_x = grid_start_x + CELL_SIZE * (grid_width / 2);
	var _shape_props = global.shape_properties;
	var _inst = instance_create_layer(_spawn_x, _spawn_y, "Blocks", obj_shape, {
		board_owner:  id,
		shape_name:   _shape_name,
		shape_data:   _shape_props[$ _shape_name],
		sprite_index: _shape_props[$ _shape_name].display_spr,
		lock_spr:     _shape_props[$ _shape_name].lock_spr,
		orientation:  0,
		image_angle:  0,
		image_speed:  0,
	});
	
	current_shape = _inst;

	if (is_local) {
		with (obj_camera) {
			target_y = _spawn_y + 10 * CELL_SIZE - camera_height / 2;
		}
	}
	return _inst;
};

// ─── Grid Manipulation Methods ───────────────────────────────────────────────
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

// ─── Line-clear core ──────────────────────────────────────────────────────────
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

// ─── Attack generator (Sixth-counters) ────────────────────────────────────────
// Slc  = 2 * N * (N-1)
// Cb   = max(0, combo_count)
// Sp   = 6 * N (if spin)
// B    = 6 * b2b_count (burst on normal clear breaking difficult chain)
// Past = past_sixths
// Tot  = (Slc + Cb + Sp + B + Past) * Multiplier
// Lines sent = Tot div 6; past_sixths = Tot mod 6
calculate_and_send_attack = function(_lines_cleared, _is_spin) {
	if (_lines_cleared > 0) {
		combo_count++;
	} else {
		combo_count = -1;
	}
	var _cb = max(0, combo_count);

	var _is_difficult = (_is_spin || _lines_cleared >= 4);

	var _N   = _lines_cleared;
	var _slc = 2 * _N * (_N - 1);
	var _sp  = _is_spin ? (6 * _N) : 0;
	var _b   = 0;

	if (_lines_cleared > 0) {
		if (_is_difficult) {
			b2b_count++;
		} else {
			_b = 6 * b2b_count;
			b2b_count = 0;
		}
	}

	var _special    = 0;
	var _multiplier = 1;
	var _tot_sixths = (_slc + _cb + _sp + _b + _special + past_sixths) * _multiplier;

	var _lines_sent = _tot_sixths div 6;
	past_sixths     = _tot_sixths mod 6;

	// Garbage cancellation against incoming queue
	if (_lines_sent > 0) {
		var _cancelled = min(_lines_sent, pending_garbage);
		pending_garbage -= _cancelled;
		_lines_sent     -= _cancelled;
	}

	if (_lines_sent > 0 && is_local && instance_exists(obj_network_manager)) {
		var _hole = irandom(grid_width - 1);
		obj_network_manager.send_attack(_lines_sent, _hole);
	}

	return _lines_sent;
};

// ─── Garbage reception ───────────────────────────────────────────────────────
receive_garbage = function(_lines, _hole_col = -1) {
	if (_lines <= 0) exit;
	pending_garbage += _lines;
	if (_hole_col >= 0 && _hole_col < grid_width) {
		_last_garbage_hole = _hole_col;
	}
};

// ─── Garbage application ─────────────────────────────────────────────────────
apply_garbage = function() {
	if (pending_garbage <= 0) return;
	var _lines_to_push = pending_garbage;
	pending_garbage = 0;
	var _owner = id;

	// Shift all locked blocks upward
	with (obj_block) {
		if (board_owner == _owner && is_locked) {
			y -= _lines_to_push * CELL_SIZE;
		}
	}

	// Insert garbage rows at bottom of grid
	for (var _g = 0; _g < _lines_to_push; _g++) {
		var _hole;
		if (_last_garbage_hole >= 0) {
			_hole = _last_garbage_hole;
			_last_garbage_hole = -1;
		} else {
			_hole = irandom(grid_width - 1);
		}

		var _row = array_create(grid_width, "I");
		_row[_hole] = GRID_EMPTY;
		array_insert(play_grid, 0, _row);

		var _row_y = grid_row_to_y(0, grid_bottom_y);
		for (var _c = 0; _c < grid_width; _c++) {
			if (_c != _hole) {
				instance_create_layer(
					grid_col_to_x(_c, grid_start_x),
					_row_y,
					"Blocks", obj_block,
					{
						board_owner:  _owner,
						is_locked:    true,
						sprite_index: spr_lock_I,
						image_index:  0,
						image_speed:  0,
						image_blend:  c_dkgray,
						block_name:   "I"
					}
				);
			}
		}
	}

	// ── Top-out detection ────────────────────────────────────────────────────
	var _top_limit_y = grid_bottom_y - grid_height * CELL_SIZE;
	var _topped_out  = false;
	with (obj_block) {
		if (board_owner == _owner && is_locked && y < _top_limit_y) {
			_topped_out = true;
			break;
		}
	}
	if (_topped_out && is_local) {
		is_alive = false;
		if (instance_exists(obj_network_manager)) {
			obj_network_manager.send_ko();
		}
	}
};
