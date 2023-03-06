tool
extends Spatial

const GAME_LIMITS_TRACKER_GROUP = "game_limits_tracker"

export var limits: Vector3 setget _set_limits, _get_limits

onready var _mesh_instance := $MeshInstance as MeshInstance
onready var _cube_mesh := _mesh_instance.mesh as CubeMesh

func _ready() -> void:
    if !Engine.editor_hint:
        visible = false

func _set_limits(value: Vector3) -> void:
    limits = value
    if !_cube_mesh:
        yield(self, "ready")
    _cube_mesh.size = limits

func _get_limits() -> Vector3:
    if !_cube_mesh:
        yield(self, "ready")
    return _cube_mesh.size

func _process(_delta: float):
    if Engine.editor_hint:
        return

    var bbox := AABB(global_transform.origin - limits / 2, limits)
    for node in get_tree().get_nodes_in_group(GAME_LIMITS_TRACKER_GROUP):
        var tracker := node as GameLimitsTracker
        if !bbox.has_point(tracker.global_transform.origin):
            tracker.reset_parent_position()