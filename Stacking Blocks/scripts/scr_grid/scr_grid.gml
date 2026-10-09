function grid_x_to_col(_x, _start_x = GRID_START_X) {
	return round((_x - _start_x) / CELL_SIZE);
}

function grid_y_to_row(_y, _bottom_y = GRID_BOTTOM_Y) {
	return round((_bottom_y - _y) / CELL_SIZE);
}

function grid_col_to_x(_col, _start_x = GRID_START_X) {
	return _start_x + _col * CELL_SIZE;
}

function grid_row_to_y(_row, _bottom_y = GRID_BOTTOM_Y) {
	return _bottom_y - _row * CELL_SIZE;
}

function grid_create_row(_len = GRID_WIDTH) {
	return array_create(_len, GRID_EMPTY);
}