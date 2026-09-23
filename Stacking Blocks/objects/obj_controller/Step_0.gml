// Spawn shape if none exists
if (!instance_exists(obj_shape)) {
	var _shape_props = global.shape_properties;
	var _keys = struct_get_names(_shape_props);
	var _chosen_key = _keys[irandom(array_length(_keys) - 1)];
	var _inst = instance_create_layer(SHAPE_SPAWN_X, SHAPE_SPAWN_Y, "Blocks", obj_shape, {
		shape_name: _chosen_key,
		shape_data: _shape_props[$ _chosen_key],
		sprite_index: _shape_props[$ _chosen_key].display_spr,
      lock_spr: _shape_props[$ _chosen_key].lock_spr,
		orientation: 0,
		image_angle: 0,
		image_speed: 0,
	});
}

