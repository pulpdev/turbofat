extends Node
"""
Plays sound effects when lines are cleared.
"""

onready var _combo_sounds := [null, null, # no combo sfx for the first two lines
		$Combo01Sound, $Combo02Sound, $Combo03Sound, $Combo04Sound, $Combo05Sound, $Combo06Sound,
		$Combo07Sound, $Combo08Sound, $Combo09Sound, $Combo10Sound, $Combo11Sound, $Combo12Sound,
		$Combo13Sound, $Combo14Sound, $Combo15Sound, $Combo16Sound, $Combo17Sound, $Combo18Sound,
		$Combo19Sound, $Combo20Sound, $Combo21Sound, $Combo22Sound, $Combo23Sound, $Combo24Sound]

onready var _combo_endless_sounds := [$ComboEndless00Sound, $ComboEndless01Sound, $ComboEndless02Sound, 
		$ComboEndless03Sound, $ComboEndless04Sound, $ComboEndless05Sound, $ComboEndless06Sound, $ComboEndless07Sound,
		$ComboEndless08Sound, $ComboEndless09Sound, $ComboEndless10Sound, $ComboEndless11Sound]

onready var _line_erase_sounds := [$LineEraseSound1, $LineEraseSound2, $LineEraseSound3]

onready var _combo_tracker: Playfield = $"../ComboTracker"

func _play_thump_sound(y: int, total_lines: int, remaining_lines: int, box_ints: Array) -> void:
	var sound: AudioStreamPlayer = _line_erase_sounds[total_lines - remaining_lines - 1]
	if sound:
		sound.pitch_scale = rand_range(0.90, 1.10)
		sound.play()


"""
Plays an escalating sound for the current combo.

For smaller combos this goes through a list of sound effects with higher pitches. For larger combos this loops through
a repeating list where the repetition is concealed using a shepard tone.
"""
func _play_combo_sound(y: int, total_lines: int, remaining_lines: int, box_ints: Array) -> void:
	var sound: AudioStreamPlayer
	if _combo_tracker.combo < _combo_sounds.size():
		sound = _combo_sounds[_combo_tracker.combo - 1]
	else:
		sound = _combo_endless_sounds[(_combo_tracker.combo - 1 - _combo_sounds.size()) % _combo_endless_sounds.size()]
	if sound: sound.play()


func _play_box_sound(y: int, total_lines: int, remaining_lines: int, box_ints: Array) -> void:
	var sound: AudioStreamPlayer
	if box_ints.has(Playfield.BOX_INT_CAKE):
		sound = $ClearCakePieceSound
	elif not box_ints.empty():
		sound = $ClearSnackPieceSound
	if sound: sound.play()


"""
Clearing a line results in three overlapping sounds:
	1. A 'thump' sound
	2. A 'ding' sound for continuing a combo
	3. A 'glorp' sound when clearing a snack/cake box
"""
func _on_Playfield_before_line_cleared(y: int, total_lines: int, remaining_lines: int, box_ints: Array) -> void:
	_play_thump_sound(y, total_lines, remaining_lines, box_ints)
	_play_combo_sound(y, total_lines, remaining_lines, box_ints)
	_play_box_sound(y, total_lines, remaining_lines, box_ints)
