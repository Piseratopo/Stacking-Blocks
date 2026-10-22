menu_state = "MAIN"; // "MAIN" or "PLAY_SELECT"

button_width = 320;
button_height = 64;
button_flex_style = {
	width: button_width,
	height: button_height,
};

buttons = [];

init_root = function() {
	if (flexpanel_root != noone && flexpanel_root != undefined) {
	   flexpanel_delete_node(flexpanel_root, true);
	   flexpanel_root = noone;
	}
	flexpanel_root = flexpanel_create_node({
	   width: room_width,
	   height: room_height,
	   flexDirection: "column",
	   justifyContent: "center",
	   alignItems: "center",
	   gap: 20,
	   padding: 40
	});
};

create_button = function(_name, _label, _style, _action = undefined) {
	var _node = flexpanel_create_node(_style);
	var _btn = instance_create_layer(0, 0, layer, obj_button, {
	   name: _name,
	   label: _label,
	   flex_node: _node
	});
	_btn.flex_node = _node;
	if (!is_undefined(_action) && is_callable(_action)) {
	   _btn.action = _action;
	}
	return _btn;
};

clear_menu = function() {
	for (var i = 0; i < array_length(buttons); i++) {
	   if (instance_exists(buttons[i])) {
	      instance_destroy(buttons[i]);
	   }
	}
	buttons = [];
};

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

show_main_menu = function() {
	clear_menu();
	init_root();
	menu_state = "MAIN";

	button_play = create_button("play", "Play", button_flex_style, function() {
	   show_play_mode_menu();
	});
	button_options = create_button("options", "Options", button_flex_style);
	button_quit = create_button("quit", "Quit", button_flex_style);

	buttons = [button_play, button_options, button_quit];

	for (var i = 0; i < array_length(buttons); i++) {
	   flexpanel_node_insert_child(flexpanel_root, buttons[i].flex_node, i);
	}

	update_layout();
};

show_play_mode_menu = function() {
	clear_menu();
	init_root();
	menu_state = "PLAY_SELECT";

	button_singleplayer = create_button("singleplayer", "Singleplayer", button_flex_style, function() {
	   room_goto(rm_singleplayer);
	});
	button_multiplayer = create_button("multiplayer", "Multiplayer", button_flex_style, function() {
	   room_goto(rm_multiplayer);
	});
	button_back = create_button("back", "Back", button_flex_style, function() {
	   show_main_menu();
	});

	buttons = [button_singleplayer, button_multiplayer, button_back];

	for (var i = 0; i < array_length(buttons); i++) {
	   flexpanel_node_insert_child(flexpanel_root, buttons[i].flex_node, i);
	}

	update_layout();
};

show_main_menu();