extends Camera
class_name FPSCamera

const MIN_LOOK_ANGLE := -90
const MAX_LOOK_ANGLE := 90

export var look_up_action: String
export var look_down_action: String
export var look_left_action: String
export var look_right_action: String

export var move_forward_action: String = "ui_up"
export var move_backward_action: String = "ui_down"
export var move_up_action: String
export var move_down_action: String
export var move_left_action: String = "ui_left"
export var move_right_action: String = "ui_right"

export var enable_movement: bool = true
export var enable_mouse_aim: bool = true
export var enable_spectator_mode: bool = false

export var movement_speed := 20
export var look_sensitivity := 10

onready var _camera := $Camera as Camera

var _mouse_delta := Vector2()

func _is_action_pressed(action: String) -> bool:
    if !action:
        return false
    return Input.is_action_pressed(action)


func _handle_movement() -> Vector3:
    var movement := Vector3()

    if enable_movement:
        if _is_action_pressed(move_left_action):
            movement.x -= 1
        if _is_action_pressed(move_right_action):
            movement.x += 1
        if _is_action_pressed(move_forward_action):
            movement.y -= 1
        if _is_action_pressed(move_backward_action):
            movement.y += 1
        if _is_action_pressed(move_up_action):
            movement.z += 1
        if _is_action_pressed(move_down_action):
            movement.z -= 1

    return movement.normalized()

func _handle_look() -> Vector3:
    var look := Vector3()

    if _is_action_pressed(look_left_action):
        look.x -= 1
    if _is_action_pressed(look_right_action):
        look.x += 1
    if _is_action_pressed(look_up_action):
        look.y -= 1
    if _is_action_pressed(look_down_action):
        look.y += 1

    return look.normalized()

func _ready():
    if enable_mouse_aim:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    if !enable_spectator_mode:
        _camera.current = true
    else:
        _camera.current = true

    # Reparent nodes
    for child in get_children():
        if child != _camera:
            remove_child(child)
            _camera.add_child(child)

func _process(delta: float) -> void:
    var movement := _handle_movement()
    var look := _handle_look()
    if look.length() > 0:
        _mouse_delta = Vector2(look.x, look.y)

    var forward := transform.basis.z
    var right := transform.basis.x
    var up := transform.basis.y
    var relative_dir := (forward * movement.y + right * movement.x + up * movement.z)
    translation += relative_dir * delta * movement_speed

    if enable_spectator_mode:
        var rotation = rotation_degrees
        rotation.x -= _mouse_delta.y * look_sensitivity * delta
        rotation.x = clamp(rotation.x, MIN_LOOK_ANGLE, MAX_LOOK_ANGLE)
        rotation.y -= _mouse_delta.x * look_sensitivity * delta
        rotation_degrees = rotation
    else:
        var rotation = rotation_degrees
        rotation.y -= _mouse_delta.x * look_sensitivity * delta
        rotation_degrees = rotation

        var camera_rotation = _camera.rotation_degrees
        camera_rotation.x -= _mouse_delta.y * look_sensitivity * delta
        camera_rotation.x = clamp(camera_rotation.x, MIN_LOOK_ANGLE, MAX_LOOK_ANGLE)
        _camera.rotation_degrees = camera_rotation

    _mouse_delta = Vector2()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if enable_mouse_aim:
            var motion_event := event as InputEventMouseMotion
            _mouse_delta = motion_event.relative
