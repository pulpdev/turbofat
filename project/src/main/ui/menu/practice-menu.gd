extends Control
"""
Scene which lets the player repeatedly play a set of scenarios.

Displays their daily and all-time high scores for each mode, encouraging the player to improve.
"""

# Rank required to unlock harder levels. Rank 24 is an S-
const RANK_TO_UNLOCK := 24.0

"""
Array of scenario categories used to initialize the scene.
[0]: Mode name, used to reference the mode selector
[1]: Difficulty name, used to populate the difficulty selector
[2]: Scenario name, used to load the scenario definitions
"""
const SCENARIO_CATEGORIES := [
	["Survival", "Normal", "survival_normal"],
	["Survival", "Hard", "survival_hard"],
	["Survival", "Expert", "survival_expert"],
	["Survival", "Master", "survival_master"],
	
	["Ultra", "Normal", "ultra_normal"],
	["Ultra", "Hard", "ultra_hard"],
	["Ultra", "Expert", "ultra_expert"],
	
	["Sprint", "Normal", "sprint_normal"],
	["Sprint", "Expert", "sprint_expert"],
	
	["Rank", "7k", "rank_7k"],
	["Rank", "6k", "rank_6k"],
	["Rank", "5k", "rank_5k"],
	["Rank", "4k", "rank_4k"],
	["Rank", "3k", "rank_3k"],
	["Rank", "2k", "rank_2k"],
	["Rank", "1k", "rank_1k"],
	["Rank", "1d", "rank_1d"],
	["Rank", "2d", "rank_2d"],
	["Rank", "3d", "rank_3d"],
	["Rank", "4d", "rank_4d"],
	["Rank", "5d", "rank_5d"],
	["Rank", "6d", "rank_6d"],
	["Rank", "7d", "rank_7d"],
	["Rank", "8d", "rank_8d"],
	["Rank", "9d", "rank_9d"],
	["Rank", "10d", "rank_10d"],
	["Rank", "M", "rank_m"],
	
	["Sandbox", "Normal", "sandbox_normal"],
	["Sandbox", "Hard", "sandbox_hard"],
	["Sandbox", "Expert", "sandbox_expert"],
	["Sandbox", "Master", "sandbox_master"],
]

"""
Key: Mode names, 'Survival', 'Ultra'
Value: Difficulty names, 'Normal', 'Hard'
"""
var mode_difficulties: Dictionary

"""
Key: Mode/Difficulty names separated with a space, 'Survival Normal', 'Ultra Hard'
Value: Scenario names, 'survival_normal', 'ultra_hard'
"""
var scenarios: Dictionary

var _rank_lowlights := []

func _ready() -> void:
	# default mode/difficulty if the player hasn't played a scenario recently
	var current_mode: String = "Ultra"
	var current_difficulty: String = "Normal"
	
	for category_obj in SCENARIO_CATEGORIES:
		var category: Array = category_obj
		var mode: String = category[0]
		var difficulty: String = category[1]
		var scenario_id: String = category[2]
		if not mode_difficulties.has(mode):
			mode_difficulties[mode] = []
		mode_difficulties[mode].append(difficulty)
		
		var settings: ScenarioSettings = ScenarioSettings.new()
		settings.load_from_resource(scenario_id)
		scenarios["%s %s" % [mode, difficulty]] = settings
		
		if scenario_id == Scenario.settings.id:
			# if they've just played a practice mode scenario, we default to that scenario
			current_mode = mode
			current_difficulty = difficulty
	
	# grab focus so the player can navigate with the keyboard
	$VBoxContainer/System/Start.grab_focus()
	
	# populate the UI with their selected scenario
	$VBoxContainer/Mode.set_selected_mode(current_mode)
	_refresh()
	$VBoxContainer/Difficulty.set_selected_difficulty(current_difficulty)


func _refresh() -> void:
	$VBoxContainer/Difficulty.set_difficulty_names(mode_difficulties[_get_mode()])
	if _get_mode() == "Rank":
		_calculate_lowlights()
		$VBoxContainer/Difficulty.set_difficulty_lowlights(_rank_lowlights)
	$VBoxContainer/Mode.set_scenario(_get_scenario())
	$VBoxContainer/HighScores.set_scenario(_get_scenario())


"""
Calculates the lowlights for rank difficulties, if they have not yet been calculated.

This calculation is complex and involves iterating over all of the player's performances for all of the rank
scenarios, so we cache the result.
"""
func _calculate_lowlights() -> void:
	if _rank_lowlights:
		# already calculated
		return
	
	for difficulty in mode_difficulties[_get_mode()]:
		var scenario: ScenarioSettings = scenarios["%s %s" % [_get_mode(), difficulty]]
		_rank_lowlights.append(not PlayerData.scenario_history.successful_scenarios.has(scenario.id))


func _get_mode() -> String:
	return $VBoxContainer/Mode.get_selected_mode()


func _get_difficulty() -> String:
	return $VBoxContainer/Difficulty.get_selected_difficulty()


func _get_scenario() -> ScenarioSettings:
	return scenarios["%s %s" % [_get_mode(), _get_difficulty()]]


func _on_Difficulty_difficulty_changed() -> void:
	_refresh()


func _on_Mode_mode_changed() -> void:
	_refresh()


func _on_Start_pressed() -> void:
	Scenario.set_launched_scenario(_get_scenario().id)
	Scenario.push_scenario_trail()
