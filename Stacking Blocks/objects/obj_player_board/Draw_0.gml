target_y = get_spawn_y() - sprite_get_yoffset(spr_next_piece_frame) + sprite_get_height(spr_next_piece_frame);
next_piece_frame_y = lerp(next_piece_frame_y, target_y, 0.08);

draw_sprite(spr_next_piece_frame, 0, next_piece_frame_x, next_piece_frame_y);

if (next_shape_name != "") {
	var _shape_props = global.shape_properties;
	var _shape_data = _shape_props[$ next_shape_name];
	var _shape_sprite = _shape_data.display_spr;

	draw_sprite(
		_shape_sprite, 0, 
		next_piece_frame_x - sprite_get_xoffset(_shape_sprite) + sprite_get_width(_shape_sprite) / 2,
		next_piece_frame_y + sprite_get_yoffset(_shape_sprite) - sprite_get_height(_shape_sprite) / 2
	);
}

hold_piece_frame_y = next_piece_frame_y;
draw_sprite(spr_hold_frame, 0, hold_piece_frame_x, hold_piece_frame_y);

if (hold_shape_name != "") {
	var _shape_props = global.shape_properties;
	var _shape_data = _shape_props[$ hold_shape_name];
	var _shape_sprite = _shape_data.display_spr;
	var _alpha = can_hold ? 1.0 : 0.5;

	draw_sprite_ext(
		_shape_sprite, 0, 
		hold_piece_frame_x - sprite_get_xoffset(_shape_sprite) + sprite_get_width(_shape_sprite) / 2,
		hold_piece_frame_y + sprite_get_yoffset(_shape_sprite) - sprite_get_height(_shape_sprite) / 2,
		1, 1, 0, c_white, _alpha
	);
}

// Draw lines cleared indicator
if (last_lines_cleared > 0 || spin_text != "") {
	var _lines_alpha = 1.0;
	if (alarm[0] < GAME_SPEED) {
		_lines_alpha = alarm[0] / GAME_SPEED;
	}

	draw_set_font(fnt_text);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);

	var _hold_bottom_y = hold_piece_frame_y - sprite_get_yoffset(spr_hold_frame) + sprite_get_height(spr_hold_frame);
	var _lines_y = _hold_bottom_y + 16;

	var _lines_text = string_upper(number_to_funny_english(last_lines_cleared));
	if (spin_text != "") {
		_lines_text = spin_text + "-" + _lines_text;
	}

	draw_text_transformed_colour(hold_piece_frame_x + 2, _lines_y + 2, _lines_text, 1, 1, 0, c_black, c_black, c_black, c_black, _lines_alpha * 0.7);
	draw_text_transformed_colour(hold_piece_frame_x, _lines_y, _lines_text, 1, 1, 0, c_white, c_white, c_white, c_white, _lines_alpha);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(-1);
}

// Draw Remote Opponent Falling Piece
if (!is_local && remote_piece_active && remote_piece_shape != "") {
	var _shape_props = global.shape_properties;
	var _shape_data = _shape_props[$ remote_piece_shape];
	var _shape_spr  = _shape_data.display_spr;
	var _angle      = (360 - remote_piece_rot * 90) % 360;

	draw_sprite_ext(
		_shape_spr, 0,
		remote_piece_draw_x, remote_piece_draw_y,
		1, 1, _angle, c_white, 1.0
	);
}

// Draw incoming garbage danger gauge
var _gauge_lines = max(pending_garbage, incoming_garbage);
if (_gauge_lines > 0) {
	var _meter_x = grid_start_x - 8;
	var _meter_bottom_y = grid_bottom_y;
	var _meter_height = min(_gauge_lines, grid_height) * CELL_SIZE;
	draw_rectangle_colour(_meter_x - 6, _meter_bottom_y - _meter_height, _meter_x, _meter_bottom_y, c_red, c_red, c_red, c_red, false);
}

// Draw K.O. overlay if player topped out
if (!is_alive) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	var _cx = grid_start_x + (grid_width * CELL_SIZE) / 2;
	var _cy = grid_bottom_y - (grid_height * CELL_SIZE) / 2;
	draw_text_transformed_colour(_cx, _cy, "K.O.", 3, 3, 0, c_red, c_red, c_red, c_red, 1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
