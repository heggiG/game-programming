extends Area2D

var level = 1
var hp = 50
var speed = 10.0
var damage = 15
var knockback_amount = 150
var attack_size = 1.2
## var attack_speed = 5.0 ##lower number is faster
#var target = Vector2.ZERO
#var angle = Vector2.ZERO

var last_movement = Vector2.ZERO
var angle = Vector2.ZERO
var angle_less = Vector2.ZERO
var angle_more = Vector2.ZERO

var spr_golem = preload("res://Textures/Items/Weapons/golem.png")

signal remove_from_array(object)

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	match level:
		1:
			hp = 5
			speed = 10.0
			damage = 15
			knockback_amount = 150
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			hp = 7
			speed = 20.0
			damage = 15
			knockback_amount = 140
			attack_size = 1.0 * (1 + player.spell_size)
		3:
			hp = 10
			speed = 30.0
			damage = 15
			knockback_amount = 130
			attack_size = 1.0 * (1 + player.spell_size)
		4:
			hp = 15
			speed = 50.0
			damage = 25
			knockback_amount = 125
			attack_size = 1.0 * (1 + player.spell_size)
			
	var move_to_less = Vector2.ZERO
	var move_to_more = Vector2.ZERO
	match last_movement:
		Vector2.UP, Vector2.DOWN:
			move_to_less = global_position + Vector2(randf_range(-1,-0.25), last_movement.y)*500
			move_to_more = global_position + Vector2(randf_range(0.25,1), last_movement.y)*500
		Vector2.RIGHT, Vector2.LEFT:
			move_to_less = global_position + Vector2(last_movement.x, randf_range(-1,-0.25))*500
			move_to_more = global_position + Vector2(last_movement.x, randf_range(0.25,1))*500
		Vector2(1,1), Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1):
			move_to_less = global_position + Vector2(last_movement.x, last_movement.y * randf_range(0,0.75))*500
			move_to_more = global_position + Vector2(last_movement.x * randf_range(0,0.75), last_movement.y)*500
	
	angle_less = global_position.direction_to(move_to_less)
	angle_more = global_position.direction_to(move_to_more)
	
	var initital_tween = create_tween().set_parallel(true)
	initital_tween.tween_property(self,"scale",Vector2(1,1)*attack_size,3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var final_speed = speed
	speed = speed/5.0
	initital_tween.tween_property(self,"speed",final_speed,6).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	initital_tween.play()
	
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1,1)*attack_size,1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()

func _physics_process(delta):
	position += angle*speed*delta
	
	
func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array",self)
		queue_free()

func _on_timer_timeout():
	emit_signal("remove_from_array",self)
	queue_free()
	

