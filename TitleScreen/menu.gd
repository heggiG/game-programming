extends Control

var level_world = "res://World/world.tscn"
var attr_level = "res://TitleScreen/attri.tscn"


func _on_btn_play_click_end():
	var _level = get_tree().change_scene_to_file(level_world)

func _on_btn_exit_click_end():
	get_tree().quit()

func _on_btn_attributions_click_end():
	var _level = get_tree().change_scene_to_file(attr_level)
