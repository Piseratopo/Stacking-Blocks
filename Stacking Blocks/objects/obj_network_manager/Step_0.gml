// ─── Network Manager Step ───────────────────────────────────────────────────

// 1. Keepalive Ping every ~3 seconds (180 steps at 60fps)
ping_timer++;
if (ping_timer >= 180) {
	ping_timer = 0;
	if (is_connected) {
		send_ping();
	}
}

// 2. Active Piece Synchronization (Normalized coordinates relative to local board origin)
if (room_state == "IN_GAME" && is_connected && instance_exists(obj_controller)) {
	var _lb = obj_controller.local_board;
	if (instance_exists(_lb) && _lb.is_alive && instance_exists(_lb.current_shape)) {
		var _s = _lb.current_shape;
		if (_s.x != last_sync_x || _s.y != last_sync_y || _s.orientation != last_sync_rot) {
			last_sync_x   = _s.x;
			last_sync_y   = _s.y;
			last_sync_rot = _s.orientation;
			var _rel_x    = _s.x - _lb.grid_start_x;
			var _rel_y    = _s.y - _lb.grid_bottom_y;
			send_piece_sync(_rel_x, _rel_y, _s.shape_name, _s.orientation, _lb.next_shape_name, _lb.hold_shape_name);
		}
	}
}

// 3. Testing Hotkeys (for quick multiplayer verification)
if (keyboard_check_pressed(ord("C"))) {
	// Create a new 1v1 room
	create_room(2, my_name);
}

if (keyboard_check_pressed(ord("J"))) {
	// Prompt for room code to join
	var _code = get_string("Enter 4-letter Room Code:", "");
	if (_code != "") {
		join_room(_code, my_name);
	}
}

if (keyboard_check_pressed(ord("R"))) {
	// Toggle ready state
	if (room_state == "LOBBY") {
		send_ready();
	}
}

if (keyboard_check_pressed(ord("L"))) {
	// Leave current room
	send_leave();
}

if (keyboard_check_pressed(ord("G"))) {
	send_attack(20);
	// receive_garbage(20);
}
