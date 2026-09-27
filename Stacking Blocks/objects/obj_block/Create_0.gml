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

dead_sprite_id = [];
lock_delay = fall_delay;
lock_delay_reset = 15;
lock_resets = 0;

// Art and style

set_block_lock_sprite = function() {
	var check_block = function(_dx, _dy) {
		var _inst = instance_place(x + _dx, y + _dy, obj_block);
		if (_inst != noone && _inst.is_locked) {
			return not (_inst.block_name == self.block_name);
		}
		return true;
	};

	
	var _nw = check_block(-CELL_SIZE, -CELL_SIZE);
   var _n  = check_block(0, -CELL_SIZE);
   var _ne = check_block(CELL_SIZE, -CELL_SIZE);
   var _w  = check_block(-CELL_SIZE, 0);
   var _e  = check_block(CELL_SIZE, 0);
   var _sw = check_block(-CELL_SIZE, CELL_SIZE);
   var _s  = check_block(0, CELL_SIZE);
   var _se = check_block(CELL_SIZE, CELL_SIZE);
	
	show_debug_message($"{_nw} {_n} {_ne} {_w} {_e} {_sw} {_s} {_se}");
	
	var get_quad = function(_horz, _vert, _corner) {
      if (_vert && _horz) return "O";             // Outer Corner
      if (_vert && !_horz) return "V";              // Vertical Edge
      if (!_vert && _horz) return "H";              // Horizontal Edge
      if (!_vert && !_horz && _corner) return "C";   // Inner Corner
      return "I";                                   // Fully Inside
   };
    
   var _tl = get_quad(_n, _w, _nw);
   var _tr = get_quad(_n, _e, _ne);
   var _bl = get_quad(_s, _w, _sw);
   var _br = get_quad(_s, _e, _se);
   
   var _key = _tl + "," + _tr + "," + _bl + "," + _br;
   show_debug_message(_key);
	
	image_index = global.block_lock_sprite_map[$ _key];
}
