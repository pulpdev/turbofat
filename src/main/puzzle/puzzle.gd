class_name Puzzle
extends Control
"""
Represents a minimal puzzle game with a piece, playfield of pieces, and next pieces. Other classes can extend this
class to add goals, win conditions, challenges or time limits.
"""

signal line_cleared(y, total_lines, remaining_lines, box_ints)

# signal emitted a few seconds after the game ends, for displaying messages
signal after_game_ended

signal back_button_pressed

onready var _go_voices := [$GoVoice0, $GoVoice1, $GoVoice2]

func _ready() -> void:
	PuzzleScore.connect("combo_ended", self, "_on_PuzzleScore_combo_ended")
	$Playfield/TileMapClip/TileMap/Viewport/ShadowMap.piece_tile_map = $PieceManager/TileMap
	
	for i in range(3):
		$CustomerView.summon_customer(i)


"""
Shows a detailed multi-line message, like how the game is controlled
"""
func show_detail_message(text: String) -> void:
	$HudHolder/Hud.show_detail_message(text)


"""
Shows a succinct single-line message, like 'Game Over'
"""
func show_message(text: String) -> void:
	$HudHolder/Hud.show_message(text)


func start_game() -> void:
	PuzzleScore.prepare_game()
	show_message("3")
	$ReadySound.play()
	yield(get_tree().create_timer(0.8), "timeout")
	show_message("2")
	$ReadySound.play()
	yield(get_tree().create_timer(0.8), "timeout")
	show_message("1")
	$ReadySound.play()
	yield(get_tree().create_timer(0.8), "timeout")
	$GoSound.play()
	_go_voices[randi() % _go_voices.size()].play()
	PuzzleScore.start_game()


"""
Ends the game. This occurs when the player loses, wins, or runs out of time.
"""
func end_game(delay: float, message: String) -> void:
	PuzzleScore.end_game()
	show_message(message)
	yield(get_tree().create_timer(delay), "timeout")
	emit_signal("after_game_ended")


func hide_chalkboard() -> void:
	$Chalkboard.visible = false


"""
Returns the milestone hud's description label.
"""
func miledesc() -> Label:
	return $Chalkboard/MilestoneHud/Desc as Label


"""
Returns the milestone hud's progress bar.
"""
func milebar() -> ProgressBar:
	return $Chalkboard/MilestoneHud/ProgressBar as ProgressBar


"""
Returns the milestone hud's value label.
"""
func milevalue() -> Label:
	return $Chalkboard/MilestoneHud/Value as Label


"""
Triggers the eating animation and makes the customer fatter. Accepts a 'fatness_pct' parameter which defines how
much fatter the customer should get. We can calculate how fat they should be, and a value of 0.4 means the customer
should increase by 40% of the amount needed to reach that target.

This 'fatness_pct' parameter is needed for the scenario where the player eliminates three lines at once. We don't
want the customer to suddenly grow full size. We want it to take 3 bites.

Parameters:
	'fatness_pct' A percent from [0.0-1.0] of how much fatter the customer should get from this bite of food.
"""
func _feed_customer(fatness_pct: float) -> void:
	$CustomerView/SceneClip/CustomerSwitcher/Scene.feed()
	
	if PuzzleScore.game_active and Global.customer_fatten:
		var old_fatness: float = $CustomerView.get_fatness()
		var target_fatness := sqrt(1 + PuzzleScore.get_customer_score() / 50.0)
		$CustomerView.set_fatness(lerp(old_fatness, target_fatness, fatness_pct))


func _on_Hud_back_button_pressed() -> void:
	emit_signal("back_button_pressed")


func _on_Hud_start_button_pressed() -> void:
	start_game()


"""
When the current piece can't be placed, we end the game and emit the appropriate signals.
"""
func _on_PieceManager_piece_spawn_blocked() -> void:
	end_game(2.4, "Game over")


"""
Relays the 'line_cleared' signal to any listeners, and triggers the 'customer feeding' animation
"""
func _on_Playfield_line_cleared(y: int, total_lines: int, remaining_lines: int, box_ints: Array) -> void:
	# Calculate whether or not the customer should say something positive about the combo. The customer talks after
	var customer_talks: bool = remaining_lines == 0 and $Playfield/ComboTracker.combo >= 5 \
			and total_lines > ($Playfield/ComboTracker.combo + 1) % 3
	
	emit_signal("line_cleared", y, total_lines, remaining_lines, box_ints)
	_feed_customer(1.0 / (remaining_lines + 1))
	
	if customer_talks:
		yield(get_tree().create_timer(0.5), "timeout")
		$CustomerView/SceneClip/CustomerSwitcher/Scene.play_combo_voice()


func _on_PuzzleScore_combo_ended() -> void:
	if PuzzleScore.game_active and Global.customer_switch:
		$CustomerView.play_goodbye_voice()
		$CustomerView.scroll_to_new_customer()
