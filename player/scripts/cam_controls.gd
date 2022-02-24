extends Spatial

#camera variables
const CAMERA_MOUSE_ROTATION_SPEED = 0.002
const CAMERA_CONTROLLER_ROTATION_SPEED = 2.8
const CAMERA_X_ROT_MIN = -40
const CAMERA_X_ROT_MAX = 70

var camera_x_rot = 0.0

onready var camera_base = $"."
onready var camera_rot = $camRot
onready var camera_camera = $camRot/camera

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		var camera_speed_this_frame = CAMERA_MOUSE_ROTATION_SPEED
		rotate_camera(event.relative * camera_speed_this_frame)

func _physics_process(delta):
	var rot = camera_rot.global_transform.basis.get_euler().y
	
		#camera physics
	var camera_move = Vector2(
		Input.get_action_strength("view_right") - Input.get_action_strength("view_left"),
		Input.get_action_strength("view_down") - Input.get_action_strength("view_up"))
	var camera_speed_this_frame = delta * CAMERA_CONTROLLER_ROTATION_SPEED
	rotate_camera(camera_move * camera_speed_this_frame)
	
	var camera_basis = camera_rot.global_transform.basis
	var camera_z = camera_basis.z
	var camera_x = camera_basis.x

	camera_z.y = 0
	camera_z = camera_z.normalized()
	camera_x.y = 0
	camera_x = camera_x.normalized()

func rotate_camera(move):
	camera_base.rotate_y(-move.x)
	# After relative transforms, camera needs to be renormalized.
	camera_base.orthonormalize()
	camera_x_rot += move.y
	camera_x_rot = clamp(camera_x_rot, deg2rad(CAMERA_X_ROT_MIN), deg2rad(CAMERA_X_ROT_MAX))
	camera_rot.rotation.x = camera_x_rot
