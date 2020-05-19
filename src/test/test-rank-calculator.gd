extends "res://addons/gut/test.gd"
"""
Unit test demonstrating the rank calculator. If a player scores a lot of points, the game should give them a higher
rank. Short levels with slower pieces require lower scores, because even a perfect player couldn't score very many
points.

There are a lot of variables and edge cases involved in the rank calculations, and it's easy to introduce obscure bugs
where it's impossible to get a master rank, or the rank system is too forgiving, which is why unit tests are
particularly important for this code.
"""

var _rank_calculator := RankCalculator.new()

func before_each() -> void:
	Global.scenario_settings.reset()
	Global.scenario_settings.set_start_level("0")
	PuzzleScore.scenario_performance = ScenarioPerformance.new()


func test_max_lpm_slow_marathon() -> void:
	Global.scenario_settings.set_start_level("0")
	assert_almost_eq(_rank_calculator._max_lpm(), 30.77, 0.1)


func test_max_lpm_medium_marathon() -> void:
	Global.scenario_settings.set_start_level("A0")
	assert_almost_eq(_rank_calculator._max_lpm(), 35.64, 0.1)


func test_max_lpm_fast_marathon() -> void:
	Global.scenario_settings.set_start_level("F0")
	assert_almost_eq(_rank_calculator._max_lpm(), 64.00, 0.1)


func test_max_lpm_mixed_marathon() -> void:
	Global.scenario_settings.set_start_level("0")
	Global.scenario_settings.add_level_up(ScenarioSettings.LINES, 30, "A0")
	Global.scenario_settings.add_level_up(ScenarioSettings.LINES, 60, "F0")
	Global.scenario_settings.set_win_condition(ScenarioSettings.LINES, 100)
	assert_almost_eq(_rank_calculator._max_lpm(), 45.01, 0.1)


func test_max_lpm_mixed_sprint() -> void:
	Global.scenario_settings.set_start_level("0")
	Global.scenario_settings.add_level_up(ScenarioSettings.TIME, 30, "A0")
	Global.scenario_settings.add_level_up(ScenarioSettings.TIME, 60, "F0")
	Global.scenario_settings.set_finish_condition(ScenarioSettings.TIME, 90)
	assert_almost_eq(_rank_calculator._max_lpm(), 49.47, 0.1)


func test_calculate_rank_marathon_300_master() -> void:
	Global.scenario_settings.set_win_condition(ScenarioSettings.LINES, 300)
	PuzzleScore.scenario_performance.seconds = 580
	PuzzleScore.scenario_performance.lines = 300
	PuzzleScore.scenario_performance.box_score = 4400
	PuzzleScore.scenario_performance.combo_score = 5300
	PuzzleScore.scenario_performance.score = 10000
	var rank :=  _rank_calculator.calculate_rank()
	assert_eq(rank.speed_rank, 0.0)
	assert_eq(rank.lines_rank, 0.0)
	assert_eq(rank.box_score_per_line_rank, 0.0)
	assert_eq(rank.combo_score_per_line_rank, 0.0)
	assert_eq(rank.score_rank, 0.0)


func test_calculate_rank_marathon_300_mixed() -> void:
	Global.scenario_settings.set_win_condition(ScenarioSettings.LINES, 300)
	PuzzleScore.scenario_performance.seconds = 240
	PuzzleScore.scenario_performance.lines = 60
	PuzzleScore.scenario_performance.box_score = 600
	PuzzleScore.scenario_performance.combo_score = 500
	PuzzleScore.scenario_performance.score = 1160
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.speed_rank), "S")
	assert_eq(Global.grade(rank.lines_rank), "A+")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "S+")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "S-")
	assert_eq(Global.grade(rank.score_rank), "AA+")


func test_calculate_rank_marathon_lenient() -> void:
	Global.scenario_settings.set_win_condition(ScenarioSettings.LINES, 300, 200)
	PuzzleScore.scenario_performance.seconds = 240
	PuzzleScore.scenario_performance.lines = 60
	PuzzleScore.scenario_performance.box_score = 600
	PuzzleScore.scenario_performance.combo_score = 500
	PuzzleScore.scenario_performance.score = 1160
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.speed_rank), "S")
	assert_eq(Global.grade(rank.lines_rank), "AA+")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "S+")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "S-")
	assert_eq(Global.grade(rank.score_rank), "AA+")


func test_calculate_rank_marathon_300_fail() -> void:
	Global.scenario_settings.set_win_condition(ScenarioSettings.LINES, 300)
	PuzzleScore.scenario_performance.seconds = 0
	PuzzleScore.scenario_performance.lines = 0
	PuzzleScore.scenario_performance.box_score = 0
	PuzzleScore.scenario_performance.combo_score = 0
	PuzzleScore.scenario_performance.score = 0
	var rank := _rank_calculator.calculate_rank()
	assert_eq(rank.speed_rank, 999.0)
	assert_eq(rank.lines_rank, 999.0)
	assert_eq(rank.box_score_per_line_rank, 999.0)
	assert_eq(rank.combo_score_per_line_rank, 999.0)
	assert_eq(rank.score_rank, 999.0)


