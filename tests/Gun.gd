extends Spatial
class_name GameGun

const Bullet = preload("res://tests/Bullet.tscn")

var bullet_container: Node setget _set_bullet_container

onready var _audio_player := $AudioStreamPlayer as AudioStreamPlayer
var _logger := SxLog.get_logger("Gun")

var _can_shoot := true

func _ready() -> void:
    $Cooldown.connect("timeout", self, "_on_cooldown")
    _cache_bullet_container()

func shoot() -> void:
    if _can_shoot:
        $Flash.emitting = true
        _can_shoot = false
        $Cooldown.start()
        _fire()

func _set_bullet_container(value: Node) -> void:
    bullet_container = value
    _cache_bullet_container()

func _cache_bullet_container() -> void:
    if !bullet_container:
        bullet_container = get_parent().get_parent().get_parent()

func _on_cooldown() -> void:
    _can_shoot = true

func _fire() -> void:
    var pos = $Muzzle.global_transform.origin
    var bullet = Bullet.instance()
    bullet_container.add_child(bullet)
    bullet.initiator = self
    bullet.global_rotation = global_rotation
    bullet.global_transform.origin = pos
    _audio_player.play()

