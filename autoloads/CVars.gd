extends Node

const SENTINEL = Object()

class _Vars:
    extends Object

    var ai_debug_shooting := false
    var ai_debug_moving := false
    var ai_debug_jumping := false
    var ai_debug_crouching := false
    var player_gravity := -10
    var player_movement_speed := 5
    var player_air_movement_speed := 2
    var player_dash_speed := 15
    var player_jump_speed := 5
    var player_crouch_speed := 2
    var player_walk_speed := 2
    var player_input_look_sensitivity := 20
    var player_look_sensitivity := 10

var _vars := _Vars.new()

func get_cvar(name: String):
    return _vars.get(name)

func set_cvar(name: String, value):
    _vars.set(name, value)

func print_cvars() -> String:
    var output := ""
    var plist := _vars.get_property_list()
    for p in plist:
        if p["usage"] == PROPERTY_USAGE_SCRIPT_VARIABLE:
            var value = _vars.get(p["name"])
            output += "%s (%s)\n" % [p["name"], value]
    if output != "":
        output = output.substr(0, len(output) - 1)
    return output
