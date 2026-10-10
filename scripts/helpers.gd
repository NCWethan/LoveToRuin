extends RefCounted
## The REVOLUTION Corps members Elric can CALL into a fight once they have joined the
## Corps (the Pacifist route): MERCY > Call a friend. Whoever is not in the party can
## be called: they run in, do their move, and leave. After any call, nobody can be
## called for 3 turns (see battle.gd, CALL_COOLDOWN).
##
## Each entry: their color, what's said when they arrive, the move's name, and:
##   kind      what the move does: "hit" (the default: one hit on an enemy, which
##             never knocks it out), "shield" (Big Joe: -80% damage for a turn), or
##             "food" (Eggo: whoever called him eats The-Eggo Benedict, +13 overheal),
##             "iframes" (Nassan: stays for the enemy turn; after each hit, the
##             SOUL is safe for twice as long), or "read" (Nat: +15% toward sparing
##             an enemy, and he reads out what every enemy will do next turn), or
##             "lightning" (N.C. Wethan: damage, and STRAVANT on the enemy: its
##             attacks are slower for 3 turns. Only below half HP), or "riff"
##             (Ronin: plays his guitar; after the riff, everyone gets 5 purple
##             overheal and AMPED, a faster SOUL), "analyze" (Supreme: the target is
##             ANALYZED, so FIGHT ignores its DEF and hits 50% harder), "card"
##             (Crayola: pick a card, any card: a random suit, a random good thing),
##             "roast" (Rooster: the target is ROASTED and hits for half; or it
##             roasts him back and he storms off), "plan" (Agent: the next enemy
##             turn is shorter and slower), "grill" (MuffinMage: everyone heals,
##             loses their bad effects, and is FED), or "honk" (Sansworth: every
##             enemy is STARTLED and skips its next attack)
##   cooldown  turns before they can be called again (default 3, the shared wait)
##   charges   how many times they can be called per battle (default: no limit)
## (A placeholder hit is still there for anyone without a move.)

const CORPS := ["BigJoe6", "Eggo", "Nassan", "Nat", "NCWethan", "Ronin", "Supreme", "Crayola", "Rooster", "Agent", "MuffinMage", "Sansworth"]

const HELPERS := {
	# Big Joe is a tank: he plants his shield in front of the party, and all damage is
	# cut by 80% for the next enemy turn. He needs 6 turns between calls (the usual 3,
	# then 3 more), and only comes twice per battle.
	"BigJoe6": {"color": Color(1.0, 0.82, 0.25), "line": "Big Joe charges in, shield first!", "move": "SHIELD WALL", "kind": "shield", "cooldown": 6, "charges": 2},
	# Eggo serves whoever called him The-Eggo Benedict: 13 overheal HP, on top of
	# their max (it stacks, up to 26). No extra wait; 2 charges per battle.
	"Eggo": {"color": Color(1.0, 0.9, 0.35), "line": "Eggo strolls in carrying a plate. \"order up.\"", "move": "THE-EGGO BENEDICT", "kind": "food", "charges": 2},
	# Nassan planned for this: he stays with the party through the next enemy turn,
	# and after every hit the SOUL stays invincible twice as long. 4 turns between
	# calls; no charge limit.
	"Nassan": {"color": Color(0.45, 0.65, 1.0), "line": "Nassan slides in. \"I planned for this.\"", "move": "CONTINGENCY PLAN", "kind": "iframes", "cooldown": 4},
	# Nat reads up on an enemy: it's 15% closer to being spared, and he tells you
	# what each enemy is going to do next turn (that's what they'll do). 1 charge.
	"Nat": {"color": Color(0.45, 0.85, 0.5), "line": "Nat wanders in, book over his face.\n* \"...I'm reading.\"", "move": "FOOTNOTE", "kind": "read", "charges": 1},
	# N.C. Wethan floats up and lets loose Stravant's Lightning: real damage, and the
	# enemy is STRAVANT for 3 turns (its attacks move slower). Only when whoever calls
	# him is below half HP. 1 charge per battle.
	"NCWethan": {"color": Color(0.45, 0.85, 1.0), "line": "N.C. Wethan bursts in! \"LIGHTNING TIME!!!\"", "move": "STRAVANT'S LIGHTNING", "kind": "lightning", "charges": 1, "low_hp": true},
	# Ronin plugs in and plays his riff (the whole thing). When it's over, everyone
	# gets 5 overheal (purple; it stacks with Eggo's blue) and is AMPED for 2 turns.
	"Ronin": {"color": Color(1.0, 0.55, 0.15), "line": "Ronin plugs in. \"THIS ONE'S FOR YOU GUYS!!\"", "move": "POWER RIFF", "kind": "riff"},
	# Supreme runs the numbers on the target: it's ANALYZED for 3 turns, and every
	# FIGHT hit on it ignores its DEF and does 50% more. 2 charges.
	"Supreme": {"color": Color(0.8, 0.82, 0.9), "line": "Supreme arrives with spreadsheet #4.\n* \"I've run the numbers on this one.\"", "move": "THREAT ASSESSMENT", "kind": "analyze", "charges": 2},
	# Crayola does his card trick: pick a card. Hearts heals everyone, Spades hits
	# the target, Diamonds is money, Clubs talks it down a little. 2 charges.
	"Crayola": {"color": Color(1.0, 0.55, 0.8), "line": "Crayola shyly steps in, shuffling.\n* \"...Pick a card?\"", "move": "PICK A CARD", "kind": "card", "charges": 2},
	# Rooster roasts the target: ROASTED for 2 turns, too embarrassed to hit hard
	# (half damage). One time in four, it roasts him back, and he storms off.
	"Rooster": {"color": Color(1.0, 0.3, 0.3), "line": "Rooster struts in, adjusting his top hat.\n* \"Oh, this'll be EASY.\"", "move": "ROAST", "kind": "roast"},
	# Agent calls the next enemy turn before it happens: it's 40% shorter, and
	# everything in it moves 20% slower. 4 turns between calls.
	"Agent": {"color": Color(0.7, 0.5, 1.0), "line": "Agent walks in. \"Three moves ahead.\"", "move": "THREE MOVES AHEAD", "kind": "plan", "cooldown": 4},
	# MuffinMage grills for everyone: +10 HP each, bad effects gone, and FED for 3
	# turns (+4 HP at the end of every enemy turn). 2 charges.
	"MuffinMage": {"color": Color(0.95, 0.5, 0.2), "line": "MuffinMage drops in with a tiny grill.\n* \"Yo. It's Friday somewhere.\"", "move": "SALMON BURGER FRIDAY", "kind": "grill", "charges": 2},
	# Sansworth honks the horn of a car he doesn't have. Every enemy is STARTLED
	# and skips its next attack. 1 charge.
	"Sansworth": {"color": Color(0.7, 0.7, 0.75), "line": "Sansworth runs in going \"VROOM.\"\n* He doesn't have a car. He has a horn.", "move": "HONK", "kind": "honk", "charges": 1},
}

