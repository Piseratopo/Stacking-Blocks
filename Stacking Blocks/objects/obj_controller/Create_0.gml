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

// Versus state
combo_count          = -1;  // -1 so first clear gives combo_count = 0 (no bonus yet)
b2b_count            = 0;   // Consecutive difficult-clear chain length (0 = no active B2B)
pending_garbage      = 0;   // Incoming lines queued for next piece-lock (cancellable)
_last_garbage_hole   = -1;  // Server-supplied hole column; -1 means use random
past_sixths          = 0;   // Leftover sixth-counters carried into the next attack


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

// ─── Line-clear core ──────────────────────────────────────────────────────────
// Clears full rows and returns the count. Pure grid/visual logic — no attack math.
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

// ─── Attack generator ─────────────────────────────────────────────────────────
// Called by lock_shape() with the line count and spin flag.
// Uses sixth-counters so fractional attacks carry across locks.
//
// Attack formula:
//   Slc  = 2 * N * (N-1)          Simultaneous line clear bonus
//   Cb   = C                      Combo (current combo count, 0 on first clear)
//   Sp   = 6 * N  (if spin)       Spin bonus (immobile check, all pieces)
//   B    = 6 * b2b_count          B2B-burst on a normal clear that breaks the chain
//   Past = past_sixths            Carry-over from previous attack
//   Tot  = (Slc + Cb + Sp + B + Special + Past) * Multiplier
//   Lines sent = Tot div 6;  past_sixths = Tot mod 6
//
// Difficult clear (4+ lines, or any spin): extend B2B chain, no burst.
// Normal clear (1-3 lines, no spin): reset chain and fire B burst.
calculate_and_send_attack = function(_lines_cleared, _is_spin) {
	// ── Combo ────────────────────────────────────────────────────────────────
	if (_lines_cleared > 0) {
		combo_count++;
	} else {
		combo_count = -1;
	}
	var _cb = max(0, combo_count);

	// ── Determine if this is a difficult clear ───────────────────────────────
	var _is_difficult = (_is_spin || _lines_cleared >= 4);

	// ── Sixth-counter components ─────────────────────────────────────────────
	var _N    = _lines_cleared;
	var _slc  = 2 * _N * (_N - 1);           // 0, 0, 4, 12, 24 … for 0-1-2-3-4 lines
	var _sp   = _is_spin ? (6 * _N) : 0;     // 6 per line cleared with a spin
	var _b    = 0;                            // B2B-burst fires only on a chain break

	// ── B2B state machine ────────────────────────────────────────────────────
	if (_lines_cleared > 0) {
		if (_is_difficult) {
			// Extend chain — no burst
			b2b_count++;
		} else {
			// Normal clear breaks the chain — fire burst equal to accumulated chain
			_b = 6 * b2b_count;
			b2b_count = 0;
		}
	}
	// (zero-line lock: no change to b2b_count, no burst)

	// ── Total sixths ─────────────────────────────────────────────────────────
	var _special    = 0;   // Reserved for future skills
	var _multiplier = 1;   // Reserved for future skills
	var _tot_sixths = (_slc + _cb + _sp + _b + _special + past_sixths) * _multiplier;

	var _lines_sent = _tot_sixths div 6;
	past_sixths     = _tot_sixths mod 6;

	// ── Garbage cancellation then send ───────────────────────────────────────
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
// Called by obj_network_manager when attack_receive arrives.
// Lines queue into pending_garbage so the player can cancel them before they rise.
receive_garbage = function(_lines, _hole_col = -1) {
	if (_lines <= 0) exit;
	pending_garbage += _lines;
	// Store the server-supplied hole column (latest value wins for the next apply)
	if (_hole_col >= 0 && _hole_col < grid_width) {
		_last_garbage_hole = _hole_col;
	}
};

// ─── Garbage application ─────────────────────────────────────────────────────
// Called after each piece lock (in Step_0). Pushes pending_garbage rows upward.
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

	// Insert garbage rows at the bottom of the grid
	for (var _g = 0; _g < _lines_to_push; _g++) {
		// Use server hole on first row, random for subsequent rows in the same burst
		var _hole;
		if (_last_garbage_hole >= 0) {
			_hole = _last_garbage_hole;
			_last_garbage_hole = -1;   // Consume — remaining rows get fresh random holes
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
		// Notify network manager; UI/visual handling deferred to Step 6
		if (instance_exists(obj_network_manager)) {
			obj_network_manager.send_ko();
		}
	}
};

