// Draw garbage queue visualization
var _pending = board_owner.pending_garbage;

var _queue_height = min(_pending, board_owner.grid_height);
var _cell_size = board_owner.cell_size;
var _bottom_y = board_owner.grid_bottom_y;

// Draw gray garbage block
draw_rectangle_colour(
	x,	_bottom_y, x + _cell_size, _bottom_y - _queue_height * _cell_size,
	c_ltgray, c_ltgray, c_gray, c_gray,
	false
);

// Draw the wall border
draw_self();
