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

board_center_x = GRID_START_X + (GRID_WIDTH * CELL_SIZE) / 2;
board_center_y = GRID_BOTTOM_Y - (GRID_HEIGHT * CELL_SIZE) / 2;

camera_x = board_center_x - (camera_width / 2);
camera_y = board_center_y - (camera_height / 2);

camera = camera_create_view(camera_x, camera_y, camera_width, camera_height, 0, noone, -1, -1, -1, -1);
view_camera[0] = camera;

surface_resize(application_surface, viewport_width, viewport_height);

window_set_rectangle(viewport_x, viewport_y, viewport_width, viewport_height);
