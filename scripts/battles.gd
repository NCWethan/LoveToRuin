class_name Battles
extends RefCounted
## Looks up a battle by name. The overworld starts fights with Game.start_battle("name", ...).


static func create(id: String) -> BattleData:
	match id:
		"pop_quiz", "hall_pass", "mascot":
			return WestviewBattles.create(id)
		_:
			return TutorialBattle.create_data()
