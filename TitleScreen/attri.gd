extends Control

var menu_level = "res://TitleScreen/menu.tscn"

func _on_btn_returnmenu_click_end():
	var _level = get_tree().change_scene_to_file(menu_level)
