function grid_x_to_col(_x) {
	return round((_x - GRID_START_X) / CELL_SIZE);
}

function grid_y_to_row(_y) {
	return round((GRID_BOTTOM_Y - _y) / CELL_SIZE);
}

function grid_col_to_x(_col) {
	return GRID_START_X + _col * CELL_SIZE;
}

function grid_row_to_y(_row) {
	return GRID_BOTTOM_Y - _row * CELL_SIZE;
}

function grid_create_row(_len = GRID_WIDTH) {
	return array_create(_len, GRID_EMPTY);
}