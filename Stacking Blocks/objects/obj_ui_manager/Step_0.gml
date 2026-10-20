if (ui_mode == "MENU") {
    // Keyboard shortcuts for menu navigation
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
        // Activate hovered button
        for (var i = 0; i < array_length(buttons); i++) {
            if (buttons[i].is_hovered) {
                buttons[i].on_click();
                break;
            }
        }
    }

    // Specific hotkeys
    if (keyboard_check_pressed(ord("P"))) {
        button_play.on_click();
    }
}
