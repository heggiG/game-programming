extends CharacterBody2D


var movement_speed = 40.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var iceSpear = preload("res://Player/Attack/ice_spear.tscn")
var tornado = preload("res://Player/Attack/tornado.tscn")
var javelin = preload("res://Player/Attack/javelin.tscn")
var golem = preload("res://Player/Attack/golem.tscn")
var arrow = preload("res://Player/Attack/arrow.tscn")

#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var arrowTimer = get_node("%ArrowTimer")
@onready var arrowAttackTimer = get_node("%ArrowAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var javelinBase = get_node("%JavelinBase")
@onready var golemTimer = get_node("%GolemTimer")
@onready var golemAttackTimer = get_node("%GolemAttackTimer")

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#IceSpear
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attackspeed = 1.5
var icespear_level = 0

#Arrow
var arrow_ammo = 0
var arrow_baseammo = 0
var arrow_attackspeed = 0.8
var arrow_level = 0

#Golem
var golem_ammo = 0
var golem_baseammo = 0
var golem_attackspeed = 5.0
var golem_level = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3.0
var tornado_level = 0

#Javelin
var javelin_ammo = 0
var javelin_level = 0


#Enemy Related
var enemy_close = []

# Movement Tracker
var tracking = false
@onready var trackingTimer = $trackingTimer
@onready var trackingCooldown = $trackingCooldown
var trackingButtonEnabled = true
var trackingOnCooldown = false
var trackedPoints = []
var time_start
var time_end
var previous_speed
@onready var moveSpeedTimer = $movSpeedBuffTimer
@onready var trackingCooldownBar = $GUILayer/GUI/TrackingCooldownBar

@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

#Signal
signal playerdeath

func _ready():
	upgrade_character("icespear1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)

func _physics_process(_delta):
	movement()
	trackingCooldownBar.value = trackingCooldown.time_left
	

func movement():
	var current_sprite = sprite
	if (Input.get_action_strength("start-elemental-attack") > 0 && trackingButtonEnabled && !trackingOnCooldown):
		if !tracking: # first press
			time_start = Time.get_ticks_msec()
			sprite.material.set_shader_parameter("turned_on", true)
		
		trackingButtonEnabled = false
		tracking = !tracking # switch tracking state
		
		trackingTimer.start()
		if !tracking: # second press
			sprite.material.set_shader_parameter("turned_on", false)
			trackingOnCooldown = true
			trackingCooldown.start()
			time_end = Time.get_ticks_msec()
			find_elemental_attack()
			trackedPoints = []
	
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	if mov.x > 0:
		current_sprite.flip_h = true
	elif mov.x < 0:
		current_sprite.flip_h = false
	
	if tracking:
		if last_movement != mov.normalized() && mov.normalized() != Vector2.ZERO:
			trackedPoints.append(mov.normalized())
	
	if mov != Vector2.ZERO:
		last_movement = mov
		if walkTimer.is_stopped():
			if current_sprite.frame >= current_sprite.hframes - 1:
				current_sprite.frame = 0
			else:
				current_sprite.frame += 1
			walkTimer.start()
	
	velocity = mov.normalized()*movement_speed
	move_and_slide()

func find_elemental_attack():
	var strength = ((time_end - time_start) / 4000) # time passed in seconds divided by 4
	var filtered_points = trackedPoints.filter(filter_array);
	if [Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0)] == filtered_points: # ice attack
		get_tree().call_group("enemies", "global_attack", 0, strength)
		print_debug("Elemental1")
	elif [Vector2(-1.0, 0.0), Vector2(0.0, -1.0), Vector2(1.0, 0.0)] == filtered_points: # confusion attack
		get_tree().call_group("enemies", "global_attack", 1, strength)
		print_debug("Elemental2")
	elif [Vector2(0.0, -1.0), Vector2(0.0, 1.0), Vector2(0.0, -1.0)] == filtered_points: # flat damage attack
		get_tree().call_group("enemies", "global_attack", 2, strength)
		print_debug("Elemental3")
	elif [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)] == filtered_points:
		print_debug("Elemental4")
		previous_speed = movement_speed
		movement_speed = movement_speed * clampf(strength, 1.2, 20000.0)
		moveSpeedTimer.start()
	pass

func filter_array(vec: Vector2):
	return vec.length() == 1.0

func attack():
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed * (1-spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()
	if golem_level > 0:
		golemTimer.wait_time = golem_attackspeed * (1-spell_cooldown)
		if golemTimer.is_stopped():
			golemTimer.start()
	if arrow_level > 0:
		arrowTimer.wait_time = arrow_attackspeed * (1-spell_cooldown)
		if arrowTimer.is_stopped():
			arrowTimer.start()


func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()

func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()

func _on_arrow_timer_timeout():
	arrow_ammo += arrow_baseammo + additional_attacks
	arrowAttackTimer.start()

func _on_arrow_attack_timer_timeout():
	if arrow_ammo > 0:
		var arrow_attack = arrow.instantiate()
		arrow_attack.position = position
		arrow_attack.target = get_random_target()
		arrow_attack.level = arrow_level
		add_child(arrow_attack)
		arrow_ammo -= 1
		if arrow_ammo > 0:
			arrowAttackTimer.start()
		else:
			arrowAttackTimer.stop()

func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func _on_golem_timer_timeout():
	golem_ammo += golem_baseammo + additional_attacks
	golemAttackTimer.start()

func _on_golem_attack_timer_timeout():
	if golem_ammo > 0:
		var golem_attack = golem.instantiate()
		golem_attack.position = position
		##golem_attack.target = get_random_target()
		golem_attack.last_movement = last_movement
		golem_attack.level = golem_level
		add_child(golem_attack)
		golem_ammo -= 1
		if golem_ammo > 0:
			golemAttackTimer.start()
		else:
			golemAttackTimer.stop()

func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	#Upgrade Javelin
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)


func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap = 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
		
	return exp_cap
		
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ",experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position",Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"arrow1":
			arrow_level = 1
			arrow_baseammo += 1
		"arrow2":
			arrow_level = 2
			arrow_baseammo += 2
		"arrow3":
			arrow_level = 3
			arrow_baseammo += 2
		"arrow4":
			arrow_level = 4
			arrow_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"mage":
			spell_cooldown += 0.10
			spell_size += 0.10
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
		"golem":
			golem_level = 1
			golem_baseammo += 1
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequisites
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()


func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")


func _on_tracking_timer_timeout():
	trackingButtonEnabled = true

func _on_tracking_cooldown_timeout():
	trackingOnCooldown = false


func _on_mov_speed_buff_timer_timeout():
	movement_speed = previous_speed
