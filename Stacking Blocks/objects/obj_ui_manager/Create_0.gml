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

// Create button structs with their respective flex panel nodes
button_play = {
    text: "Play",
    x: 0,
    y: 0,
    width: 200,
    height: 50,
    flex_node: flexpanel_create_node({ width: 200, height: 50 })
};

button_options = {
    text: "Options",
    x: 0,
    y: 0,
    width: 200,
    height: 50,
    flex_node: flexpanel_create_node({ width: 200, height: 50 })
};

button_quit = {
    text: "Quit",
    x: 0,
    y: 0,
    width: 200,
    height: 50,
    flex_node: flexpanel_create_node({ width: 200, height: 50 })
};

// Insert the button nodes as children of the root flex panel
flexpanel_node_insert_child(flexpanel_root, button_play.flex_node, 0);
flexpanel_node_insert_child(flexpanel_root, button_options.flex_node, 1);
flexpanel_node_insert_child(flexpanel_root, button_quit.flex_node, 2);

// Calculate initial layout
flexpanel_calculate_layout(flexpanel_root, room_width, room_height);