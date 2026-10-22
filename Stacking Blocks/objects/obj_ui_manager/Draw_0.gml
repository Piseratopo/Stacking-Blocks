if (ui_mode == "MENU") {
    draw_set_font(fnt_text);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    var _title_text = (menu_state == "PLAY_SELECT") ? "SELECT MODE" : "STACKING BLOCKS";
    var _cx = room_width / 2;
    var _cy = 180;
    
    // Drop shadow
    draw_set_colour(c_black);
    draw_text_transformed(_cx + 2, _cy + 2, _title_text, 2, 2, 0);
    
    // Main text
    draw_set_colour(c_white);
    draw_text_transformed(_cx, _cy, _title_text, 2, 2, 0);
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
