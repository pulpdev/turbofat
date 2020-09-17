class_name OverworldUi
extends Control
"""
UI elements for the overworld.

This includes chats, buttons and debug messages.
"""

signal chat_started

signal chat_ended

# emitted when we present the player with a dialog choice
signal showed_chat_choices

# Characters we're currently chatting with. We try to keep them all in frame and facing the player.
var chatters := []

# If 'true' the overworld is being used to play a cutscene. If 'false' the overworld is allowing free roam.
var cutscene := false

var _show_version := true setget set_show_version, is_show_version

# These two fields store details for the upcoming scenario. We store the scenario details during the dialog sequence
# and launch the scenario when the dialog window closes.
var _current_chat_tree: ChatTree
var _next_chat_tree: ChatTree

# A cache of ChatTree objects representing dialog the player's seen since this scene was loaded. This prevents the
# player from cycling through the dialog over and over if you talk to a creature multiple times repetitively.
var _chat_tree_cache: Dictionary

func _ready() -> void:
	_update_visible()
	get_tree().get_root().connect("size_changed", self, "_on_Viewport_size_changed")


func _input(event: InputEvent) -> void:
	if not chatters and event.is_action_pressed("interact") and ChattableManager.get_focused():
		get_tree().set_input_as_handled()
		start_chat(ChattableManager.load_chat_events(), [ChattableManager.get_focused()])
	if not chatters and event.is_action_pressed("ui_menu"):
		$SettingsMenu.show()
		get_tree().set_input_as_handled()


func start_chat(new_chat_tree: ChatTree, new_chatters: Array) -> void:
	_current_chat_tree = new_chat_tree
	chatters = new_chatters
	_update_visible()
	ChattableManager.set_focus_enabled(false)
	make_chatters_face_eachother()
	# emit 'chat_started' event first to prepare chatters before emoting
	emit_signal("chat_started")
	
	# reset state variables
	_next_chat_tree = null
	$ChatUi.play_chat_tree(_current_chat_tree)


func set_show_version(new_show_version: bool) -> void:
	_show_version = new_show_version
	_update_visible()


func is_show_version() -> bool:
	return _show_version


"""
Turn the the active chat participants towards each other, and make them face the camera.
"""
func make_chatters_face_eachother() -> void:
	# make the player face the other characters
	if chatters.size() >= 1:
		if ChattableManager.player.get_movement_mode() == Creature.IDLE:
			# let the player move while chatting, unless she's asked a question
			ChattableManager.player.orient_toward(chatters[0])

	# make the other characters face the player
	for chatter in chatters:
		if chatter.has_method("orient_toward"):
			# other characters must orient towards the player to avoid visual glitches when emoting while moving
			chatter.orient_toward(ChattableManager.player)


"""
Updates the different UI components to be visible/invisible based on the UI's current state.
"""
func _update_visible() -> void:
	$ChatUi.visible = true if chatters else false
	$Labels/SoutheastLabels/VersionLabel.visible = _show_version and not chatters


"""
Process a 'select_level_*' event, loading the appropriate scenario data or conversation to launch.
"""
func _process_select_level_meta_item(level_num: int = -1) -> void:
	var creature_chatters := []
	for chatter in chatters:
		if chatter is Creature and chatter != ChattableManager.player:
			creature_chatters.append(chatter)
	
	if creature_chatters.size() >= 2:
		push_warning("Too many (%s) creature_chatters found for select_level (%s)" \
				% [creature_chatters.size(), creature_chatters])
	elif creature_chatters.size() <= 0:
		push_warning("No creature_chatters found for select_level")
	else:
		var creature: Creature = creature_chatters[0]
		if not _chat_tree_cache.has(creature.creature_id):
			var chit_chat: bool = level_num < 1
			_next_chat_tree = ChatLibrary.load_chat_events_for_creature(creature, level_num, chit_chat)
			if _next_chat_tree.meta.get("filler", false):
				PlayerData.chat_history.increment_filler_count(creature.creature_id)
			if _next_chat_tree.meta.get("notable", false):
				PlayerData.chat_history.reset_filler_count(creature.creature_id)
			_chat_tree_cache[creature.creature_id] = _next_chat_tree
		
		_next_chat_tree = _chat_tree_cache[creature.creature_id]
		
		if level_num >= 1:
			var level_ids := creature.get_level_ids()
			var scenario_id: String = level_ids[level_num - 1]
			Scenario.set_launched_scenario(scenario_id, creature.creature_id, level_num)


func _on_ChatUi_pop_out_completed() -> void:
	PlayerData.chat_history.add_history_item(_current_chat_tree.history_key)
	
	if _next_chat_tree:
		_current_chat_tree = _next_chat_tree
		# don't reset launched_scenario; this is currently set by the first of a series of chat trees
		_next_chat_tree = null
		$ChatUi.play_chat_tree(_current_chat_tree)
	else:
		# unset mood
		for chatter in chatters:
			if chatter and chatter.has_method("play_mood"):
				chatter.call("play_mood", ChatEvent.Mood.DEFAULT)
		
		chatters = []
		ChattableManager.set_focus_enabled(true)
		_update_visible()
		emit_signal("chat_ended")
		
		if Scenario.launched_scenario_id:
			ChattableManager.clear()
			Scenario.push_scenario_trail()
			
			if cutscene:
				# upon completing a puzzle, return to the level select screen
				Breadcrumb.trail.erase(Global.SCENE_OVERWORLD)


func _on_ChatUi_chat_event_played(chat_event: ChatEvent) -> void:
	make_chatters_face_eachother()
	
	# update the chatter's mood
	var chatter := ChattableManager.get_chatter(chat_event.who)
	if chatter and chatter.has_method("play_mood"):
		chatter.call("play_mood", chat_event.mood)
	if chat_event.meta:
		var meta: Array = chat_event.meta
		for meta_item_obj in meta:
			var meta_item: String = meta_item_obj
			if meta_item.begins_with("select_level_"):
				_process_select_level_meta_item(int(StringUtils.substring_after(meta_item, "select_level_")))
			elif meta_item == "chit_chat":
				_process_select_level_meta_item()


func _on_ChatUi_showed_choices() -> void:
	emit_signal("showed_chat_choices")


func _on_SettingsMenu_quit_pressed() -> void:
	ChattableManager.clear()
	Breadcrumb.pop_trail()


func _on_Viewport_size_changed() -> void:
	rect_size = get_viewport_rect().size
