randomise();

// ─── Match / System Orchestrator ─────────────────────────────────────────────
// obj_controller manages global game state, network synchronization,
// and orchestrates local and remote obj_player_board instances.

grid_width    = GRID_WIDTH;
grid_height   = GRID_HEIGHT;
grid_start_x  = GRID_START_X;
grid_bottom_y = GRID_BOTTOM_Y;

// Array of remote opponent boards
remote_boards = [];

// Spawn the primary local player board
local_board = instance_create_layer(0, 0, "Controllers", obj_player_board, {
	is_local:      true,
	slot_index:    0,
	player_id:     "local",
	player_name:   "Player 1",
	grid_start_x:  GRID_START_X,
	grid_bottom_y: GRID_BOTTOM_Y,
	grid_width:    GRID_WIDTH,
	grid_height:   GRID_HEIGHT
});

// Helper for Step 4+ to dynamically spawn remote opponent boards
spawn_remote_board = function(_player_id, _player_name, _start_x, _bottom_y, _slot = 1) {
	var _board = instance_create_layer(0, 0, "Controllers", obj_player_board, {
		is_local:      false,
		slot_index:    _slot,
		player_id:     _player_id,
		player_name:   _player_name,
		grid_start_x:  _start_x,
		grid_bottom_y: _bottom_y,
		grid_width:    GRID_WIDTH,
		grid_height:   GRID_HEIGHT
	});
	array_push(remote_boards, _board);
	return _board;
};
