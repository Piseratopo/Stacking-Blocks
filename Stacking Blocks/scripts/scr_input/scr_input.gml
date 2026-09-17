function get_key_move_right() {
	return keyboard_check(vk_right);
}

function get_key_move_right_pressed() {
	return keyboard_check_pressed(vk_right);
}

function get_key_move_left() {
	return keyboard_check(vk_left);
}

function get_key_move_left_pressed() {
	return keyboard_check_pressed(vk_left);
}

function get_key_soft_drop() {
	return keyboard_check(vk_down);
}

function get_key_hard_drop() {
	return keyboard_check(vk_space);
}

function get_key_rotate_cw_pressed() {
	return keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("X")) || keyboard_check_pressed(ord("E"));
}

function get_key_rotate_ccw_pressed() {
	return keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_control) || keyboard_check_pressed(ord("Q"));
}

function get_key_rotate_180_pressed() {
	return keyboard_check_pressed(ord("A")) || keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_shift);
}

