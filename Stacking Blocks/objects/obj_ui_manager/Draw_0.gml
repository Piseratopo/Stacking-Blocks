// Recalculate layout using the correct root variable name
flexpanel_calculate_layout(flexpanel_root, room_width, room_height);

// Update button positions based on the flexpanel layout calculation
var _pos_play = flexpanel_node_layout_get_position(button_play.flex_node);
button_play.x = _pos_play.left;
button_play.y = _pos_play.top;

var _pos_options = flexpanel_node_layout_get_position(button_options.flex_node);
button_options.x = _pos_options.left;
button_options.y = _pos_options.top;

var _pos_quit = flexpanel_node_layout_get_position(button_quit.flex_node);
button_quit.x = _pos_quit.left;
button_quit.y = _pos_quit.top;

// Draw the UI buttons to the screen
var _buttons = [button_play, button_options, button_quit];

for (var i = 0; i < array_length(_buttons); i++) {
    var _btn = _buttons[i];
    
    // Draw button background
    draw_set_color(c_gray);
    draw_rectangle(_btn.x, _btn.y, _btn.x + _btn.width, _btn.y + _btn.height, false);
    
    // Draw button border
    draw_set_color(c_white);
    draw_rectangle(_btn.x, _btn.y, _btn.x + _btn.width, _btn.y + _btn.height, true);
    
    // Draw button text centered
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_btn.x + (_btn.width / 2), _btn.y + (_btn.height / 2), _btn.text);
}

// Reset text alignments
draw_set_halign(fa_left);
draw_set_valign(fa_top);