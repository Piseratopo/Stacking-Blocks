/// @description Async Networking Event - Custom dispatcher (bypasses script_execute + method incompatibility)

var _net_type = async_load[? "type"];

if (_net_type == network_type_data) {
	var _buf = async_load[? "buffer"];
	var _raw = buffer_read(_buf, buffer_text);
	buffer_delete(_buf);
	
	// Split on the packet delimiter (may receive multiple packets at once)
	while (string_pos(global.splitter, _raw) > 0) {
		var _pkt_str = string_copy(_raw, 1, string_pos(global.splitter, _raw) - 1);
		_raw = string_delete(_raw, 1, string_pos(global.splitter, _raw) + string_length(global.splitter) - 1);
		
		if (_pkt_str == "") continue;
		
		var _pkt = json_decode(_pkt_str);
		if (_pkt == -1) continue;
		
		var _event = _pkt[? "identify"];
		if (is_string(_event)) {
			var _data = _pkt[? _event];
			
			show_debug_message("[Network RX] " + _event);
			
			// ─── Direct dispatch ─────────────────────────────────────────────
			if (_event == "room_created") {
				room_code   = ds_map_exists(_data, "code")        ? string(_data[? "code"])       : room_code;
				my_slot     = ds_map_exists(_data, "slot")        ? real(_data[? "slot"])         : my_slot;
				max_players = ds_map_exists(_data, "max_players") ? real(_data[? "max_players"])  : max_players;
				is_host    = true;
				is_ready   = false;
				room_state = "LOBBY";
				last_error = "";
				
			} else if (_event == "room_joined") {
				room_code   = ds_map_exists(_data, "code")        ? string(_data[? "code"])       : room_code;
				my_slot     = ds_map_exists(_data, "slot")        ? real(_data[? "slot"])         : my_slot;
				max_players = ds_map_exists(_data, "max_players") ? real(_data[? "max_players"])  : max_players;
				is_host    = false;
				is_ready   = false;
				room_state = "LOBBY";
				last_error = "";
				
			} else if (_event == "room_error") {
				if (ds_exists(_data, ds_type_map)) {
					last_error = string(_data[? "message"]);
				}
				
			} else if (_event == "room_update") {
				if (ds_exists(_data, ds_type_map)) {
					if (ds_map_exists(_data, "code"))  room_code  = string(_data[? "code"]);
					if (ds_map_exists(_data, "state")) room_state = string(_data[? "state"]);
					
					players = [];
					if (ds_map_exists(_data, "players")) {
						var _plist = _data[? "players"];
						if (ds_exists(_plist, ds_type_list)) {
							for (var _i = 0; _i < ds_list_size(_plist); _i++) {
								var _pm = _plist[| _i];
								if (ds_exists(_pm, ds_type_map)) {
									array_push(players, {
										slot:          real(_pm[? "slot"]),
										name:          string(_pm[? "name"]),
										ready:         bool(_pm[? "ready"]),
										alive:         bool(_pm[? "alive"]),
										score:         ds_map_exists(_pm, "score")         ? real(_pm[? "score"])         : 0,
										lines_cleared: ds_map_exists(_pm, "lines_cleared") ? real(_pm[? "lines_cleared"]) : 0
									});
								}
							}
						}
					}
				}
				
			} else if (_event == "countdown_start") {
				if (ds_exists(_data, ds_type_map)) {
					countdown_seconds = real(_data[? "seconds"]);
					match_seed        = real(_data[? "seed"]);
				}
				room_state = "COUNTDOWN";
				random_set_seed(match_seed);
				if (instance_exists(obj_controller)) {
					obj_controller.reset_game();
				}
				
			} else if (_event == "match_start") {
				if (ds_exists(_data, ds_type_map)) {
					match_seed = real(_data[? "seed"]);
				}
				room_state = "IN_GAME";
				random_set_seed(match_seed);
				
				// Spawn remote boards for all non-local slots
				for (var _i = 0; _i < array_length(players); _i++) {
					var _p = players[_i];
					if (_p.slot != my_slot && instance_exists(obj_controller)) {
						ensure_remote_board(_p.slot, _p.name);
					}
				}
				
				// Clear boards and destroy any falling pieces for match start
				if (instance_exists(obj_controller)) {
					obj_controller.reset_game();
				}
				
			} else if (_event == "attack_receive") {
				if (ds_exists(_data, ds_type_map)) {
					var _lines = real(_data[? "lines"]);
					var _hole  = real(_data[? "hole_col"]);
					if (instance_exists(obj_controller) && instance_exists(obj_controller.local_board)) {
						obj_controller.local_board.receive_garbage(_lines, _hole);
					}
				}
				
			} else if (_event == "piece_sync") {
				if (ds_exists(_data, ds_type_map)) {
					var _slot  = real(_data[? "slot"]);
					var _px    = real(_data[? "x"]);
					var _py    = real(_data[? "y"]);
					var _shape = string(_data[? "shape"]);
					var _rot   = real(_data[? "rot"]);
					var _board = ensure_remote_board(_slot, "Opponent");
					if (_board != noone) {
						_board.remote_piece_x      = _px;
						_board.remote_piece_y      = _py;
						_board.remote_piece_shape  = _shape;
						_board.remote_piece_rot    = _rot;
						_board.remote_piece_active = true;
					}
				}
				
			} else if (_event == "piece_locked") {
				if (ds_exists(_data, ds_type_map)) {
					var _slot  = real(_data[? "slot"]);
					var _lines = ds_map_exists(_data, "lines_cleared") ? real(_data[? "lines_cleared"]) : 0;
					var _board = ensure_remote_board(_slot, "Opponent");
					if (_board != noone) {
						_board.remote_piece_active  = false;
						_board.total_lines_cleared += _lines;
					}
				}
				
			} else if (_event == "player_ko") {
				if (ds_exists(_data, ds_type_map)) {
					var _slot  = real(_data[? "slot"]);
					var _board = get_remote_board_by_slot(_slot);
					if (_board != noone) _board.is_alive = false;
				}
				
			} else if (_event == "match_over") {
				if (ds_exists(_data, ds_type_map)) {
					winner_slot = real(_data[? "winner_slot"]);
					winner_name = string(_data[? "winner_name"]);
				}
				room_state = "GAME_OVER";
				
			} else if (_event == "pong") {
				if (ds_exists(_data, ds_type_map)) {
					var _send_t = real(_data[? "client_time"]);
					ping_rtt = current_time - _send_t;
				}
			}
		}
		
		ds_map_destroy(_pkt);
	}
	
} else if (_net_type == network_type_disconnect) {
	show_debug_message("[Network] Disconnected from server.");
	is_connected = false;
	room_state   = "DISCONNECTED";

} else if (_net_type == network_type_non_blocking_connect) {
	var _succeeded = async_load[? "succeeded"];
	is_connected = _succeeded;
	room_state   = _succeeded ? "CONNECTED" : "DISCONNECTED";
	show_debug_message("[Network] Async connect: " + string(_succeeded));
}
