#macro GRID_OFFSET sprite_get_width(spr_blocks)
#macro CELL_SIZE sprite_get_width(spr_blocks)

#macro SHAPE_SPAWN_X 320
#macro SHAPE_SPAWN_Y 0

#macro GRID_WIDTH 10
#macro GRID_HEIGHT 20
#macro GRID_START_X 160
#macro GRID_BOTTOM_Y 672
#macro GRID_EMPTY -1

#macro ROTATION_CW 1
#macro ROTATION_CCW -1
#macro ROTATION_180 2

shape_properties = {
	"J4": {
		display_spr: spr_J4,
		lock_id: spr_lock_J4,
		offsets: [
			[-48, -48],
			[-16, -48],
			[-48, -16],
			[-48, -48]
		]
	},
	"L4": {
		display_spr: spr_L4,
		lock_spr: spr_lock_L4,
	},
	"O4": {
		display_spr: spr_O4,
		lock_spr: spr_lock_O4,
		offsets: [
			[-32, -32]
		]
	},
};