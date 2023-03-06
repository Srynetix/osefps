extends Spatial

onready var _camera_cycle = [$Cameras/TopCamera, $Cameras/FarCamera, null]
onready var _current = len(_camera_cycle) - 1

func _input(event):
    if event is InputEventKey:
        if event.pressed && event.physical_scancode == KEY_0:
            _select_next_camera()

func _select_next_camera():
    var next_current := wrapi(_current + 1, 0, len(_camera_cycle))
    var prev_camera := _camera_cycle[_current] as Camera
    var new_camera := _camera_cycle[next_current] as Camera

    if prev_camera != null:
        prev_camera.current = false
    if new_camera != null:
        new_camera.current = true

    _current = next_current