extends Area
class_name GameBullet

const Sparkles = preload("res://tests/Sparkles.tscn")

var initiator: Node

var speed := 60.0
var velocity := Vector3.FORWARD * speed

func _ready():
    $Lifetime.connect("timeout", self, "destroy")
    connect("body_entered", self, "_on_body_entered")

func _process(delta: float) -> void:
    translate(velocity * delta)

func destroy():
    _show_sparkles(global_transform.origin)
    queue_free()

func _on_body_entered(body: PhysicsBody) -> void:
    if body == null:
        # CSG?
        destroy()

    elif body.is_in_group("player"):
        if body._gun != initiator:
            body.call("hit")
            destroy()

    elif body is RigidBody:
        var direction = -global_transform.basis.z
        body.apply_impulse(global_transform.origin - body.global_transform.origin, direction)
        destroy()

    elif body is StaticBody:
        destroy()

func _show_sparkles(position: Vector3) -> void:
    var sparkles = Sparkles.instance()
    get_parent().add_child(sparkles)
    sparkles.global_transform.origin = position
    sparkles.global_rotation = global_rotation
