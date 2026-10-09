view_enabled = true;
view_visible[0] = true;


screen_width = display_get_width();
screen_height = display_get_height();
viewport_x = 0;
viewport_y = 0;
viewport_width = screen_width;
viewport_height = screen_height;

view_xport[0] = viewport_x;
view_yport[0] = viewport_y;
view_wport[0] = viewport_width;
view_hport[0] = viewport_height;

camera_width = viewport_width;
camera_height = viewport_height;

if (instance_number(obj_controller) > 1) {
	var _min_x = 999999;
	var _max_x = -999999;
	with (obj_controller) {
		_min_x = min(_min_x, grid_start_x);
		_max_x = max(_max_x, grid_start_x + grid_width * CELL_SIZE);
	}
	board_center_x = (_min_x + _max_x) / 2;
} else {
	board_center_x = obj_controller.grid_start_x + (obj_controller.grid_width * CELL_SIZE) / 2;
}
board_center_y = GRID_BOTTOM_Y - (GRID_HEIGHT * CELL_SIZE) / 2;



camera_x = board_center_x - (camera_width / 2);
camera_y = board_center_y - (camera_height / 2);

camera = camera_create_view(camera_x, camera_y, camera_width, camera_height, 0, noone, -1, -1, -1, -1);
view_camera[0] = camera;

surface_resize(application_surface, viewport_width, viewport_height);

window_set_rectangle(viewport_x, viewport_y, viewport_width, viewport_height);

target_y = camera_y;
