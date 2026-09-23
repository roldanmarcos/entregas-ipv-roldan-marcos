extends StaticBody2D

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var body_anim: AnimatedSprite2D = $Body

@export var projectile_scene: PackedScene

var target: Node2D
var projectile_container: Node
var dead: bool = false


func _ready() -> void:
	fire_timer.timeout.connect(fire)
	set_physics_process(false)
	_play_animation("idle")

func initialize(turret_pos: Vector2, projectile_container: Node) -> void:
	global_position = turret_pos
	self.projectile_container = projectile_container


func fire() -> void:
	if target != null:
		var proj_instance: Node = projectile_scene.instantiate()
		if projectile_container == null:
			projectile_container = get_parent()
		projectile_container.add_child(proj_instance)
		proj_instance.initialize(
			fire_position.global_position,
			fire_position.global_position.direction_to(target.global_position)
		)
		fire_timer.start()
		_play_animation("attack")


func _physics_process(delta: float) -> void:
	raycast.set_target_position(raycast.to_local(target.global_position))
	if raycast.is_colliding() && raycast.get_collider() == target:
		if fire_timer.is_stopped():
			fire_timer.start()
	elif !fire_timer.is_stopped():
		fire_timer.stop()

func notify_hit() -> void:
	print("I'm turret and imma die")
	dead = true
	target = null
	set_physics_process(false)
	fire_timer.stop()
	collision_layer = 0
	if target != null:
		_play_animation("die_alert")
	else:
		_play_animation("die")

func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if target == null && !dead:
		target = body
		set_physics_process(true)

		_play_animation("alert")


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target && !dead:
		target = null
		set_physics_process(false)
		fire_timer.stop()
		
		_play_animation("go_normal")

func _on_animation_finished() -> void:
	match body_anim.animation:
		"alert":
			_play_animation("idle_alert")
		"go_normal":
			_play_animation("idle")
		"fire", "attack":
			_play_animation("alert")
		"die", "die_alert":
			call_deferred("_remove")

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
