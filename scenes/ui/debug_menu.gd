class_name DebugMenu
extends Control

@onready var weapon_type_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/WeaponTypeOption
@onready var barrel_rarity_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/BarrelRarityOption
@onready var body_rarity_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/BodyRarityOption
@onready var handle_rarity_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/HandleRarityOption
@onready var magazine_rarity_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/MagazineRarityOption
@onready var element_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/ElementOption
@onready var apply_weapon_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/ApplyWeaponButton
@onready var level_spinbox: SpinBox = $Panel/MarginContainer/VBoxContainer/TabContainer/EnemyTab/LevelSpinBox
@onready var spawn_enemy_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/EnemyTab/SpawnEnemyButton
@onready var health_spinbox: SpinBox = $Panel/MarginContainer/VBoxContainer/TabContainer/PlayerTab/HealthSpinBox
@onready var set_health_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/PlayerTab/SetHealthButton
@onready var weapon_level_spinbox: SpinBox = $Panel/MarginContainer/VBoxContainer/TabContainer/WeaponTab/WeaponSpinBox
@onready var modifier1_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/EnemyTab/Modifier1Option
@onready var modifier2_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/EnemyTab/Modifier2Option
@onready var modifier3_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/EnemyTab/Modifier3Option

const EnemyScene = preload("res://scenes/enemies/enemy.tscn")


func _ready() -> void:
	hide()
	print("weapon_type_option: ", weapon_type_option)
	_populate_weapon_options()
	_populate_enemy_options()
	_setup_enemy_tab()
	_setup_player_tab()

func _populate_weapon_options() -> void:
	for type in Enums.WeaponType.keys():
		weapon_type_option.add_item(type)
	
	for rarity in Enums.Rarity.keys():
		barrel_rarity_option.add_item(rarity)
		body_rarity_option.add_item(rarity)
		handle_rarity_option.add_item(rarity)
		magazine_rarity_option.add_item(rarity)
	
	element_option.add_item("NONE")
	element_option.add_item("FIRE")
	element_option.add_item("FREEZE")
	element_option.add_item("CORRUPT")
	element_option.add_item("BLEED")
	element_option.add_item("SHOCK")
	element_option.add_item("INFECTED")
	element_option.add_item("DUUMITE")
	
	apply_weapon_button.pressed.connect(_on_apply_weapon_pressed)

func _on_apply_weapon_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var weapon_type = weapon_type_option.selected as Enums.WeaponType
	var barrel_rarity = barrel_rarity_option.selected as Enums.Rarity
	var body_rarity = body_rarity_option.selected as Enums.Rarity
	var handle_rarity = handle_rarity_option.selected as Enums.Rarity
	var magazine_rarity = magazine_rarity_option.selected as Enums.Rarity
	
	var weapon_data = _create_debug_weapon(weapon_type, barrel_rarity, body_rarity, handle_rarity, magazine_rarity)
	
	weapon_data.level = int(weapon_level_spinbox.value)
	weapon_data.calculate_stats()
	
	var element_index = element_option.selected
	if element_index > 0:
		weapon_data.override_element = element_index - 1  # -1 because index 0 is "NONE"
	else:
		weapon_data.override_element = -1
	player.current_weapon.setup(weapon_data)
	print("debug weapon equipped: ", weapon_data.get_display_name())

func _create_debug_weapon(weapon_type: Enums.WeaponType, barrel: Enums.Rarity, body: Enums.Rarity, handle: Enums.Rarity, magazine: Enums.Rarity) -> WeaponInstanceData:
	var weapon = WeaponInstanceData.new()
	weapon.base = WeaponFactory.weapon_bases[weapon_type]
	weapon.manufacturer = ManufacturerData.roll_manufacturer()
	weapon.weapon_name = ManufacturerData.get_weapon_name(weapon.manufacturer, weapon_type)
	
	if weapon_type == Enums.WeaponType.WAND:
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.RUNE, barrel))
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.STAFF, body))
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.GEM, handle))
	else:
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.BARREL, barrel))
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.BODY, body))
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.HANDLE, handle))
		weapon.parts.append(WeaponFactory.get_part(weapon_type, Enums.PartType.MAGAZINE, magazine))
	
	weapon.calculate_stats()
	return weapon

func _populate_enemy_options() -> void:
	modifier1_option.add_item("NONE")
	modifier2_option.add_item("NONE")
	modifier3_option.add_item("NONE")
	
	for modifier_name in Enums.EnemyModifier.keys():
		modifier1_option.add_item(modifier_name)
		modifier2_option.add_item(modifier_name)
		modifier3_option.add_item(modifier_name)
	
	spawn_enemy_button.pressed.connect(_on_spawn_enemy_pressed)

func _setup_enemy_tab():
	spawn_enemy_button.pressed.connect(_on_spawn_enemy_pressed)

func _on_spawn_enemy_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var enemy = EnemyScene.instantiate()
	enemy.skip_random_modifiers = true

	if modifier1_option.selected > 0:
		var mod = (modifier1_option.selected - 1) as Enums.EnemyModifier
		enemy.modifiers.append(mod)
	if modifier2_option.selected > 0:
		var mod = (modifier2_option.selected - 1) as Enums.EnemyModifier
		enemy.modifiers.append(mod)
	if modifier3_option.selected > 0:
		var mod = (modifier3_option.selected - 1) as Enums.EnemyModifier
		enemy.modifiers.append(mod)
	
	enemy.level = int(level_spinbox.value)
	
	var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	
	get_tree().root.add_child(enemy)
	enemy.global_position = player.global_position + offset

func _setup_player_tab():
	set_health_button.pressed.connect(_on_set_health_pressed)

func _on_set_health_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.current_health = int(health_spinbox.value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		visible = !visible
		get_tree().paused = visible

func _on_close_button_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_button_pressed() -> void:
	pass # Replace with function body.
