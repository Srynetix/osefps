extends Spatial

onready var _particles := $CPUParticles as CPUParticles

func _ready():
    _particles.emitting = true
    yield($AudioStreamPlayer, "finished")
    queue_free()