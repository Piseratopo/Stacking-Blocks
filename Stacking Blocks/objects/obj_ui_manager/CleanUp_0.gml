if (variable_instance_exists(id, "ui_mode") && ui_mode == "MENU") {
    if (variable_instance_exists(id, "buttons") && is_array(buttons) && array_length(buttons) > 0) {
       for (var i = 0; i < array_length(buttons); i++) {
          if (instance_exists(buttons[i])) {
             instance_destroy(buttons[i]);
          }
       }
    }

    if (variable_instance_exists(id, "flexpanel_root") && flexpanel_root != undefined && flexpanel_root != noone) {
        flexpanel_delete_node(flexpanel_root, true);
    }
}