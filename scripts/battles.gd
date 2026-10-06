class_name Battles
extends RefCounted
## Looks up a battle by name. The overworld starts fights with Game.start_battle("name", ...).


static func create(id: String) -> BattleData:
	# People around town you challenged (see townsfolk.gd).
	if id.begins_with("person_"):
		return Townsfolk.create_battle(id.trim_prefix("person_"))
	match id:
		"hopkuna":
			return HilltopBattles.create(id)
		"pop_quiz", "hall_pass", "mystery_meat", "tardy_bell", "overdue_book", "tent", "wally":
			return WestviewBattles.create(id)
		"training":
			return load("res://scripts/bunker_battles.gd").create(id)
		_:
			return TutorialBattle.create_data()
