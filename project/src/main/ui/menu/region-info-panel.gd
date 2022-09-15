extends Panel
## A panel on the region select screen which summarizes region details.
##
## This includes details about the player's progress and how they can progress further.

## The text shown in the region info panel
var text: String setget set_text

## key: (String) level id
## value: (String) human readable rank for the specified level id, such as '7 dan'
var rank_by_level_id := {
	"rank/7k": tr("7 kyu"),
	"rank/6k": tr("6 kyu"),
	"rank/5k": tr("5 kyu"),
	"rank/4k": tr("4 kyu"),
	"rank/3k": tr("3 kyu"),
	"rank/2k": tr("2 kyu"),
	"rank/1k": tr("1 kyu"),
	"rank/1d": tr("1 dan"),
	"rank/2d": tr("2 dan"),
	"rank/3d": tr("3 dan"),
	"rank/4d": tr("4 dan"),
	"rank/5d": tr("5 dan"),
	"rank/6d": tr("6 dan"),
	"rank/7d": tr("7 dan"),
	"rank/8d": tr("8 dan"),
	"rank/9d": tr("9 dan"),
	"rank/10d": tr("10 dan"),
	"rank/m": tr("Master"),
}

## The label which shows the text of the region info panel
onready var _label := $MarginContainer/Label

func _ready() -> void:
	_refresh_text()


func set_text(new_text: String) -> void:
	text = new_text
	_refresh_text()


## Updates the region info panel label's text to match our text field
func _refresh_text() -> void:
	if _label:
		_label.text = text


## Updates the text box to show the career region's information.
func _update_career_region_text(region: CareerRegion) -> void:
	if PlayerData.career.is_region_locked(region):
		set_text("")
		return
	
	var new_text := ""
	var region_completion := PlayerData.career.region_completion(region)
	if region_completion.completion_percent() == 1.0:
		# include grade details -- how the player can get a better grade
		var ranks := []
		for level_obj in region.levels:
			var level: CareerLevel = level_obj
			ranks.append(PlayerData.level_history.best_overall_rank(level.level_id))
		
		# calculate the worst rank
		var worst_rank := 0.0
		for rank in ranks:
			worst_rank = max(worst_rank, rank)
		
		# count the total number of 'stars' for all of the levels
		var star_count := 0
		for rank in ranks:
			match RankCalculator.grade(rank):
				"S-": star_count += 1
				"S": star_count += 2
				"S+": star_count += 3
				"SS": star_count += 4
				"SS+": star_count += 5
				"SSS": star_count += 6
				"M": star_count += 7
		
		# calculate the percent of levels where the player's rank is already high enough to rank up
		var worst_rank_count := 0
		for rank in ranks:
			if RankCalculator.grade(worst_rank) == RankCalculator.grade(rank):
				worst_rank_count += 1
		var next_rank_pct := float(ranks.size() - worst_rank_count) / ranks.size()
		
		new_text += tr("Overall grade: %s") % [RankCalculator.grade(worst_rank)]
		if RankCalculator.grade(worst_rank) != RankCalculator.HIGHEST_GRADE:
			new_text += "\n" + tr("Promotion to %s: %.1f%%") % [
					RankCalculator.next_grade(RankCalculator.grade(worst_rank)), 100 * next_rank_pct]
		if star_count > 0:
			new_text += "\n" + tr("Total stars: %s") % [star_count]
	else:
		# include completion details -- how the player can get 100%
		new_text += tr("Completion: %.1f%%") % [100.0 * region_completion.completion_percent()]
		if region_completion.cutscene_completion_percent() < 1.0:
			new_text += "\n\n" + tr("Replay this chapter to continue your adventure!")
		else:
			new_text += "\n\n" + tr("Clear every level to get to 100%!")
	
	set_text(new_text)