func test_calculate_rank_sprint_120() -> void:
	Global.scenario_settings.set_start_level("A0")
	Global.scenario_settings.set_finish_condition(ScenarioSettings.TIME, 120)
	PuzzleScore.scenario_performance.seconds = 120
	PuzzleScore.scenario_performance.lines = 47
	PuzzleScore.scenario_performance.box_score = 395
	PuzzleScore.scenario_performance.combo_score = 570
	PuzzleScore.scenario_performance.score = 1012
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.speed_rank), "S+")
	assert_eq(Global.grade(rank.lines_rank), "S+")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "S")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "SS")
	assert_eq(Global.grade(rank.score_rank), "S+")


func test_calculate_rank_ultra_200() -> void:
	Global.scenario_settings.set_finish_condition(ScenarioSettings.SCORE, 200)
	PuzzleScore.scenario_performance.seconds = 20.233
	PuzzleScore.scenario_performance.lines = 8
	PuzzleScore.scenario_performance.box_score = 135
	PuzzleScore.scenario_performance.combo_score = 60
	PuzzleScore.scenario_performance.score = 8
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.speed_rank), "SS+")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "M")
	assert_eq(rank.combo_score_per_line, 20.0)
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "M")
	assert_eq(Global.grade(rank.seconds_rank), "SSS")


func test_calculate_rank_ultra_200_died() -> void:
	Global.scenario_settings.set_finish_condition(ScenarioSettings.SCORE, 200)
	PuzzleScore.scenario_performance.seconds = 60
	PuzzleScore.scenario_performance.lines = 10
	PuzzleScore.scenario_performance.box_score = 80
	PuzzleScore.scenario_performance.combo_score = 60
	PuzzleScore.scenario_performance.score = 150
	PuzzleScore.scenario_performance.died = true
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.speed_rank), "AA+")
	assert_eq(rank.seconds_rank, 999.0)
	assert_eq(Global.grade(rank.box_score_per_line_rank), "B+")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "B")


"""
This is an edge case where, if the player gets too many points for ultra, they can sort of be robbed of a master rank.
"""
func test_calculate_rank_ultra_200_overshot() -> void:
	Global.scenario_settings.set_finish_condition(ScenarioSettings.SCORE, 200)
	PuzzleScore.scenario_performance.seconds = 19
	PuzzleScore.scenario_performance.lines = 10
	PuzzleScore.scenario_performance.box_score = 150
	PuzzleScore.scenario_performance.combo_score = 100
	PuzzleScore.scenario_performance.score = 260
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.speed_rank), "M")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "M")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "M")
	assert_eq(Global.grade(rank.seconds_rank), "SSS")


func test_calculate_rank_five_customers_good() -> void:
	Global.scenario_settings.set_finish_condition(ScenarioSettings.CUSTOMERS, 5)
	Global.scenario_settings.set_start_level("4")
	PuzzleScore.scenario_performance.lines = 100
	PuzzleScore.scenario_performance.box_score = 1025
	PuzzleScore.scenario_performance.combo_score = 915
	PuzzleScore.scenario_performance.score = 2040
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.lines_rank), "SSS")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "S+")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "S")
	assert_eq(Global.grade(rank.score_rank), "SS")


func test_calculate_rank_five_customers_bad() -> void:
	Global.scenario_settings.set_finish_condition(ScenarioSettings.CUSTOMERS, 5)
	Global.scenario_settings.set_start_level("4")
	PuzzleScore.scenario_performance.lines = 18
	PuzzleScore.scenario_performance.box_score = 90
	PuzzleScore.scenario_performance.combo_score = 60
	PuzzleScore.scenario_performance.score = 168
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.lines_rank), "A-")
	assert_eq(Global.grade(rank.box_score_per_line_rank), "AA")
	assert_eq(Global.grade(rank.combo_score_per_line_rank), "A")
	assert_eq(Global.grade(rank.score_rank), "A-")


"""
These two times are pretty far apart; they shouldn't yield the same rank
"""
func test_two_rank_s() -> void:
	Global.scenario_settings.set_start_level("A0")
	Global.scenario_settings.set_finish_condition(ScenarioSettings.SCORE, 1000)
	PuzzleScore.scenario_performance.seconds = 88.55
	var rank := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank.seconds_rank), "SS+")

	Global.scenario_settings.set_finish_condition(ScenarioSettings.SCORE, 1000)
	PuzzleScore.scenario_performance.seconds = 128.616
	var rank2 := _rank_calculator.calculate_rank()
	assert_eq(Global.grade(rank2.seconds_rank), "S+")


"""
This edge case used to result in a combo_score_per_line of 22.5
"""
func test_combo_score_per_line_ultra_overshot() -> void:
	Global.scenario_settings.set_finish_condition(ScenarioSettings.SCORE, 200)
	PuzzleScore.scenario_performance.combo_score = 45
	PuzzleScore.scenario_performance.lines = 7
	var rank := _rank_calculator.calculate_rank()
	assert_eq(rank.combo_score_per_line, 20.0)


"""
This edge case used to result in a combo_score_per_line of 0.305
"""
func test_combo_score_per_line_death() -> void:
	Global.scenario_settings.set_win_condition(ScenarioSettings.LINES, 200, 150)
	PuzzleScore.scenario_performance.combo_score = 195
	PuzzleScore.scenario_performance.lines = 37
	PuzzleScore.scenario_performance.died = true
	var rank := _rank_calculator.calculate_rank()
	assert_almost_eq(rank.combo_score_per_line, 6.09, 0.1)
