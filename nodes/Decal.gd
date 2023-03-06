# tool
extends MeshInstance
class_name SxDecal

export var texture: Texture setget _set_texture

func _ready() -> void:
    pass
    # _set_texture(texture)

func _set_texture(value: Texture) -> void:
    texture = value
    var material = _get_material()
    if material == null:
        yield(self, "ready")

    material.set_shader_param("texture_albedo", texture)

func _get_material() -> ShaderMaterial:
    return get_surface_material(0) as ShaderMaterial