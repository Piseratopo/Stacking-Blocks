// Draw button background
draw_sprite(spr_button, 0, x, y);

// Draw label text
if (string_length(label) > 0)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(x + sprite_get_width(spr_button) / 2, y + sprite_get_height(spr_button) / 2, label);
}
