target_y = get_spawn_y() - sprite_get_yoffset(spr_next_piece_frame) + sprite_get_height(spr_next_piece_frame);
next_piece_frame_y = lerp(next_piece_frame_y, target_y, 0.08);

draw_sprite(spr_next_piece_frame, 0, next_piece_frame_x, next_piece_frame_y);

if (next_shape_name != "") {
	var _shape_props = global.shape_properties;
	if (struct_exists(_shape_props, next_shape_name)) {
		var _shape_data = _shape_props[$ next_shape_name];
		var _shape_sprite = _shape_data.display_spr;

		draw_sprite(
			_shape_sprite, 0, 
			next_piece_frame_x - sprite_get_xoffset(_shape_sprite) + sprite_get_width(_shape_sprite) / 2,
			next_piece_frame_y + sprite_get_yoffset(_shape_sprite) - sprite_get_height(_shape_sprite) / 2
		);
	}
}

hold_piece_frame_y = next_piece_frame_y;
draw_sprite(spr_hold_frame, 0, hold_piece_frame_x, hold_piece_frame_y);

if (hold_shape_name != "") {
	var _shape_props = global.shape_properties;
	if (struct_exists(_shape_props, hold_shape_name)) {
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
}

// Draw incoming garbage danger gauge
if (incoming_garbage > 0) {
	var _meter_x = grid_start_x - 8;
	var _meter_bottom_y = grid_bottom_y;
	var _meter_height = min(incoming_garbage, grid_height) * CELL_SIZE;
	draw_rectangle_colour(_meter_x - 6, _meter_bottom_y - _meter_height, _meter_x, _meter_bottom_y, c_red, c_red, c_orange, c_orange, false);
}
