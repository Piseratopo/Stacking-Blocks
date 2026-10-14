// ─── Standard single-hole garbage ────────────────────────────────────────────
/// Push one standard garbage row with a single hole.
/// @param {Id.Instance} _board   The obj_player_board instance
/// @param {int}         _row     Target row index in play_grid (1-based, 1 = bottom playable row)
/// @param {int}         _hole    Column index (0-based) for the open hole; -1 = random
function garbage_push_single_hole(_board, _row, _hole = -1) {
	if (_hole < 0 || _hole >= _board.grid_width) {
		_hole = irandom(_board.grid_width - 1);
	}

	var _row_y    = grid_row_to_y(_row, _board.grid_bottom_y);
	var _owner    = _board.id;
	var _lock_spr = global.shape_properties.Gb.lock_spr;

	for (var _c = 0; _c < _board.grid_width; _c++) {
		if (_c == _hole) continue;

		_board.grid_set(_c, _row, "Gb");

		instance_create_layer(
			grid_col_to_x(_c, _board.grid_start_x),
			_row_y,
			"Blocks", obj_block,
			{
				board_owner:  _owner,
				is_locked:    true,
				sprite_index: _lock_spr,
				image_index:  0,
				image_speed:  0,
				block_name:   "Gb"
			}
		);
	}
}

// ─── Double-hole garbage ─────────────────────────────────────────────────────
/// Push one garbage row with two open holes (for future use).
/// @param {Id.Instance} _board   The obj_player_board instance
/// @param {int}         _row     Target row index in play_grid (1-based)
/// @param {int}         _hole1   First hole column; -1 = random
/// @param {int}         _hole2   Second hole column; -1 = random adjacent
function garbage_push_double_hole(_board, _row, _hole1 = -1, _hole2 = -1) {
	var _w = _board.grid_width;
	if (_hole1 < 0 || _hole1 >= _w) _hole1 = irandom(_w - 1);
	if (_hole2 < 0 || _hole2 >= _w || _hole2 == _hole1) {
		_hole2 = (_hole1 + 1) mod _w;
	}

	var _row_y    = grid_row_to_y(_row, _board.grid_bottom_y);
	var _owner    = _board.id;
	var _lock_spr = global.shape_properties.Gb.lock_spr;

	for (var _c = 0; _c < _w; _c++) {
		if (_c == _hole1 || _c == _hole2) continue;

		_board.grid_set(_c, _row, "Gb");

		instance_create_layer(
			grid_col_to_x(_c, _board.grid_start_x),
			_row_y,
			"Blocks", obj_block,
			{
				board_owner:  _owner,
				is_locked:    true,
				sprite_index: _lock_spr,
				image_index:  0,
				image_speed:  0,
				block_name:   "Gb"
			}
		);
	}
}
