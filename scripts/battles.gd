class_name Battles
extends RefCounted
## Looks up a battle by name. The overworld starts fights with Game.start_battle("name", ...).


static func create(id: String) -> BattleData:
	match id:
		"hopkuna":
			return HilltopBattles.create(id)
		"pop_quiz", "hall_pass", "mystery_meat", "tardy_bell", "overdue_book", "tent", "wally":
			return WestviewBattles.create(id)
		_:
			return TutorialBattle.create_data()
