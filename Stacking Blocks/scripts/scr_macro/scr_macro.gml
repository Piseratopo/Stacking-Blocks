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
	"O4": {
		display_spr: spr_O4,
		lock_id: [
			[[0, 1],
			[2, 3]]
		],
		offsets: [
			[-32, -32]
		]
	},
	"J4": {
		display_spr: spr_J4,
		lock_id: [
			[[4, GRID_EMPTY, GRID_EMPTY],
			[5, 6, 7]],
			[[8, 7],
			[9, GRID_EMPTY],
			[10, GRID_EMPTY]],
			[[11, 6, 12],
			[GRID_EMPTY, GRID_EMPTY, 10]],
			[[GRID_EMPTY, 4],
			[GRID_EMPTY, 9],
			[11, 13]]
		],
		offsets: [
			[-48, -48],
			[-16, -48],
			[-48, -16],
			[-48, -48]
		]
	}
};