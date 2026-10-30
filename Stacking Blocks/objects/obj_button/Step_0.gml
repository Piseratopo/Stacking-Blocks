// Check if mouse is hovering over button (GUI coordinates if use_gui, else world coordinates)
var _mx = (variable_instance_exists(id, "use_gui") && use_gui) ? device_mouse_x_to_gui(0) : mouse_x;
var _my = (variable_instance_exists(id, "use_gui") && use_gui) ? device_mouse_y_to_gui(0) : mouse_y;

is_hovered = (_mx >= x && _mx <= x + sprite_width &&
              _my >= y && _my <= y + sprite_height);

// Handle mouse click
if (is_hovered && mouse_check_button_pressed(mb_left)) {
   if (variable_instance_exists(id, "action") && is_callable(action)) {
      action();
   } else {
      on_click();
   }
}
