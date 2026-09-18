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
y_check_pos = GRID_BOTTOM_Y - 100;

place_meeting_border = function(_x, _y) {
	return place_meeting(_x, y_check_pos, obj_border) or place_meeting(_x, _y, obj_border);
}

// Lock settings

is_locked = false;
dead_sprite_id = [];
lock_delay = fall_delay;
lock_delay_reset = 15;
lock_resets = 0;