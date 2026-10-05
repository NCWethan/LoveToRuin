extends RefCounted
## The REVOLUTION Corps members Elric can CALL into a fight once they have joined the
## Corps (the Pacifist route): MERCY > Call a friend. Whoever is not in the party can
## be called: they run in, do their move, and leave. After any call, nobody can be
## called for 3 turns (see battle.gd, CALL_COOLDOWN).
##
## Each entry: their color, what's said when they arrive, the move's name, and:
##   kind      what the move does: "hit" (the default: one hit on an enemy, which
##             never knocks it out), "shield" (Big Joe: -80% damage for a turn), or
##             "food" (Eggo: whoever called him eats The-Eggo Benedict, +13 overheal)
##   cooldown  turns before they can be called again (default 3, the shared wait)
##   charges   how many times they can be called per battle (default: no limit)
## Members without a decided ability yet use a placeholder hit.

const CORPS := ["BigJoe6", "Eggo", "Nassan", "Nat", "NCWethan", "Ronin", "Supreme", "Crayola", "Rooster", "Agent"]

const HELPERS := {
	# Big Joe is a tank: he plants his shield in front of the party, and all damage is
	# cut by 80% for the next enemy turn. He needs 6 turns between calls (the usual 3,
	# then 3 more), and only comes twice per battle.
	"BigJoe6": {"color": Color(1.0, 0.82, 0.25), "line": "Big Joe charges in, shield first!", "move": "SHIELD WALL", "kind": "shield", "cooldown": 6, "charges": 2},
	# Eggo serves whoever called him The-Eggo Benedict: 13 overheal HP, on top of
	# their max (it stacks, up to 26). No extra wait; 2 charges per battle.
	"Eggo": {"color": Color(1.0, 0.9, 0.35), "line": "Eggo strolls in carrying a plate. \"order up.\"", "move": "THE-EGGO BENEDICT", "kind": "food", "charges": 2},
	"Nassan": {"color": Color(0.45, 0.65, 1.0), "line": "Nassan slides in with a plan!", "move": "CALCULATED HIT"},
	"Nat": {"color": Color(0.45, 0.85, 0.5), "line": "Nat runs in, book open!", "move": "PAGE SLAP"},
	"NCWethan": {"color": Color(0.45, 0.85, 1.0), "line": "N.C. Wethan bursts in! LIGHTNING TIME!!!", "move": "LIGHTNING"},
	"Ronin": {"color": Color(1.0, 0.55, 0.15), "line": "Ronin strolls in, guitar first!", "move": "FIRE CHORD"},
	"Supreme": {"color": Color(0.8, 0.82, 0.9), "line": "Supreme arrives with a spreadsheet!", "move": "STATISTICAL STRIKE"},
	"Crayola": {"color": Color(1.0, 0.55, 0.8), "line": "Crayola shyly steps in!", "move": "CARD FLICK"},
	"Rooster": {"color": Color(1.0, 0.3, 0.3), "line": "Rooster struts in!", "move": "ROAST"},
	"Agent": {"color": Color(0.7, 0.5, 1.0), "line": "Agent walks in, already calculating!", "move": "THE ODDS"},
}
