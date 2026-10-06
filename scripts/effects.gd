extends RefCounted
## Status effects in battle: things that stay on someone for a few turns. They're
## shown on screen next to whoever has them, with how many turns are left.
##
## Effects count down at the end of every enemy turn (so "2 turns" means the rest
## of this enemy turn and the next one). Party members get them from enemy hits;
## enemies get them from friends you call in (see helpers.gd).

const EFFECTS := {
	# On enemies.
	"STRAVANT": {"color": Color(0.35, 0.55, 1.0), "what": "Struck by Stravant's Lightning: its attacks move slower."},
	# On the party.
	"STICKY": {"color": Color(1.0, 0.8, 0.2), "what": "Covered in goo: the SOUL moves 30% slower."},
	"SHAKEN": {"color": Color(0.8, 0.8, 0.9), "what": "Rattled: FIGHT does 30% less damage."},
	"DIZZY": {"color": Color(0.8, 0.5, 1.0), "what": "Seeing stars: the FIGHT bar moves faster."},
	"QUEASY": {"color": Color(0.6, 0.85, 0.3), "what": "Stomach's upset: food heals half as much."},
	"BURN": {"color": Color(1.0, 0.45, 0.15), "what": "On fire: lose 2 HP at the end of every enemy turn."},
	# Good ones, from friends.
	"AMPED": {"color": Color(0.75, 0.45, 1.0), "what": "Pumped up by Ronin's riff: the SOUL moves 30% faster."},
}

## What each enemy can do to you: [effect, chance per hit (0 to 1), turns].
const ENEMY_DEBUFFS := {
	"Eggo": ["STICKY", 0.3, 2],
	"Big Joe": ["SHAKEN", 0.3, 2],
	"Pop Quiz": ["DIZZY", 0.3, 2],
	"Hall Pass": ["DIZZY", 0.25, 2],
	"Mystery Meat": ["QUEASY", 0.4, 3],
	"Tardy Bell": ["DIZZY", 0.3, 2],
	"Overdue Book": ["SHAKEN", 0.3, 2],
	"Wally Wolverine": ["STICKY", 0.25, 2],
	"Hopkuna": ["BURN", 0.35, 3],
}

## Every attack's name, for the Encyclopedia.
const ATTACK_NAMES := {
	"rain": "Yolk Rain", "straw": "Straw Rain", "egg_drop": "Egg Drop", "bunny_hop": "Bunny Hop",
	"lance": "Lance Thrust", "sweep": "Shield Wall", "aimed": "Justice Stars",
	"pencils": "Pencil Rain", "bubbles": "Answer Bubbles", "scantron": "Scantron",
	"papers": "Fluttering Passes", "zoom": "Zoom", "tardy_slips": "Tardy Slips",
	"gravy": "Gravy Splat", "tray_toss": "Tray Toss", "peas": "Pea Spread",
	"sound_waves": "Sound Waves", "sonar": "Sonar", "clapper": "The Clapper", "ring": "Ring of Notes", "alarm": "Alarm",
	"pages": "Loose Pages", "bookmark": "Bookmarks", "shelf": "Sliding Shelf",
	"confetti": "Confetti", "claw_swipe": "Claw Swipe", "dodgeballs": "Dodgeballs", "claw_drop": "Claw Drop",
	"foam_finger": "Foam Finger", "bleacher_wave": "Rising Bleachers", "mascot_spin": "Mascot Spin", "frenzy": "FRENZY",
	"cleave": "Cleave", "red_arrows": "Red Arrows", "slash_grid": "Slash Grid", "burst": "Closing Ring", "fire_arrow": "Flaming Arrow",
}

## The Encyclopedia, in order: [battle id, enemy name].
const ENCYCLOPEDIA := [
	["tutorial", "Eggo"], ["tutorial", "Big Joe"],
	["pop_quiz", "Pop Quiz"], ["hall_pass", "Hall Pass"], ["mystery_meat", "Mystery Meat"],
	["tardy_bell", "Tardy Bell"], ["overdue_book", "Overdue Book"], ["wally", "Wally Wolverine"],
	["tent", "Tent"], ["hopkuna", "Hopkuna"], ["training", "Training Dummy"],
]


## Remembers that you've met an enemy (for the Encyclopedia).
static func mark_seen(enemy_name: String) -> void:
	var seen: Array = Game.flags.get("seen_enemies", [])
	if not enemy_name in seen:
		seen.append(enemy_name)
	Game.flags["seen_enemies"] = seen


static func seen(enemy_name: String) -> bool:
	return enemy_name in Game.flags.get("seen_enemies", [])


## The enemy itself (its picture, stats, attacks, ACTs), made fresh from its battle.
static func enemy_for(entry: Array) -> Enemy:
	var data: BattleData = Battles.create(entry[0])
	for enemy in data.enemies:
		if enemy.name == entry[1]:
			return enemy
	return null


## Counts down everyone's effects by one turn; ones that run out are removed.
static func tick(statuses: Dictionary) -> void:
	for effect in statuses.keys():
		statuses[effect] -= 1
		if statuses[effect] <= 0:
			statuses.erase(effect)
