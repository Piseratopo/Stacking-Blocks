// Check if mouse is hovering over button
is_hovered = (mouse_x >= x && mouse_x <= x + sprite_width &&
             mouse_y >= y && mouse_y <= y + sprite_height);

// Handle mouse click
if (is_hovered && mouse_check_button_pressed(mb_left)) {
    on_click();
}
