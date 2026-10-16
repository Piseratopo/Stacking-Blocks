// ─── Network Manager ────────────────────────────────────────────────────────

// Connection properties
server_ip    = "127.0.0.1";
server_port  = 5001;
is_connected = false;
last_error   = "";
ping_timer   = 0;
ping_rtt     = 0;

// Player & Room state
my_name           = "Player " + string(irandom_range(100, 999));
my_slot           = -1;
is_host           = false;
is_ready          = false;
room_code         = "";
room_state        = "DISCONNECTED"; // DISCONNECTED, CONNECTED, LOBBY, COUNTDOWN, IN_GAME, GAME_OVER
players           = [];             // Array of structs: { slot, name, ready, alive, score, lines_cleared }
max_players       = 2;
match_seed        = 0;
countdown_seconds = 3;
winner_slot       = -1;
winner_name       = "";

// Piece sync throttling cache
last_sync_x   = -1;
last_sync_y   = -1;
last_sync_rot = -1;

// ─── Helper: Connection ──────────────────────────────────────────────────────
connect_to_server = function(_host = server_ip, _port = server_port) {
	server_ip   = _host;
	server_port = _port;
	
	network_init();
	network_server(_host, _port);
	
	is_connected = (global.server >= 0);
	if (is_connected) {
		room_state = "CONNECTED";
		show_debug_message("[Network] Connected to " + _host + ":" + string(_port));
	} else {
		room_state = "DISCONNECTED";
		show_debug_message("[Network] Failed to connect to " + _host + ":" + string(_port));
	}
	return is_connected;
};

disconnect_from_server = function() {
	if (is_connected) {
		send_leave();
		network_disconnect();
		is_connected = false;
		room_state   = "DISCONNECTED";
		show_debug_message("[Network] Disconnected from server.");
	}
};

// ─── Helper: Board Lookup & Spawner ──────────────────────────────────────────
get_remote_board_by_slot = function(_slot) {
	if (!instance_exists(obj_controller)) return noone;
	for (var _i = 0; _i < array_length(obj_controller.remote_boards); _i++) {
		var _b = obj_controller.remote_boards[_i];
		if (instance_exists(_b) && _b.slot_index == _slot) {
			return _b;
		}
	}
	return noone;
};

ensure_remote_board = function(_slot, _name) {
	var _existing = get_remote_board_by_slot(_slot);
	if (_existing != noone) return _existing;
	if (!instance_exists(obj_controller)) return noone;
	
	// Position opponent board to the right of local board (800px spacing accommodates UI frames cleanly)
	var _board_idx = array_length(obj_controller.remote_boards) + 1;
	var _opp_x = obj_controller.grid_start_x + _board_idx * 800;
	var _opp_y = obj_controller.grid_bottom_y;
	return obj_controller.spawn_remote_board(_slot, _name, _opp_x, _opp_y, _slot);
};

// ─── Outgoing Protocol Emitters ──────────────────────────────────────────────
create_room = function(_max_p = 2, _name = my_name) {
	if (!is_connected) connect_to_server();
	if (!is_connected) exit;
	
	my_name = _name;
	var _map = ds_map_create();
	_map[? "max_players"] = _max_p;
	_map[? "name"]        = _name;
	network_emit("room_create", _map);
};

join_room = function(_code, _name = my_name) {
	if (!is_connected) connect_to_server();
	if (!is_connected) exit;
	
	my_name = _name;
	var _map = ds_map_create();
	_map[? "code"] = string_upper(string_trim(_code));
	_map[? "name"] = _name;
	network_emit("room_join", _map);
};

send_ready = function(_ready = undefined) {
	if (!is_connected) exit;
	if (_ready == undefined) {
		is_ready = !is_ready;
	} else {
		is_ready = _ready;
	}
	var _map = ds_map_create();
	_map[? "ready"] = is_ready;
	network_emit("player_ready", _map);
};

send_attack = function(_lines, _hole_col = 0, _target_slot = -1) {
	if (!is_connected || room_state != "IN_GAME") exit;
	var _map = ds_map_create();
	_map[? "lines"]    = _lines;
	_map[? "hole_col"] = _hole_col;
	if (_target_slot >= 0) {
		_map[? "target_slot"] = _target_slot;
	}
	network_emit("attack_send", _map);
};

send_ko = function() {
	if (!is_connected || room_state != "IN_GAME") exit;
	var _map = ds_map_create();
	_map[? "slot"] = my_slot;
	network_emit("player_ko", _map);
};

send_piece_sync = function(_rel_x, _rel_y, _shape, _rot) {
	if (!is_connected || room_state != "IN_GAME") exit;
	var _map = ds_map_create();
	_map[? "x"]     = _rel_x;
	_map[? "y"]     = _rel_y;
	_map[? "shape"] = _shape;
	_map[? "rot"]   = _rot;
	network_emit("piece_sync", _map);
};

send_piece_locked = function(_lines_cleared, _blocks_arr = [], _garbage_lines = 0, _garbage_hole = -1) {
	if (!is_connected || room_state != "IN_GAME") exit;
	var _map = ds_map_create();
	_map[? "lines_cleared"] = _lines_cleared;
	_map[? "garbage_lines"] = _garbage_lines;
	_map[? "garbage_hole"]  = _garbage_hole;

	var _blist = ds_list_create();
	for (var _i = 0; _i < array_length(_blocks_arr); _i++) {
		var _bmap = ds_map_create();
		_bmap[? "col"]   = _blocks_arr[_i].col;
		_bmap[? "row"]   = _blocks_arr[_i].row;
		_bmap[? "shape"] = _blocks_arr[_i].shape;
		ds_list_add(_blist, _bmap);
		ds_list_mark_as_map(_blist, _i);
	}
	ds_map_add_list(_map, "blocks", _blist);

	network_emit("piece_locked", _map);
};

send_leave = function() {
	if (!is_connected) exit;
	var _map = ds_map_create();
	_map[? "dummy"] = 1;
	network_emit("room_leave", _map);
	
	room_code  = "";
	room_state = "CONNECTED";
	players    = [];
	is_ready   = false;

   obj_controller.destroy_remote_boards();
   obj_controller.reset_game();
};

send_ping = function() {
	if (!is_connected) exit;
	var _map = ds_map_create();
	_map[? "client_time"] = current_time;
	network_emit("ping", _map);
};

// ─── Init and Connect ─────────────────────────────────────────────────────────
// Packet dispatch is handled directly in the Async Networking event (Other_68).
// network_init() sets up global.splitter and global.listener (still needed for
// network_emit to write the splitter correctly).
network_init();

// Attempt initial connection to backend server
connect_to_server();

