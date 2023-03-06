tool
extends Control
class_name GameCrosshair

export var size = Vector2(25, 15)
export var color = Color.red
export var width = 1

func _process(_delta: float) -> void:
    update()

func _draw() -> void:
    draw_line(Vector2.LEFT * size.x, Vector2.RIGHT * size.x, color, width)
    draw_line(Vector2.UP * size.y, Vector2.DOWN * size.y, color, width)