extends KinematicBody
class_name GameFPSPlayer

const MIN_LOOK_ANGLE := -90
const MAX_LOOK_ANGLE := 90
const DASH_TIME_THRESHOLD := 200
const DASH_DELAY := 100

var velocity := Vector3.ZERO

export var is_ai := false
export var look_up_action: String
export var look_down_action: String
export var look_left_action: String
export var look_right_action: String
export var move_forward_action: String = "ui_up"
export var move_backward_action: String = "ui_down"
export var move_left_action: String = "ui_left"
export var move_right_action: String = "ui_right"
export var jump_action: String
export var fire_action: String
export var crouch_action: String
export var walk_action: String
export var peek_action: String
export var enable_mouse_aim: bool = true
export var gun_bullet_container_path: NodePath
export var health: int = 5

onready var _camera := $RotationHelper/Camera as Camera
onready var _rotation_helper := $RotationHelper as Spatial
onready var _gun := _camera.get_node("Gun") as GameGun
onready var _animation_player := $AnimationPlayer as AnimationPlayer
onready var _hitbox := $Hitbox as Area
onready var _initial_health = health

var _jumping := false
var _prev_movement_action = null
var _prev_movement_time := 0
var _dashing := false
var _walking := false
var _crouching := false
var _peeking := false
var _inside_force_field := false
var _force_field_amount := Vector3.ZERO
var tracer: SxNodeTracer

var _dash_timer: Timer
var _mouse_delta := Vector2()
var _peek_rotation := Vector3()

func _is_input_enabled() -> bool:
    if enable_mouse_aim:
        return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
    return true

func _ready() -> void:
    if gun_bullet_container_path:
        _gun.bullet_container = get_node(gun_bullet_container_path)

    if is_ai:
        _camera.current = false
        enable_mouse_aim = false

    tracer = SxNodeTracer.new()
    add_child(tracer)

    _dash_timer = Timer.new()
    add_child(_dash_timer)
    _dash_timer.connect("timeout", self, "_after_dash_delay")
    _dash_timer.wait_time = float(DASH_DELAY) / 1000.0
    _dash_timer.one_shot = true

    if enable_mouse_aim:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    _hitbox.connect("area_entered", self, "_on_area_entered")

func _handle_movement() -> Vector3:
    if is_ai:
        return _handle_ai_movement()

    var movement := Vector3()
    if !_is_input_enabled():
        return movement

    if _is_action_pressed(move_left_action):
        movement.x -= 1
    if _is_action_pressed(move_right_action):
        movement.x += 1
    if _is_action_pressed(move_forward_action):
        movement.z -= 1
    if _is_action_pressed(move_backward_action):
        movement.z += 1

    return movement.normalized()

func _handle_dash() -> void:
    if is_ai:
        return

    if _is_action_just_pressed(move_left_action):
        _handle_dash_i("left")
    if _is_action_just_pressed(move_right_action):
        _handle_dash_i("right")
    if _is_action_just_pressed(move_forward_action):
        _handle_dash_i("forward")
    if _is_action_just_pressed(move_backward_action):
        _handle_dash_i("backward")

func _handle_peeking() -> Vector3:
    var peek_direction := Vector3.ZERO

    if is_ai:
        return peek_direction

    if _is_action_pressed(move_left_action):
        peek_direction.x -= 1
    if _is_action_pressed(move_right_action):
        peek_direction.x += 1
    if _is_action_pressed(move_forward_action):
        peek_direction.z += 1
    if _is_action_pressed(move_backward_action):
        peek_direction.z -= 1

    return peek_direction.normalized()

func _handle_dash_i(action: String) -> void:
    var now_time = OS.get_ticks_msec()
    if _prev_movement_action == action && _prev_movement_time && now_time - _prev_movement_time < DASH_TIME_THRESHOLD:
        _dashing = true
        _dash_timer.start()
    else:
        _dash_timer.stop()
        _dashing = false
    _prev_movement_action = action
    _prev_movement_time = now_time

func _after_dash_delay() -> void:
    _dashing = false

func _handle_ai_movement() -> Vector3:
    if GameCVars.get_cvar("ai_debug_moving"):
        return Vector3(rand_range(-1, 1), 0, rand_range(-1, 1)).normalized()
    return Vector3()

func _handle_look() -> Vector3:
    if is_ai:
        return _handle_ai_look()

    var look := Vector3()
    if !_is_input_enabled():
        return look

    if _is_action_pressed(look_left_action):
        look.x -= 1
    if _is_action_pressed(look_right_action):
        look.x += 1
    if _is_action_pressed(look_up_action):
        look.y -= 1
    if _is_action_pressed(look_down_action):
        look.y += 1

    return look.normalized() * GameCVars.get_cvar("player_input_look_sensitivity")

func _handle_ai_look() -> Vector3:
    return Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized()

func _process(_delta: float):
    var look := _handle_look()
    if look.length() > 0:
        _mouse_delta = Vector2(look.x, look.y)

    if _is_fire_pressed():
        _gun.shoot()

func hit() -> void:
    health = int(max(health - 1, 0))
    if health == 0:
        print("BYE")
        queue_free()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if enable_mouse_aim && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            var motion_event := event as InputEventMouseMotion
            _mouse_delta = motion_event.relative

