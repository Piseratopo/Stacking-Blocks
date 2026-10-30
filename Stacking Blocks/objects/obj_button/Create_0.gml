if (!variable_instance_exists(id, "flex_node") || flex_node == undefined) {
   flex_node = noone;
}

if (!variable_instance_exists(id, "icon_sprite") || icon_sprite == undefined) {
   icon_sprite = (name == "back") ? spr_back_symbol : noone;
} else if (icon_sprite == noone && name == "back") {
   icon_sprite = spr_back_symbol;
}

if (!variable_instance_exists(id, "use_gui") || use_gui == undefined) {
   use_gui = false;
}

if (flex_node != noone) {
   var _pos = flexpanel_node_layout_get_position(flex_node, false);
   if (_pos.width > 0 && _pos.height > 0) {
      x = _pos.left;
      y = _pos.top;
      image_xscale = _pos.width / sprite_get_width(sprite_index);
      image_yscale = _pos.height / sprite_get_height(sprite_index);
   }
}

on_click = function() {
   switch (name) {
      case "play":
         if (instance_exists(obj_ui_manager)) {
            obj_ui_manager.show_play_mode_menu();
         }
         break;
      case "singleplayer":
         room_goto(rm_singleplayer);
         break;
      case "multiplayer":
         room_goto(rm_multiplayer);
         break;
      case "back":
         if (room != rm_menu) {
            room_goto(rm_menu);
         } else if (instance_exists(obj_ui_manager)) {
            obj_ui_manager.show_main_menu();
         }
         break;
      case "options":
         // TODO: Implement options menu
         break;
      case "quit":
         game_end();
         break;
   }
};

draw_button_self = function() {
   var _btn_color = is_hovered ? c_yellow : c_white;

   image_blend = _btn_color;
   draw_self();

   var _has_icon = (variable_instance_exists(id, "icon_sprite") && icon_sprite != noone && sprite_exists(icon_sprite));
   var _has_label = (variable_instance_exists(id, "label") && string_length(label) > 0);

   if (_has_icon) {
      var _icon_w = sprite_get_width(icon_sprite);
      var _icon_h = sprite_get_height(icon_sprite);

      if (_has_label) {
         draw_set_font(fnt_text);
         var _text_w = string_width(label);
         var _spacing = 8;
         var _total_w = _icon_w + _spacing + _text_w;
         var _start_x = x + (sprite_width - _total_w) / 2;

         draw_sprite_ext(icon_sprite, 0, _start_x, y + (sprite_height - _icon_h) / 2, 1, 1, 0, _btn_color, 1);

         draw_set_halign(fa_left);
         draw_set_valign(fa_middle);
         draw_set_colour(_btn_color);
         draw_text(_start_x + _icon_w + _spacing, y + sprite_height / 2, label);
         draw_set_halign(fa_left);
         draw_set_valign(fa_top);
      } else {
         var _icon_x = x + (sprite_width - _icon_w) / 2;
         var _icon_y = y + (sprite_height - _icon_h) / 2;
         draw_sprite_ext(icon_sprite, 0, _icon_x, _icon_y, 1, 1, 0, _btn_color, 1);
      }
   } else if (_has_label) {
      draw_set_halign(fa_center);
      draw_set_valign(fa_middle);
      draw_set_font(fnt_text);
      draw_set_colour(_btn_color);
      draw_text(x + sprite_width / 2, y + sprite_height / 2, label);
      draw_set_halign(fa_left);
      draw_set_valign(fa_top);
   }
};
