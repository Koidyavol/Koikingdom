extends Node

var day: int = 1
var hour: int = 7
var minute: int = 0
@export var minutes_per_real_second: float = 2.0
var _accumulator := 0.0

func _process(delta: float) -> void:
    _accumulator += delta * minutes_per_real_second
    while _accumulator >= 1.0:
        _accumulator -= 1.0
        minute += 1
        if minute >= 60:
            minute = 0
            hour += 1
        if hour >= 24:
            hour = 0
            day += 1

func formatted_time() -> String:
    return "Hari %d  %02d:%02d" % [day, hour, minute]

func reset_clock() -> void:
    day = 1
    hour = 7
    minute = 0
    _accumulator = 0.0

func get_state() -> Dictionary:
    return {"day": day, "hour": hour, "minute": minute}

func apply_state(state: Dictionary) -> void:
    day = maxi(1, int(state.get("day", 1)))
    hour = clampi(int(state.get("hour", 7)), 0, 23)
    minute = clampi(int(state.get("minute", 0)), 0, 59)
    _accumulator = 0.0
