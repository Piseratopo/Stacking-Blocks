// Draw button background with hover effect
var _btn_color = is_hovered ? c_yellow : c_white;
var _bg_color = is_hovered ? c_dkgray : c_black;

draw_set_colour(_bg_color);
draw_rectangle(x, y, x + sprite_width, y + sprite_height, false);

draw_set_colour(_btn_color);
draw_rectangle(x, y, x + sprite_width, y + sprite_height, true);

// Draw label text
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_text);
draw_set_colour(_btn_color);
draw_text(x + sprite_width / 2, y + sprite_height / 2, label);
draw_set_halign(fa_left);
draw_set_valign(fa_top);