## What Nat reads out about each attack ("its next attack: ...").
const PAGE_HINTS := {
	"straw": "straw, shaken out of its stuffing. It drifts.", "bullseye": "target rings, from the middle. Find the gap.",
	"rain": "yolk, raining down. Lots of it.", "egg_drop": "big eggs, dropped from above. They crack.",
	"bunny_hop": "bunnies. Hopping. They jump as high as you are.", "lance": "lances, from the sides. Watch your row.",
	"sweep": "a wall of shields with one gap.", "aimed": "gold stars, thrown right at you.",
	"pencils": "pencils, falling at an angle.", "bubbles": "answer bubbles that fly at where you were.",
	"papers": "hall passes, fluttering down.", "zoom": "a pass that dashes across. It flashes first.",
	"confetti": "confetti. A whole storm of it.", "foam_finger": "a giant foam finger, swinging through your row.",
	"dodgeballs": "dodgeballs. Bouncy ones.", "claw_swipe": "claw marks, raking right through you. Twice.",
	"claw_drop": "claws, plunging from the top.", "cleave": "slashes, through where you're standing.",
	"slash_grid": "three slashes crossing on you, one after another.", "red_arrows": "red arrows that curve toward you.",
	"burst": "a ring of shards closing in. One gap.", "fire_arrow": "one burning arrow. It follows you.",
	"scantron": "a column of answer bubbles. One is blank.", "tardy_slips": "tardy slips, sliding in from the corners.",
	"gravy": "gravy blobs that splatter.", "tray_toss": "lunch trays, spinning across.",
	"peas": "peas. A spread of them.", "ring": "a ring of notes, bursting out.",
	"sound_waves": "rolling sound waves, each with a quiet gap.", "alarm": "an alarm line that flickers, then blasts.",
	"sonar": "sonar rings. Slip through the gaps.", "clapper": "the clapper, swinging like a pendulum.",
	"pages": "loose pages. Fluttering. Rude.", "bookmark": "bookmarks, shot straight at you.",
	"shelf": "a sliding bookshelf with a gap.", "bleacher_wave": "bleachers rising from the floor, with a gap.",
	"mascot_spin": "a spinning twirl that flings claws.", "frenzy": "claws AND dodgeballs. Good luck.",
	"coaster_cars": "roller coaster cars, along the track.", "the_drop": "the big drop. From the top.",
	"loop_track": "the loop. Cars all the way around.", "sword_sweep": "three sword slashes from a top corner.",
	"armor_rain": "armor. Falling. Helmets first.", "shield_charge": "a shield, charging down your row.",
	"soup_waves": "soup. In waves. Hot.", "carving_knives": "knives and forks, from the sides.",
	"dessert_tray": "flan. Bouncing. One slides along the table.", "tortilla_toss": "tortillas, flipped way up.",
	"comal_heat": "a wall of heat with one cool spot.", "needle_spray": "cactus needles. A spray of them.",
	"maraca_beat": "maraca beats, on the beat.", "lantern_sweep": "a lantern beam, sweeping.",
	"ghost_story": "ghosts. They drift toward you.",
	"instant_replay": "your last turn, played back. Don't go there.", "kiss_cam": "a heart, closing in. One gap.",
	"the_wave": "the crowd doing the wave. Jump it.", "foul_ball": "foul balls, bouncing.",
	"fireworks": "fireworks. They burst where you are.", "scoreboard": "the score, falling. 0 to 7.",
	"hot_dog_toss": "hot dogs, lobbed in arcs.", "mustard_squirt": "mustard. A squiggly line of it.",
	"frozen_pose": "coins that stop in mid-air. Then don't.", "tip_jar": "coins, sprayed from a corner.",
	"rally_towel": "rally towels, spinning across.", "peanut_shells": "peanut shells. Bouncing.",
}
