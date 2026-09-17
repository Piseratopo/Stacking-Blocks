/// @function grid_x_to_col(_x)
/// @description Converts room x coordinate to grid column (0-indexed)
function grid_x_to_col(_x) {
	return round((_x - GRID_START_X) / CELL_SIZE);
}

/// @function grid_y_to_row(_y)
/// @description Converts room y coordinate to grid row from bottom to top (row 0 = bottom row at GRID_BOTTOM_Y)
function grid_y_to_row(_y) {
	return round((GRID_BOTTOM_Y - _y) / CELL_SIZE);
}

/// @function grid_col_to_x(_col)
/// @description Converts grid column to room x coordinate
function grid_col_to_x(_col) {
	return GRID_START_X + _col * CELL_SIZE;
}

/// @function grid_row_to_y(_row)
/// @description Converts grid row (bottom-to-top) to room y coordinate
function grid_row_to_y(_row) {
	return GRID_BOTTOM_Y - _row * CELL_SIZE;
}

/// @function grid_create_row(_len)
/// @description Creates a new empty row array of length _len (default GRID_WIDTH) filled with GRID_EMPTY
function grid_create_row(_len = GRID_WIDTH) {
	return array_create(_len, GRID_EMPTY);
}