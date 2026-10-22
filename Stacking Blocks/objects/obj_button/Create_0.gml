if (flex_node != noone) {
   var _pos = flexpanel_node_layout_get_position(flex_node, false);
   if (_pos.width > 0 && _pos.height > 0) {
      x = _pos.left;
      y = _pos.top;
      image_xscale = _pos.width / sprite_get_width(sprite_index);
      image_yscale = _pos.height / sprite_get_height(sprite_index);
   }
}

on_click = function() {
    switch (name) {
        case "play":
            if (instance_exists(obj_ui_manager)) {
                obj_ui_manager.show_play_mode_menu();
            }
            break;
        case "singleplayer":
            room_goto(rm_singleplayer);
            break;
        case "multiplayer":
            room_goto(rm_multiplayer);
            break;
        case "back":
            if (instance_exists(obj_ui_manager)) {
                obj_ui_manager.show_main_menu();
            }
            break;
        case "options":
            // TODO: Implement options menu
            break;
        case "quit":
            game_end();
            break;
    }
};
