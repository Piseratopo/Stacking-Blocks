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

block_lock_sprite_map = {
	"I,I,I,I": 0,  "C,I,I,I": 1,  "I,C,I,I": 2,  "C,C,I,I": 3,
   "I,I,I,C": 4,  "C,I,I,C": 5,  "I,C,I,C": 6,  "C,C,I,C": 7,
   "I,I,C,I": 8,  "C,I,C,I": 9,  "I,C,C,I": 10, "C,C,C,I": 11,
   "I,I,C,C": 12, "C,I,C,C": 13, "I,C,C,C": 14, "C,C,C,C": 15,
   "V,I,V,I": 16, "V,C,V,I": 17, "V,I,V,C": 18, "V,C,V,C": 19,
   "H,H,I,I": 20, "H,H,I,C": 21, "H,H,C,I": 22, "H,H,C,C": 23,
   "I,V,I,V": 24, "I,V,C,V": 25, "C,V,I,V": 26, "C,V,C,V": 27,
   "I,I,H,H": 28, "C,I,H,H": 29, "I,C,H,H": 30, "C,C,H,H": 31,
   "V,V,V,V": 32, "H,H,H,H": 33, "O,H,V,I": 34, "O,H,V,C": 35,
   "H,O,I,V": 36, "H,O,C,V": 37, "I,V,H,O": 38, "C,V,H,O": 39,
   "V,I,O,H": 40, "V,C,O,H": 41, "O,O,V,V": 42, "O,H,O,H": 43,
   "V,V,O,O": 44, "H,O,H,O": 45, "O,O,O,O": 46
};
