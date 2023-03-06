extends Spatial
class_name GameLimitsTracker

var _parent_node: Spatial
var _initial_parent_position: Vector3

func _ready() -> void:
    var parent = get_parent()
    assert(parent is Spatial, "GameLimitsTracker nodes should be instantiated as child of a Spatial node")
    _parent_node = parent
    _initial_parent_position = _parent_node.global_transform.origin

func reset_parent_position() -> void:
    _parent_node.global_transform.origin = _initial_parent_position