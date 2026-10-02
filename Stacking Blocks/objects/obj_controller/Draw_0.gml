next_piece_frame_y = get_spawn_y() - sprite_get_yoffset(spr_next_piece_frame) + sprite_get_height(spr_next_piece_frame);

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
