extends Node
## Starts and stops music during the puzzle mode.

func _ready() -> void:
	PuzzleState.connect("game_ended", self, "_on_PuzzleState_game_ended")
	PuzzleState.connect("game_prepared", self, "_on_PuzzleState_game_prepared")


func start_puzzle_music() -> void:
	if CurrentLevel.is_tutorial():
		MusicPlayer.play_tutorial_track(false)
	else:
		MusicPlayer.play_puzzle_track(false)


func _on_PuzzleState_game_prepared() -> void:
	start_puzzle_music()


func _on_PuzzleState_game_ended() -> void:
	MusicPlayer.play_menu_track()
