extends Node

signal minute_advanced(total_game_minutes: int)
signal day_changed(day_number: int)

const GAME_MINUTES_PER_REAL_SECOND := 2.0
const MAX_OFFLINE_SECONDS := 2 * 60 * 60
const START_MINUTES := 7 * 60
const MINUTES_PER_DAY := 24 * 60
const MAX_TOTAL_GAME_MINUTES := MINUTES_PER_DAY * 36500

var total_game_minutes: int = START_MINUTES
var is_paused := false
var _minute_accumulator := 0.0
var _last_emitted_day := 1


func _ready() -> void:
	_last_emitted_day = get_day_number()


func _process(delta: float) -> void:
	if is_paused:
		return

	_minute_accumulator += maxf(0.0, delta) * GAME_MINUTES_PER_REAL_SECOND
	var processed := 0
	while _minute_accumulator >= 1.0 and processed < 120:
		_minute_accumulator -= 1.0
		_advance_one_minute()
		processed += 1


func _advance_one_minute() -> void:
	if total_game_minutes >= MAX_TOTAL_GAME_MINUTES:
		return

	total_game_minutes += 1
	minute_advanced.emit(total_game_minutes)

	var current_day := get_day_number()
	if current_day != _last_emitted_day:
		_last_emitted_day = current_day
		day_changed.emit(current_day)


func apply_state(state: Dictionary) -> void:
	total_game_minutes = clampi(
		int(state.get("total_game_minutes", START_MINUTES)),
		0,
		MAX_TOTAL_GAME_MINUTES
	)
	_minute_accumulator = 0.0
	_last_emitted_day = get_day_number()


func get_state() -> Dictionary:
	return {
		"total_game_minutes": total_game_minutes
	}


func apply_offline_progress(last_saved_unix: int, now_unix: int = 0) -> int:
	if now_unix <= 0:
		now_unix = int(Time.get_unix_time_from_system())

	var added_minutes := calculate_offline_minutes(last_saved_unix, now_unix)
	if added_minutes <= 0:
		return 0

	var previous_day := get_day_number()
	total_game_minutes = mini(
		total_game_minutes + added_minutes,
		MAX_TOTAL_GAME_MINUTES
	)
	_minute_accumulator = 0.0

	minute_advanced.emit(total_game_minutes)
	var current_day := get_day_number()
	if current_day != previous_day:
		_last_emitted_day = current_day
		day_changed.emit(current_day)

	return added_minutes


func calculate_offline_minutes(
	last_saved_unix: int,
	now_unix: int,
	max_seconds: int = MAX_OFFLINE_SECONDS
) -> int:
	if last_saved_unix <= 0 or now_unix <= last_saved_unix:
		return 0

	var safe_cap := maxi(0, max_seconds)
	var elapsed_seconds := clampi(now_unix - last_saved_unix, 0, safe_cap)
	return int(floor(float(elapsed_seconds) * GAME_MINUTES_PER_REAL_SECOND))


func get_day_number() -> int:
	return int(floor(float(total_game_minutes) / float(MINUTES_PER_DAY))) + 1


func get_hour() -> int:
	return int((total_game_minutes % MINUTES_PER_DAY) / 60)


func get_minute() -> int:
	return total_game_minutes % 60


func get_clock_text() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]
