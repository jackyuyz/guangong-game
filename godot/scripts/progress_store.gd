extends RefCounted
## One ConfigFile owns settings, story progress and versioned scores.
const SCORE_VERSION = "ch01-v2-checkpoint"
const LUOYANG_ROUTE = "ch02-v1-route"
const IDS = ["dongling", "luoyang", "sishui", "xingyang", "yellow_river"]
var config = ConfigFile.new()
var path = ""
var error_text = ""
var writable = true
var needs_migration = false

func load_file(file_path: String) -> void:
	path = file_path
	config = ConfigFile.new()
	error_text = ""
	writable = true
	needs_migration = false
	var result = config.load(path)
	if result != OK and result != ERR_FILE_NOT_FOUND:
		writable = false
		error_text = "存档读取失败，本次进度暂不能保存"
		return
	var version = config.get_value("journey", "schema_version", 0)
	if not version is int or version > 1 or version < 0:
		writable = false
		error_text = "存档版本暂不支持，本次进度暂不能保存"
		return
	if version == 0:
		needs_migration = result == OK
		config.set_value("journey", "schema_version", 1)
		if config.get_value(SCORE_VERSION, "cleared", false) == true:
			config.set_value("chapter.dongling", "cleared", true)
			config.set_value("journey", "intro_state", "legacy")
	if intro_state() == "unseen":
		config.set_value("journey", "intro_state", "unseen")

func intro_state() -> String:
	var value = config.get_value("journey", "intro_state", "unseen")
	return str(value) if value in ["unseen", "completed", "skipped", "legacy"] else "unseen"

func set_intro(value: String) -> void:
	if value in ["completed", "skipped"]:
		config.set_value("journey", "intro_state", value)

func is_cleared(id: String) -> bool:
	return id in IDS and config.get_value("chapter." + id, "cleared", false) == true

func is_unlocked(id: String, order: Array = IDS) -> bool:
	var position = order.find(id)
	if position < 0:
		return false
	for i in position:
		if not is_cleared(str(order[i])):
			return false
	return true

func completed_count() -> int:
	var count = 0
	for id in IDS:
		if is_cleared(id): count += 1
	return count

func best_score() -> int:
	var value = config.get_value(SCORE_VERSION, "best", 0)
	return maxi(0, int(value)) if value is int or value is float else 0

func muted() -> bool:
	return config.get_value("settings", "muted", false) == true

func reduced_motion() -> bool:
	if config.has_section_key("settings", "reduced_motion"):
		return config.get_value("settings", "reduced_motion", false) == true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	return false

func mark_cleared(id: String, score: int) -> void:
	if id not in IDS:
		return
	config.set_value("chapter." + id, "cleared", true)
	if id == "dongling":
		config.set_value(SCORE_VERSION, "cleared", true)
		config.set_value(SCORE_VERSION, "best", maxi(best_score(), score))

func luoyang_record() -> Dictionary:
	var record = config.get_value(LUOYANG_ROUTE, "best", {})
	return record.duplicate(true) if _valid_route(record) else {}

func _valid_route(record: Variant) -> bool:
	if not record is Dictionary:
		return false
	var seconds = record.get("seconds", 0.0)
	if not (seconds is float or seconds is int) or not is_finite(float(seconds)) or seconds <= 0.0:
		return false
	for key in ["hits", "retries", "switches"]:
		if not record.get(key) is int or record[key] < 0:
			return false
	return true

func record_luoyang(record: Dictionary) -> bool:
	if not _valid_route(record):
		error_text = "本次洛阳成绩无效，暂不能保存"
		return false
	var best_route = luoyang_record()
	var better = best_route.is_empty() or record.seconds < best_route.seconds
	if not best_route.is_empty() and is_equal_approx(record.seconds, best_route.seconds):
		better = record.hits < best_route.hits or (record.hits == best_route.hits and record.retries < best_route.retries)
	if better:
		config.set_value(LUOYANG_ROUTE, "best", record.duplicate(true))
	mark_cleared("luoyang", 0)
	return save_file()

func save_preferences(sound_muted: bool, reduce_motion: bool, best: int) -> bool:
	config.set_value("settings", "muted", sound_muted)
	config.set_value("settings", "reduced_motion", reduce_motion)
	config.set_value(SCORE_VERSION, "best", maxi(best_score(), best))
	return save_file()

func save_file() -> bool:
	if not writable:
		return false
	if config.save(path) != OK:
		error_text = "本次进度未能保存"
		return false
	error_text = ""
	needs_migration = false
	return true