## Updates the text box to show the rank region's information. This includes regions for tutorials and training
## levels.
func _update_rank_region_text(region: OtherRegion) -> void:
	var new_text := ""
	
	# find the last rank level which the player completed successfully
	var last_successful_level_id: String
	for level_id in region.level_ids:
		if PlayerData.level_history.is_level_success(level_id):
			last_successful_level_id = level_id
	
	# translate the level id into a message like 'Overall rank: 7 dan'
	var last_successful_level_index := region.level_ids.find(last_successful_level_id)
	new_text += tr("Overall rank: %s") % [rank_by_level_id.get(last_successful_level_id, "-")]
	
	# add a message describing how close they are to reaching the next level's success criteria
	if last_successful_level_index != region.level_ids.size() - 1:
		var next_level_id: String = region.level_ids[last_successful_level_index + 1]
		var next_rank: String = rank_by_level_id.get(next_level_id, "-")
		var best_result := PlayerData.level_history.best_result(next_level_id)
		var promotion_percent := 0.0
		if best_result:
			var level_settings := LevelSettings.new()
			level_settings.load_from_resource(next_level_id)
			if best_result.compare == "-seconds":
				# If the player has finished in 4 minutes but needs 2 minutes, they are 25% complete
				promotion_percent = level_settings.success_condition.value / float(best_result.seconds)
				promotion_percent = pow(promotion_percent, 2.0)
			else:
				# If the player scored ¥200 but needs ¥400, they are 25% complete
				promotion_percent = best_result.score / float(level_settings.success_condition.value)
				promotion_percent = pow(promotion_percent, 2.0)
		
		new_text += "\n" + tr("Promotion to %s: %.1f%%") % [next_rank, 100 * promotion_percent]
	set_text(new_text)


## Updates the text box to show the other region's information. This includes regions for tutorials and training
## levels.
func _update_other_region_text(region: OtherRegion) -> void:
	var new_text := ""
	var level_completion: int = 0
	var potential_level_completion := region.level_ids.size()
	for level_id in region.level_ids:
		# count the number of finished levels
		if PlayerData.level_history.is_level_finished(level_id):
			level_completion += 1
	var completion_percent := level_completion / float(potential_level_completion)
	
	if completion_percent == 1.0:
		# include grade details -- how the player can get a better grade
		var ranks := []
		for level_id in region.level_ids:
			ranks.append(PlayerData.level_history.best_overall_rank(level_id))
		
		# calculate the worst rank
		var worst_rank := 0.0
		for rank in ranks:
			worst_rank = max(worst_rank, rank)
		
		# count the total number of 'stars' for all of the levels
		var star_count := 0
		for rank in ranks:
			match RankCalculator.grade(rank):
				"S-": star_count += 1
				"S": star_count += 2
				"S+": star_count += 3
				"SS": star_count += 4
				"SS+": star_count += 5
				"SSS": star_count += 6
				"M": star_count += 7
		
		# calculate the percent of levels where the player's rank is already high enough to rank up
		var worst_rank_count := 0
		for rank in ranks:
			if RankCalculator.grade(worst_rank) == RankCalculator.grade(rank):
				worst_rank_count += 1
		var next_rank_pct := float(ranks.size() - worst_rank_count) / ranks.size()
		
		new_text += tr("Overall grade: %s") % [RankCalculator.grade(worst_rank)]
		if RankCalculator.grade(worst_rank) != RankCalculator.HIGHEST_GRADE:
			new_text += "\n" + tr("Promotion to %s: %.1f%%") % [
					RankCalculator.next_grade(RankCalculator.grade(worst_rank)), 100 * next_rank_pct]
		if star_count > 0:
			new_text += "\n" + tr("Total stars: %s") % [star_count]
	else:
		# include completion details -- how the player can get to 100%
		new_text += tr("Completion: %.1f%%") % [100.0 * completion_percent]
		new_text += "\n\n" + tr("Clear every level to get to 100%!")
	
	set_text(new_text)


func _on_RegionButtons_region_focused(region_obj: Object) -> void:
	if region_obj is CareerRegion:
		_update_career_region_text(region_obj)
	elif region_obj is OtherRegion and region_obj.id == OtherRegion.ID_RANK:
		_update_rank_region_text(region_obj)
	else:
		_update_other_region_text(region_obj)
