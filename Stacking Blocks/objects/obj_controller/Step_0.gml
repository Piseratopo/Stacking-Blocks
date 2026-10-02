// Spawn shape if none exists
if (!instance_exists(obj_shape)) {
	var _chosen_key = next_shape_name;
	next_shape_name = get_random_shape();
	
	var _spawn_y = get_spawn_y();
	var _shape_props = global.shape_properties;
	var _inst = instance_create_layer(SHAPE_SPAWN_X, _spawn_y, "Blocks", obj_shape, {
		shape_name: _chosen_key,
		shape_data: _shape_props[$ _chosen_key],
		sprite_index: _shape_props[$ _chosen_key].display_spr,
		lock_spr: _shape_props[$ _chosen_key].lock_spr,
		orientation: 0,
		image_angle: 0,
		image_speed: 0,
	});
	
	with (obj_camera) {
		target_y = _spawn_y + 10 * CELL_SIZE - camera_height / 2;
	}
}

if (finished_locking_shape) {
	with (obj_block) {
		if (is_locked) {
			set_block_lock_sprite();
		}
	}
	finished_locking_shape = false;
}