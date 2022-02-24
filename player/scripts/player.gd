extends KinematicBody

#base player stats
export var health = 100
export var magick = 100

#vectors sort of speak for themselves
var direction = Vector3.BACK
var velocity = Vector3.ZERO

#velocities
var vertical_velocity = 0
var gravity = 26.34
var weight_on_ground = 8

var orientation = Transform()
var root_motion = Transform()

#movement values
export var movement_speed = 0
export var walk_speed = 1.21
export var run_speed = 5.85
export var acceleration = 9.7
export var angular_acceleration = 13

#jump, double jump and dodge values
export var jump_magnitude = 15.63
export var jump_distance = 8
export var double_jump_magnitude = 13.13
export var double_jump_distance = 30
export var jump_num = 0

#t/f variables
export var head_checked = false
export var dodging = false

onready var current_weapon = 0

var floor_just = false
var can_move = false

var run_toggle = true
var running = false

#var checks
onready var headcheck = $HeadCheck
onready var mesh = $model
onready var anim_tree = $AnimationTree

func check_weapon_states(delta):
	if current_weapon == 1:
		anim_tree.set("parameters/idle_states/blend_amount", 1)
		anim_tree.set("parameters/walk_states/blend_amount", 1)
		anim_tree.set("parameters/run_states/blend_amount", 1)
	if current_weapon == 0:
		anim_tree.set("parameters/idle_states/blend_amount", 0)
		anim_tree.set("parameters/walk_states/blend_amount", 0)
		anim_tree.set("parameters/run_states/blend_amount", 0)

func _ready():
	if run_toggle:
		if Input.is_action_pressed("walk_toggle"):
			running = false if running else true
	else:
		running = Input.is_action_pressed("walk_toggle")

func _physics_process(delta):
	#basic movement script, speaks for itself.	
	var rot = $camBase/camRot.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("move_forward") ||  Input.is_action_pressed("move_backward") ||  Input.is_action_pressed("move_left") ||  Input.is_action_pressed("move_right"):
	
		direction = Vector3(Input.get_action_strength("move_left") - Input.get_action_strength("move_right"), 0,
			Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward"))

		direction = direction.rotated(Vector3.UP, rot).normalized()
		
		if Input.is_action_pressed("walk_toggle"):
			movement_speed = walk_speed
			anim_tree.set("parameters/iwr_blend/blend_amount", lerp(anim_tree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
		else:
			movement_speed = run_speed
			anim_tree.set("parameters/iwr_blend/blend_amount", lerp(anim_tree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))
				
	else:
		movement_speed = 0
		anim_tree.set("parameters/iwr_blend/blend_amount", lerp(anim_tree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)

	move_and_slide(velocity + Vector3.UP * vertical_velocity - get_floor_normal() * weight_on_ground, Vector3.UP)
	
	#player is in the air
	if !is_on_floor():
		anim_tree.set("parameters/agc_trans/current", 0)
		vertical_velocity -= gravity * delta
		floor_just = false
		
	#air combat code
		if current_weapon == 1:
			if Input.is_action_just_pressed("attack"):
				anim_tree.set("parameters/air_hit1/active", true)
				vertical_velocity = 9
				velocity = direction * 20
			
	#player is on the ground
	else:
		if vertical_velocity < -10:
			if floor_just == false:
				$AnimationTree.set("parameters/land/active",true)
				floor_just = true
				#can_jump = false
				#can_move = false
				$fall_timer.start()
		anim_tree.set("parameters/agc_trans/current", 1)
		jump_num = 1
		vertical_velocity = 0
		
	#combat ground code
		if current_weapon == 1:
			if Input.is_action_just_pressed("attack"):
				anim_tree.set("parameters/hit1/active", true)
				anim_tree.get_root_motion_transform()
					
		if current_weapon == 0:
			anim_tree.set("parameters/idle_states/blend_amount", 0)
	
		if Input.is_action_just_pressed("weapon_toggle"):
			if !anim_tree.get("parameters/sheathe_kb/active") and !anim_tree.get("parameters/draw_kb/active"):
				if current_weapon == 0:
					!anim_tree.set("parameters/draw_kb/active", true)
					current_weapon = 1
					$model/P_EX100outao/Skeleton/BoneAttachment/kingdom_key.visible = true
				else:
					!anim_tree.set("parameters/sheathe_kb/active", true)
					current_weapon = 0
					$model/P_EX100outao/Skeleton/BoneAttachment/kingdom_key.visible = false
		
	#run/sprint blending
	mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
		
#jumping and double jumping script
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if jump_num == 1:
			$AnimationTree.set("parameters/jump/active", true)
			vertical_velocity = jump_magnitude
			jump_num = 1
			
	elif Input.is_action_just_pressed("jump") and not is_on_floor():
		if jump_num == 1:
			$AnimationTree.set("parameters/djump/active", true)
			vertical_velocity = double_jump_magnitude
			velocity = direction * double_jump_distance
			jump_num = 2
			
#this is for when the player's head collides with a ceiling, that it pushes the player back down
#	if headcheck.is_colliding():
#		head_checked = true
#		vertical_velocity = -2
	
# Check current weapon
	check_weapon_states(delta)

func _on_fall_timer_timeout():
	pass
	
func _on_AnimationPlayer_animation_finished(draw_kb):
	current_weapon = 1
