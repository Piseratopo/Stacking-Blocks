// Horizontal-movement timer

if (is_locked) {
   exit;
}

if (move_dir == -1 && ! get_key_move_left()) {
   move_dir = 0;
}
else if (move_dir == 1 && ! get_key_move_right()) {
   move_dir = 0;
}

if (move_dir != 0) {
   var _moved = false;

   if (move_ARR == 0) {
      if (move_dir == -1) {
         _moved = shift_leftmost();
      }
      else if (move_dir == 1) {
         _moved = shift_rightmost();
      }
      alarm[1] = 1;
   }
   else {
      var _can_move = (move_dir == -1)?is_touching_left(): is_touching_right();
      if (_can_move) {
         x += move_dir * CELL_SIZE;
         _moved = true;
      }
      alarm[1] = move_ARR;
   }

   if (_moved) {
      // Reset lock timer on horizontal move while grounded
      if (place_meeting(x, y + CELL_SIZE, obj_border) && lock_resets < lock_delay_reset) {
         alarm[2] = lock_delay;
         lock_resets += 1;
      }
   }
}