func _get_movement_speed() -> float:
    if !is_on_floor():
        return float(GameCVars.get_cvar("player_air_movement_speed"))
    elif _dashing:
        return float(GameCVars.get_cvar("player_dash_speed"))
    elif _crouching:
        return float(GameCVars.get_cvar("player_crouch_speed"))
    elif _walking:
        return float(GameCVars.get_cvar("player_walk_speed"))
    else:
        return float(GameCVars.get_cvar("player_movement_speed"))

func _physics_process(delta: float):
    var gravity = GameCVars.get_cvar("player_gravity") as int
    var look_sensitivity = GameCVars.get_cvar("player_look_sensitivity") as int
    var jump_speed = GameCVars.get_cvar("player_jump_speed") as int

    velocity += Vector3(0, gravity, 0) * delta

    var on_floor = is_on_floor()

    if _inside_force_field:
        velocity = _force_field_amount

    # Jumping
    if !_jumping && on_floor && _is_jump_pressed():
        _jumping = true
        velocity.y = jump_speed
    elif _jumping && on_floor:
        _jumping = false

    # Walking
    if on_floor && _is_walk_pressed():
        _walking = true
    else:
        _walking = false

    # Crouching
    if on_floor && _is_crouch_pressed():
        _crouching = true
        _animation_player.play("crouch")
    else:
        _crouching = false
        _animation_player.play("idle")

    # Peeking
    if _is_peek_pressed():
        _peeking = true
        var dir := _handle_peeking()
        var camera_xform := _camera.global_transform
        var forward := camera_xform.basis.z
        var right := camera_xform.basis.x
        var relative_dir := (forward * -dir.x + right * dir.z).normalized()
        _peek_rotation = lerp(_peek_rotation, relative_dir * 2, 0.1)
        # _peek_rotation.x = lerp(_peek_rotation.x, forward * dir.z * delta * 90, 0.1)
        # _peek_rotation.z = lerp(_peek_rotation.z, right * dir.x * delta * 90, 0.1)
    else:
        _peeking = false
        _peek_rotation = lerp(_peek_rotation, Vector3.ZERO, 0.1)

    # Apply peek
    global_rotation = _peek_rotation

    # Movement
    if !_peeking && !_jumping && !_inside_force_field && on_floor:
        var movement := _handle_movement()
        _handle_dash()
        var camera_xform := _camera.global_transform
        var forward := camera_xform.basis.z
        var right := camera_xform.basis.x
        var relative_dir := (forward * movement.z + right * movement.x).normalized()
        var move_velocity = relative_dir * _get_movement_speed()
        velocity.x = move_velocity.x
        velocity.z = move_velocity.z
    velocity = move_and_slide(velocity, Vector3.UP, true)

    # Camera rotation
    var rotation = _rotation_helper.rotation_degrees
    rotation.x -= _mouse_delta.y * look_sensitivity * delta
    rotation.x = clamp(rotation.x, MIN_LOOK_ANGLE, MAX_LOOK_ANGLE)
    rotation.y -= _mouse_delta.x * look_sensitivity * delta
    _rotation_helper.rotation_degrees = rotation

    _trace_parameters()
    _mouse_delta = Vector2()

    _inside_force_field = false
    _force_field_amount = Vector3.ZERO

func _trace_parameters() -> void:
    tracer.trace_parameter("Velocity", velocity)
    tracer.trace_parameter("Basis", global_transform.basis)
    tracer.trace_parameter("Origin", global_transform.origin)
    tracer.trace_parameter("Is on floor?", is_on_floor())

func _apply_force_field(force: Vector3):
    _inside_force_field = true
    _force_field_amount = force

func _on_area_entered(area: Area) -> void:
    if area is GameJumpPlatform:
        var platform := area as GameJumpPlatform
        var initial_force = platform.global_transform.basis.y * platform.jump_speed
        _apply_force_field(initial_force)

#########
# Helpers

func _is_action_pressed(action: String) -> bool:
    if !action:
        return false
    return Input.is_action_pressed(action)

func _is_action_just_pressed(action: String) -> bool:
    if !action:
        return false
    return Input.is_action_just_pressed(action)

func _is_jump_pressed() -> bool:
    if is_ai:
        return GameCVars.get_cvar("ai_debug_jumping")
    else:
        if !_is_input_enabled():
            return false
        return _is_action_just_pressed(jump_action)

func _is_peek_pressed() -> bool:
    if is_ai:
        return false
    else:
        if !_is_input_enabled():
            return false
        return _is_action_pressed(peek_action)

func _is_crouch_pressed() -> bool:
    if is_ai:
        return GameCVars.get_cvar("ai_debug_crouching")
    else:
        if !_is_input_enabled():
            return false
        return _is_action_pressed(crouch_action)

func _is_walk_pressed() -> bool:
    if is_ai:
        return false
    else:
        if !_is_input_enabled():
            return false
        return _is_action_pressed(walk_action)

func _is_fire_pressed() -> bool:
    if is_ai:
        return GameCVars.get_cvar("ai_debug_shooting")
    else:
        if !_is_input_enabled():
            return false
        return _is_action_pressed(fire_action)
