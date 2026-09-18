event_inherited();

// Drop

fall_fast = 1;
fall_normal = game_get_speed(gamespeed_fps) div 3 * 2;
fall_delay = fall_normal;
alarm[0] = fall_delay;

// Horizontal movements

move_DAS = game_get_speed(gamespeed_fps) div 3;
//move_ARR = max(1, game_get_speed(gamespeed_fps) div 20);
move_ARR = 1;
move_arr = move_ARR;
move_dir = 0;

is_touching_left = function() {
	return !place_meeting(x - CELL_SIZE, y, obj_border) and bbox_left - CELL_SIZE >= GRID_START_X;
}

is_touching_right = function() {
	return !place_meeting(x + CELL_SIZE, y, obj_border) and bbox_right <= GRID_START_X + (GRID_WIDTH - 1) * CELL_SIZE;
}

// Lock settings

is_locked = false;
dead_sprite_id = [];
lock_delay = fall_delay;
lock_delay_reset = 15;
lock_resets = 0;