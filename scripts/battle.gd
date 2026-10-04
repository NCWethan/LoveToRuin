extends Node2D
## Runs a battle: spawns the enemy's attacks and keeps track of the player's HP.

## The player's maximum HP.
@export var max_hp: int = 20
## How often a new bullet appears, in seconds.
@export var spawn_interval: float = 0.35
## How fast bullets fly, in pixels per second.
@export var bullet_speed: float = 110.0
## After getting hit, how long the SOUL can't be hurt again, in seconds.
@export var invincibility_time: float = 1.0

var hp: int

var _spawn_timer: float = 0.0
var _invincible_timer: float = 0.0
var _hp_label: Label

@onready var soul: Sprite2D = $Soul
@onready var box: BattleBox = $BattleBox


func _ready() -> void:
	# Battles happen on a black background, like in Undertale and Deltarune.
	RenderingServer.set_default_clear_color(Color.BLACK)

	hp = max_hp

	# Show the HP just below the box.
	_hp_label = Label.new()
	var area := box.get_inner_rect()
	_hp_label.position = Vector2(area.position.x, area.end.y + box.border + 8)
	add_child(_hp_label)
	_update_hp_label()


func _process(delta: float) -> void:
	# Spawn a new bullet every spawn_interval seconds.
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_spawn_bullet()

	if _invincible_timer > 0.0:
		# Just got hit: make the SOUL blink until the invincibility wears off.
		_invincible_timer -= delta
		soul.visible = _invincible_timer <= 0.0 or fmod(_invincible_timer, 0.2) > 0.1
	else:
		_check_hits()


## Creates a bullet on the left or right edge of the box, flying across it.
func _spawn_bullet() -> void:
	var area := box.get_inner_rect()
	var bullet := Bullet.new()
	var y := randf_range(area.position.y + 4, area.end.y - 4)

	if randf() < 0.5:
		bullet.position = Vector2(area.position.x + 3, y)
		bullet.velocity = Vector2(bullet_speed, 0)
	else:
		bullet.position = Vector2(area.end.x - 3, y)
		bullet.velocity = Vector2(-bullet_speed, 0)

	bullet.bounds = area
	add_child(bullet)


## Checks whether any bullet is touching the SOUL.
func _check_hits() -> void:
	# The SOUL's hitbox is smaller than the heart picture, so close
	# dodges feel fair (Undertale does the same thing).
	var soul_hitbox := Rect2(soul.global_position - Vector2(4, 4), Vector2(8, 8))

	for child in get_children():
		var bullet := child as Bullet
		if bullet and bullet.get_hitbox().intersects(soul_hitbox):
			_take_damage(bullet.damage)
			bullet.queue_free()
			return


func _take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	_invincible_timer = invincibility_time
	_update_hp_label()

	if hp == 0:
		# No GAME OVER screen yet, so just start the battle over.
		get_tree().reload_current_scene.call_deferred()


func _update_hp_label() -> void:
	_hp_label.text = "HP  %d / %d" % [hp, max_hp]
