draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _bx = 16;
var _by = 16;
var _bw = 440;
var _bh = 190;

var _ty = _by + 10;
var _tx = _bx + 12;

// Connection Status
if (is_connected) {
	draw_set_colour(c_lime);
	draw_text(_tx, _ty, "● SERVER: Connected (" + string(ping_rtt) + "ms)");
} else {
	draw_set_colour(c_red);
	draw_text(_tx, _ty, "● SERVER: Disconnected");
}
_ty += 20;

// Room State & Code
draw_set_colour(c_yellow);
if (room_code != "") {
	var _role = is_host ? "HOST" : "GUEST";
	draw_text(_tx, _ty, "ROOM: " + room_code + " [" + _role + "] (Slot " + string(my_slot) + ")");
} else {
	draw_text(_tx, _ty, "ROOM: Not in a room (Press [C] or [J])");
}
_ty += 20;

draw_set_colour(c_aqua);
draw_text(_tx, _ty, "STATE: " + room_state);
_ty += 20;

// Players / Ready info
draw_set_colour(c_white);
if (room_state == "LOBBY" || room_state == "COUNTDOWN") {
	var _p_info = "Players (" + string(array_length(players)) + "/" + string(max_players) + "): ";
	for (var _i = 0; _i < array_length(players); _i++) {
		var _p = players[_i];
		_p_info += _p.name + (_p.ready ? " [READY] " : " [NOT READY] ");
	}
	draw_text(_tx, _ty, _p_info);
	_ty += 20;

	if (array_length(players) < max_players) {
		draw_set_colour(c_orange);
		draw_text(_tx, _ty, "Waiting for Player 2 to join...");
		_ty += 20;
	} else {
		draw_set_colour(c_yellow);
		draw_text(_tx, _ty, "All players joined! Press [R] to Ready");
		_ty += 20;
	}
} else if (room_state == "IN_GAME") {
	draw_text(_tx, _ty, "Seed: " + string(match_seed) + " | Game Active");
	_ty += 20;
} else if (room_state == "GAME_OVER") {
	draw_text(_tx, _ty, "Winner: " + winner_name + " (Slot " + string(winner_slot) + ")");
	_ty += 20;
}

// Error Message if any
if (last_error != "") {
	draw_set_colour(c_orange);
	draw_text(_tx, _ty, "ERR: " + last_error);
	_ty += 18;
}

// Hotkey instructions
draw_set_colour(c_ltgray);
draw_text(_tx, _ty, "[C] Create  [J] Join  [R] Ready  [L] Leave");
