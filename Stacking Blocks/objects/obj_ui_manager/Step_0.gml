if (variable_instance_exists(id, "last_room") && last_room != room) {
   last_room = room;
   if (variable_instance_exists(id, "handle_room_change") && is_callable(handle_room_change)) {
      handle_room_change();
   }
}

if (ui_mode == "MENU") {
   // Keyboard shortcuts for menu navigation
   if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
      // Activate hovered button
      for (var i = 0; i < array_length(buttons); i++) {
         if (instance_exists(buttons[i]) && buttons[i].is_hovered) {
            buttons[i].on_click();
            break;
         }
      }
   }

   // Specific hotkeys based on current menu state
   if (menu_state == "MAIN") {
      if (keyboard_check_pressed(ord("P"))) {
         if (variable_instance_exists(id, "button_play") && instance_exists(button_play)) {
            button_play.on_click();
         }
      }
   } else if (menu_state == "PLAY_SELECT") {
      if (keyboard_check_pressed(ord("S"))) {
         if (variable_instance_exists(id, "button_singleplayer") && instance_exists(button_singleplayer)) {
            button_singleplayer.on_click();
         }
      } else if (keyboard_check_pressed(ord("M"))) {
         if (variable_instance_exists(id, "button_multiplayer") && instance_exists(button_multiplayer)) {
            button_multiplayer.on_click();
         }
      } else if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("B"))) {
         if (variable_instance_exists(id, "button_back") && instance_exists(button_back)) {
            button_back.on_click();
         }
      }
   }
} else if (ui_mode == "GAME") {
   if (keyboard_check_pressed(vk_escape)) {
      if (variable_instance_exists(id, "button_in_game_back") && instance_exists(button_in_game_back)) {
         button_in_game_back.on_click();
      } else {
         room_goto(rm_menu);
      }
   }
}
