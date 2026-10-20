// Determine UI mode based on current room
ui_mode = (room == rm_menu) ? "MENU" : "MULTIPLAYER";

if (ui_mode == "MENU") {
    // Initialize the FlexPanel root layout for the menu
    flexpanel_root = flexpanel_create_node({
        width: room_width,
        height: room_height,
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
        gap: 20,
        padding: 40
    });

    button_width = 320;
    button_height = 64;
    button_flex_style = {
       width: button_width,
       height: button_height,
    };

    create_button = function(_name, _label, _style) {
       var _node = flexpanel_create_node(_style);
       var _btn = instance_create_layer(0, 0, layer, obj_button, {
          name: _name,
          label: _label,
          flex_node: _node
       });
       _btn.flex_node = _node;
       return _btn;
    };

    button_play = create_button("play", "Play", button_flex_style);
    button_options = create_button("options", "Options", button_flex_style);
    button_quit = create_button("quit", "Quit", button_flex_style);

    buttons = [button_play, button_options, button_quit];

    for (var i = 0; i < array_length(buttons); i++) {
       flexpanel_node_insert_child(flexpanel_root, buttons[i].flex_node, i);
    }

    // Function to calculate and apply layout positions to button instances
    update_layout = function() {
       flexpanel_calculate_layout(flexpanel_root, room_width, room_height);
       for (var i = 0; i < array_length(buttons); i++) {
          var _btn = buttons[i];
          if (instance_exists(_btn) && _btn.flex_node != noone) {
             var _pos = flexpanel_node_layout_get_position(_btn.flex_node, false);
             _btn.x = _pos.left;
             _btn.y = _pos.top;
             _btn.image_xscale = _pos.width / sprite_get_width(_btn.sprite_index);
             _btn.image_yscale = _pos.height / sprite_get_height(_btn.sprite_index);
          }
       }
    };

    update_layout();
} else if (ui_mode == "MULTIPLAYER") {
    // Simple multiplayer UI - just reference network manager
    network_manager = noone;
    buttons = [];
}