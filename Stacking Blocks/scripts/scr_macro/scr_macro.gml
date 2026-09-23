#macro GRID_OFFSET sprite_get_width(spr_lock_I)
#macro CELL_SIZE sprite_get_width(spr_lock_I)
#macro NUM_ORIENTATIONS 4

#macro SHAPE_SPAWN_X 320
#macro SHAPE_SPAWN_Y 0

#macro GRID_WIDTH 10
#macro GRID_HEIGHT 20
#macro GRID_START_X 160
#macro GRID_BOTTOM_Y 672
#macro GRID_EMPTY -1

#macro ROTATION_CW 1
#macro ROTATION_CCW 3
#macro ROTATION_180 2

shape_properties = {
	"I": {
		display_spr: spr_I,
		lock_spr: spr_lock_I,
	},
	"J": {
		display_spr: spr_J,
		lock_spr: spr_lock_J,
	},
	"L": {
		display_spr: spr_L,
		lock_spr: spr_lock_L,
	},
	"O": {
		display_spr: spr_O,
		lock_spr: spr_lock_O,
	},
   "S": {
      display_spr: spr_S,
      lock_spr: spr_lock_S,
   },
   "T": {
      display_spr: spr_T,
      lock_spr: spr_lock_T,
   },
   "Z": {
      display_spr: spr_Z,
      lock_spr: spr_lock_Z,
   }
};