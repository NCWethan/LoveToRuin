class_name WildBattles
extends RefCounted
## Wild creatures: the little things you can run into anywhere around town (not
## people, and not the Corps). Battles are "wild_<id>". Each area lists which
## ones live there (ZONES), and Area.check_random_encounter() picks one now and
## then as you walk.

const CREATURES := {
	# --- Chapter 2: The Junkyard ---
	"junk_rat": {
		"name": "Junk Rat", "sprite": "wild_junk_rat",
		"intro": "* A Junk Rat pops out of a tire.\n* It's wearing a bottle cap as a hat.",
		"hp": 100, "atk": 10, "def": 4, "patterns": ["rat_scurry", "rat_hoard"],
		"check": "* JUNK RAT - ATK 10 DEF 4\n* Collects things. Shiny things. Your things, if you let it.",
		"acts": [
			{"name": "Trade", "mercy": 50, "lines": ["* {actor} offers it a shiny button.\n* The Junk Rat inspects it. It accepts. A deal is a deal."]},
			{"name": "Admire Hoard", "mercy": 40, "lines": ["* {actor} admires its collection.\n* The Junk Rat shows you every single piece. Every one."]},
		],
		"taunts": ["*squeak*", "MINE MINE", "*rustle*"],
		"flavor": ["* The Junk Rat twitches its whiskers.", "* The Junk Rat has a collection, too.\n* It reminds you of someone."],
		"backdrop": Color(0.45, 0.4, 0.35), "style": "grid", "exp": 34, "money": 25,
	},
	"magnet": {
		"name": "Magnet", "sprite": "wild_magnet",
		"intro": "* A Magnet drags itself over, covered in bolts.\n* Everything metal leans toward it.",
		"hp": 106, "atk": 10, "def": 6, "patterns": ["magnet_pull", "magnet_scrap"],
		"check": "* MAGNET - ATK 10 DEF 6\n* Fell off the crane. Everything sticks to it. Nothing stays.",
		"acts": [
			{"name": "Flip It", "mercy": 50, "lines": ["* {actor} flips it around.\n* Everything stuck to it falls off. The Magnet sighs with relief."]},
			{"name": "Stick Around", "mercy": 40, "lines": ["* {actor} says they'll stick around.\n* The Magnet has never heard that from anything not made of metal."]},
		],
		"taunts": ["*hummm*", "*CLINK*", "STAY."],
		"flavor": ["* Screws crawl across the ground toward the Magnet.", "* Your belt buckle is trying to leave you."],
		"backdrop": Color(0.55, 0.2, 0.2), "style": "static", "exp": 35, "money": 22,
	},
	"hubcap": {
		"name": "Hubcap", "sprite": "wild_hubcap",
		"intro": "* A Hubcap comes rolling out of nowhere!\n* It's been rolling since the freeway.",
		"hp": 98, "atk": 10, "def": 5, "patterns": ["hubcap_roll", "hubcap_glint"],
		"check": "* HUBCAP - ATK 10 DEF 5\n* Came off a car on the 15 in 2011. Still rolling. Can't stop.",
		"acts": [
			{"name": "Catch It", "mercy": 50, "lines": ["* {actor} catches it. It wobbles, and stops.\n* The Hubcap hasn't stopped in years. It's dizzy. It's grateful."]},
			{"name": "Polish", "mercy": 40, "lines": ["* {actor} polishes it with a sleeve.\n* The Hubcap gleams. It sees itself. It looks good."]},
		],
		"taunts": ["*wobblewobble*", "*CLANG*", "*whirrr*"],
		"flavor": ["* The Hubcap spins in place.", "* The Hubcap catches the light, and blinds you a little.\n* On purpose."],
		"backdrop": Color(0.5, 0.5, 0.55), "style": "skyline", "exp": 35, "money": 24,
	},
	# --- Chapter 2: The Burned Hills ---
	"cinder": {
		"name": "Cinder", "sprite": "wild_cinder",
		"intro": "* A Cinder hops out of the ash.\n* It's still warm. It's very proud of that.",
		"hp": 96, "atk": 9, "def": 4, "patterns": ["cinder_spark", "cinder_pop"],
		"check": "* CINDER - ATK 9 DEF 4\n* A piece of the old fire that never went out. Five years old.",
		"acts": [
			{"name": "Warm Hands", "mercy": 50, "lines": ["* {actor} warms their hands over it.\n* The Cinder glows brighter. Somebody needed it."]},
			{"name": "Tell It Rest", "mercy": 40, "lines": ["* {actor} tells it it can stop now.\n* The Cinder flickers. Nobody ever told it that."]},
		],
		"taunts": ["*crackle*", "*pop*", "STILL HOT"],
		"flavor": ["* The Cinder smolders.", "* The Cinder bounces from foot to foot.\n* Which is to say, from side to side. It has no feet."],
		"backdrop": Color(0.6, 0.25, 0.1), "style": "shards", "exp": 31, "money": 18,
	},
	"smoke_wraith": {
		"name": "Smoke Wraith", "sprite": "wild_smoke_wraith",
		"intro": "* A Smoke Wraith rises off the hill.\n* Your eyes water.",
		"hp": 92, "atk": 9, "def": 2, "patterns": ["smoke_veil", "smoke_choke"],
		"check": "* SMOKE WRAITH - ATK 9 DEF 2\n* Hung over these hills since the fire. Wants to see the sky.",
		"acts": [
			{"name": "Fan", "mercy": 50, "lines": ["* {actor} fans it gently upward.\n* The Smoke Wraith rises a little. Toward the sky. It looks up."]},
			{"name": "Hold Breath", "mercy": 40, "lines": ["* {actor} holds their breath and waits.\n* The Smoke Wraith is touched. People usually cough at it."]},
		],
		"taunts": ["*cough*", "...hhhh...", "*drift*"],
		"flavor": ["* The Smoke Wraith thins and thickens.", "* You can't tell where the Smoke Wraith ends\n* and the sky begins."],
		"backdrop": Color(0.4, 0.38, 0.38), "style": "static", "exp": 32, "money": 15,
	},
	"charred_stump": {
		"name": "Charred Stump", "sprite": "wild_charred_stump",
		"intro": "* A Charred Stump pulls up its roots.\n* It's had enough of standing around.",
		"hp": 100, "atk": 9, "def": 6, "patterns": ["stump_roots", "stump_splinters"],
		"check": "* CHARRED STUMP - ATK 9 DEF 6\n* Was a tree once. Remembers all of it. Angry about the rest.",
		"acts": [
			{"name": "Plant Seed", "mercy": 50, "lines": ["* {actor} plants a seed by its roots.\n* The Charred Stump goes very still. Something's growing."]},
			{"name": "Count Rings", "mercy": 40, "lines": ["* {actor} counts its rings out loud. 84.\n* The Charred Stump didn't know it was that old. It feels wise."]},
		],
		"taunts": ["*creak*", "*CRACK*", "MY HILL."],
		"flavor": ["* The Charred Stump shifts its roots.", "* There's a tiny green shoot on top of the Charred Stump.\n* It hasn't noticed."],
		"backdrop": Color(0.35, 0.25, 0.2), "style": "leaves", "exp": 33, "money": 20,
	},
	# --- Chapter 2: Torrey Pines ---
	"rattlesnake": {
		"name": "Rattlesnake", "sprite": "wild_rattlesnake",
		"intro": "* A Rattlesnake rattles a warning.\n* You should probably listen.",
		"hp": 92, "atk": 9, "def": 4, "patterns": ["snake_strike", "snake_rattle"],
		"check": "* RATTLESNAKE - ATK 9 DEF 4\n* Doesn't want to fight. Will if it has to. It has warned you.",
		"acts": [
			{"name": "Back Away", "mercy": 50, "lines": ["* {actor} backs away, slowly.\n* The Rattlesnake stops rattling. That's all it wanted."]},
			{"name": "Give Space", "mercy": 40, "lines": ["* {actor} steps off the trail.\n* The Rattlesnake appreciates a person who reads the signs."]},
		],
		"taunts": ["*tktktktk*", "HSSS", "*rattle*"],
		"flavor": ["* The Rattlesnake coils up. The rattle never stops.", "* There's a sign behind the Rattlesnake:\n* STAY ON THE TRAIL. It's lying on the trail."],
		"backdrop": Color(0.7, 0.55, 0.3), "style": "cliffs", "exp": 29, "money": 18,
	},
	"fog_wisp": {
		"name": "Fog Wisp", "sprite": "wild_fog_wisp",
		"intro": "* A Fog Wisp drifts out of the white.\n* You could walk right through it. You don't.",
		"hp": 86, "atk": 9, "def": 2, "patterns": ["wisp_fade", "wisp_curl"],
		"check": "* FOG WISP - ATK 9 DEF 2\n* A little piece of the fog that got lost. It wants to be found.",
		"acts": [
			{"name": "Call Out", "mercy": 50, "lines": ["* {actor} calls \"Hello?\" into the fog.\n* The Fog Wisp answers! It's never been called before."]},
			{"name": "Stand Still", "mercy": 40, "lines": ["* {actor} stands very still.\n* The Fog Wisp drifts closer, curious. It's cold. It's nice."]},
		],
		"taunts": ["...", "*whooo*", "(lost)"],
		"flavor": ["* The Fog Wisp curls around your ankles.", "* You can see the trees through the Fog Wisp.\n* They look further away than they are."],
		"backdrop": Color(0.75, 0.8, 0.85), "style": "static", "exp": 30, "money": 15,
	},
	"lost_kite": {
		"name": "Lost Kite", "sprite": "wild_lost_kite",
		"intro": "* A Lost Kite tumbles down out of the sky.\n* Its string has nobody on the other end.",
		"hp": 90, "atk": 9, "def": 3, "patterns": ["lostkite_tangle", "lostkite_loop"],
		"check": "* LOST KITE - ATK 9 DEF 3\n* Got away from a kid at the gliderport. In 2019.",
		"acts": [
			{"name": "Grab String", "mercy": 50, "lines": ["* {actor} catches the string.\n* The Lost Kite tugs once, gently. It's being held again."]},
			{"name": "Run", "mercy": 40, "lines": ["* {actor} runs into the wind with it.\n* The Lost Kite soars. It forgot it could do that."]},
		],
		"taunts": ["*flap flap*", "*whoosh*", "(where?)"],
		"flavor": ["* The Lost Kite loops in the wind.", "* The Lost Kite's tail is tangled with three other\n*  kites' tails. A support group."],
		"backdrop": Color(0.45, 0.65, 0.85), "style": "cliffs", "exp": 29, "money": 16,
	},
	# --- Chapter 2: The Harbor ---
	"gull_captain": {
		"name": "Gull Captain", "sprite": "wild_gull_captain",
		"intro": "* A Gull Captain lands on the rail.\n* It salutes. It wants your fish taco.",
		"hp": 88, "atk": 8, "def": 4, "patterns": ["gull_dive", "gull_cap"],
		"check": "* GULL CAPTAIN - ATK 8 DEF 4\n* Found the hat in 1987. Has been in charge ever since.",
		"acts": [
			{"name": "Salute", "mercy": 50, "lines": ["* {actor} salutes back, crisply.\n* The Gull Captain puffs out its chest. Finally, discipline."]},
			{"name": "Aye Aye", "mercy": 40, "lines": ["* {actor} says \"Aye aye, Captain!\"\n* The Gull Captain has waited its whole life for that."]},
		],
		"taunts": ["SKRAA!", "*flap*", "MINE."],
		"flavor": ["* The Gull Captain inspects you. You fail.", "* The Gull Captain's hat is three sizes too big.\n* It is extremely proud of it."],
		"backdrop": Color(0.3, 0.5, 0.75), "style": "waves", "exp": 26, "money": 18,
	},
	"lobster_trap": {
		"name": "Lobster Trap", "sprite": "wild_lobster_trap",
		"intro": "* A Lobster Trap scuttles out on its own.\n* The lobster inside is driving.",
		"hp": 94, "atk": 8, "def": 6, "patterns": ["trap_snap", "trap_rope"],
		"check": "* LOBSTER TRAP - ATK 8 DEF 6\n* The lobster got in. The lobster stayed. It's home now.",
		"acts": [
			{"name": "Open Door", "mercy": 50, "lines": ["* {actor} opens the little door.\n* The lobster looks out. ...It closes the door again. Cozy."]},
			{"name": "Compliment", "mercy": 40, "lines": ["* {actor} compliments the craftsmanship.\n* The lobster clicks its claws, flattered."]},
		],
		"taunts": ["*click click*", "*creak*", "SNIP"],
		"flavor": ["* The Lobster Trap drips seawater.", "* The lobster is waving. You're not sure it's friendly."],
		"backdrop": Color(0.2, 0.35, 0.5), "style": "bubbles", "exp": 27, "money": 22,
	},
	"rust_bot": {
		"name": "Rust Bot", "sprite": "wild_rust_bot",
		"intro": "* A Rust Bot clanks out of the engine room.\n* It hasn't been oiled since the war.",
		"hp": 90, "atk": 9, "def": 5, "patterns": ["rust_bolts", "rust_laser"],
		"check": "* RUST BOT - ATK 9 DEF 5\n* Built to fix the engines. Nobody told it they stopped.",
		"acts": [
			{"name": "Oil It", "mercy": 50, "lines": ["* {actor} oils its joints.\n* The Rust Bot moves its arm without screeching. It weeps oil."]},
			{"name": "Thank It", "mercy": 40, "lines": ["* {actor} tells it the engines were well kept.\n* The Rust Bot's eye glows a little softer."]},
		],
		"taunts": ["*CLANK*", "SCREEEECH", "MAINTENANCE."],
		"flavor": ["* The Rust Bot creaks. Flakes of rust drift down.", "* The Rust Bot is still holding a wrench from 1972."],
		"backdrop": Color(0.55, 0.35, 0.25), "style": "carrier", "exp": 28, "money": 20,
	},
	# --- Chapter 2: Downtown ---
	"pigeon_gang": {
		"name": "Pigeon Gang", "sprite": "wild_pigeon_gang",
		"intro": "* The Pigeon Gang surrounds you.\n* They're wearing tiny bandanas.",
		"hp": 82, "atk": 8, "def": 3, "patterns": ["pigeon_swoop", "pigeon_crumbs"],
		"check": "* PIGEON GANG - ATK 8 DEF 3\n* Run this block. Want your fries. All of them.",
		"acts": [
			{"name": "Share Fries", "mercy": 50, "lines": ["* {actor} tosses them a fry.\n* The Pigeon Gang has never been offered anything. They're stunned."]},
			{"name": "Coo", "mercy": 40, "lines": ["* {actor} coos. Badly.\n* The Pigeon Gang coos back, out of pity."]},
		],
		"taunts": ["COO.", "*flap flap*", "FRIES."],
		"flavor": ["* The Pigeon Gang bobs its heads in unison. Menacingly.", "* One of the pigeons is just a guy in a pigeon costume.\n* Nobody mentions it."],
		"backdrop": Color(0.45, 0.45, 0.55), "style": "skyline", "exp": 23, "money": 16,
	},
	"parking_meter": {
		"name": "Parking Meter", "sprite": "wild_parking_meter",
		"intro": "* A Parking Meter blocks your path.\n* Its little flag says EXPIRED.",
		"hp": 90, "atk": 8, "def": 5, "patterns": ["meter_coins", "meter_expired"],
		"check": "* PARKING METER - ATK 8 DEF 5\n* Has given out 40,000 tickets. Has never been thanked.",
		"acts": [
			{"name": "Feed It", "mercy": 50, "lines": ["* {actor} feeds it a quarter.\n* The flag flips to TIME LEFT. It hasn't felt this full in years."]},
			{"name": "Thank It", "mercy": 40, "lines": ["* {actor} thanks it for its service.\n* The Parking Meter makes a small, grateful ding."]},
		],
		"taunts": ["EXPIRED", "*ding*", "*tick tick*"],
		"flavor": ["* The Parking Meter ticks.", "* The Parking Meter is judging where you're standing.\n* It's a loading zone."],
		"backdrop": Color(0.35, 0.4, 0.5), "style": "grid", "exp": 24, "money": 25,
	},
	"neon_sign": {
		"name": "Neon Sign", "sprite": "wild_neon_sign",
		"intro": "* A Neon Sign buzzes to life!\n* Half its letters are out.",
		"hp": 80, "atk": 8, "def": 2, "patterns": ["neon_flicker", "neon_buzz"],
		"check": "* NEON SIGN - ATK 8 DEF 2\n* Used to say OPEN. Now says OP N. It's sensitive about it.",
		"acts": [
			{"name": "Fix Letter", "mercy": 50, "lines": ["* {actor} jiggles the loose E.\n* It flickers back on. OPEN. The sign glows with pride."]},
			{"name": "Read It", "mercy": 40, "lines": ["* {actor} reads it out loud: \"OP N!\"\n* Close enough. The sign is moved."]},
		],
		"taunts": ["*bzzzt*", "OP N", "*hummmm*"],
		"flavor": ["* The Neon Sign flickers. Off. On. Off.", "* Moths are circling the Neon Sign. It loves them."],
		"backdrop": Color(0.6, 0.2, 0.55), "style": "static", "exp": 25, "money": 15,
	},
	# --- Chapter 2: Old Town ---
	"tumbleweed": {
		"name": "Tumbleweed", "sprite": "wild_tumbleweed",
		"intro": "* A Tumbleweed rolls up.\n* It stops. Right in front of you. On purpose.",
		"hp": 78, "atk": 7, "def": 3, "patterns": ["weed_roll", "weed_gust"],
		"check": "* TUMBLEWEED - ATK 7 DEF 3\n* Has rolled here all the way from Arizona. Won't say why.",
		"acts": [
			{"name": "Whistle", "mercy": 50, "lines": ["* {actor} whistles a lonesome tune.\n* The Tumbleweed rolls back and forth, slowly. It's dancing."]},
			{"name": "Untangle", "mercy": 40, "lines": ["* {actor} picks a candy wrapper out of it.\n* It feels lighter. It rolls a happy little circle."]},
		],
		"taunts": ["*rustle*", "*tumble*", "..."],
		"flavor": ["* The Tumbleweed drifts in a wind you can't feel.", "* There's a sock in the Tumbleweed.\n* Nobody asks."],
		"backdrop": Color(0.75, 0.55, 0.35), "style": "plaza", "exp": 19, "money": 12,
	},
	"pinata": {
		"name": "Piñata", "sprite": "wild_pinata",
		"intro": "* A Piñata swings down from the papel picado!\n* It's FULL.",
		"hp": 86, "atk": 8, "def": 3, "patterns": ["pinata_candy", "pinata_swing"],
		"check": "* PIÑATA - ATK 8 DEF 3\n* Survived three birthday parties. Has opinions about sticks.",
		"acts": [
			{"name": "Sing", "mercy": 50, "lines": ["* {actor} sings \"Dale, dale, dale.\"\n* The Piñata sways along. It knows all the words."]},
			{"name": "Put Stick Down", "mercy": 40, "lines": ["* {actor} puts down the stick. Nobody had a stick.\n* The Piñata relaxes anyway."]},
		],
		"taunts": ["DALE DALE", "*crinkle*", "NOT THE STICK"],
		"flavor": ["* The Piñata twirls on its string.", "* Candy rattles inside the Piñata. It's a little smug about it."],
		"backdrop": Color(0.85, 0.35, 0.55), "style": "banners", "exp": 21, "money": 18,
	},
	"wax_ghost": {
		"name": "Wax Ghost", "sprite": "wild_wax_ghost",
		"intro": "* A Wax Ghost drips out of the shadows.\n* Its little flame flickers at you.",
		"hp": 80, "atk": 8, "def": 2, "patterns": ["wax_drip", "wax_flame"],
		"check": "* WAX GHOST - ATK 8 DEF 2\n* Was a candle. Burned all the way down. Kept going.",
		"acts": [
			{"name": "Shield Flame", "mercy": 50, "lines": ["* {actor} cups their hands around its little flame.\n* It stops flickering. It feels safe."]},
			{"name": "Make a Wish", "mercy": 40, "lines": ["* {actor} makes a wish, and doesn't blow.\n* The Wax Ghost has waited a long time for that."]},
		],
		"taunts": ["*drip*", "*fssss*", "...warm..."],
		"flavor": ["* The Wax Ghost drips on the floor. The drips crawl back.", "* Its flame leans toward you, like it's listening."],
		"backdrop": Color(0.45, 0.3, 0.55), "style": "stars", "exp": 22, "money": 14,
	},
	# --- Chapter 2: Balboa Park ---
	"peacock": {
		"name": "Peacock", "sprite": "wild_peacock",
		"intro": "* A Peacock fans its tail at you.\n* Every eye on it is staring.",
		"hp": 72, "atk": 7, "def": 3, "patterns": ["peacock_fan", "peacock_strut"],
		"check": "* PEACOCK - ATK 7 DEF 3\n* Lives in the park. Owns the park. Ask it.",
		"acts": [
			{"name": "Admire", "mercy": 50, "lines": ["* {actor} admires its feathers. Out loud.\n* The Peacock turns, slowly, so you get every angle."]},
			{"name": "Strut", "mercy": 40, "lines": ["* {actor} struts back at it.\n* The Peacock stops. It respects the commitment."]},
		],
		"taunts": ["*MEEE-OWW*", "*rustle*", "*AAAAH*"],
		"flavor": ["* The Peacock's tail shimmers.", "* The Peacock screams for no reason.\n*  Peacocks do that."],
		"backdrop": Color(0.3, 0.6, 0.55), "style": "leaves", "exp": 17, "money": 10,
	},
	"marble_bust": {
		"name": "Marble Bust", "sprite": "wild_marble_bust",
		"intro": "* A Marble Bust has rolled off its pedestal,\n*  and it is FURIOUS about it.",
		"hp": 80, "atk": 7, "def": 4, "patterns": ["bust_roll", "bust_glare"],
		"check": "* MARBLE BUST - ATK 7 DEF 4\n* Some general. Or a poet. The plaque fell off.",
		"acts": [
			{"name": "Read Plaque", "mercy": 50, "lines": ["* {actor} finds the plaque and reads it out loud.\n* The Bust remembers who it is. It stands taller."]},
			{"name": "Dust It", "mercy": 40, "lines": ["* {actor} dusts off its nose.\n* Two hundred years. Nobody ever dusted the nose."]},
		],
		"taunts": ["...", "*crack*", "HMPH"],
		"flavor": ["* The Marble Bust stares blankly.\n*  It has no pupils. Somehow you feel judged.", "* The Marble Bust is missing its nose. Rude to mention."],
		"backdrop": Color(0.7, 0.68, 0.62), "style": "stripes", "exp": 19, "money": 12,
	},
	"tour_group": {
		"name": "Tour Group", "sprite": "wild_tour_group",
		"intro": "* A Tour Group surrounds you!\n* Their guide holds the flag high.",
		"hp": 76, "atk": 7, "def": 2, "patterns": ["tour_flags", "tour_flash"],
		"check": "* TOUR GROUP - ATK 7 DEF 2\n* Twelve people, one flag, no idea where they are.",
		"acts": [
			{"name": "Give Directions", "mercy": 50, "lines": ["* {actor} points them to the museum.\n* Twelve people say THANK YOU at slightly different times."]},
			{"name": "Pose", "mercy": 40, "lines": ["* {actor} poses for a photo.\n* Everyone takes one. Nobody checks if it's good."]},
		],
		"taunts": ["*click click*", "IS THIS THE ZOO?", "*murmur*"],
		"flavor": ["* The Tour Group shuffles in a tight circle.", "* Somebody in the back is still eating a churro."],
		"backdrop": Color(0.75, 0.55, 0.4), "style": "plaza", "exp": 18, "money": 15,
	},
	# --- Chapter 2: Mission Beach ---
	"sand_crab": {
		"name": "Sand Crab", "sprite": "wild_sand_crab",
		"intro": "* A Sand Crab bursts up out of the sand,\n*  claws first!",
		"hp": 70, "atk": 6, "def": 3, "patterns": ["crab_pinch", "crab_scuttle"],
		"check": "* SAND CRAB - ATK 6 DEF 3\n* Walks sideways. Thinks sideways. Is never wrong.",
		"acts": [
			{"name": "Walk Sideways", "mercy": 50, "lines": ["* {actor} walks sideways too.\n* The Sand Crab is impressed. Finally, someone gets it."]},
			{"name": "Offer Shell", "mercy": 40, "lines": ["* {actor} holds out a nice shell.\n* The crab considers it. It's a very good shell."]},
		],
		"taunts": ["*click click*", "*CLACK*", "*bubble*"],
		"flavor": ["* The Sand Crab snaps its claws.", "* The Sand Crab is guarding a sandcastle\n*  nobody asked it to guard."],
		"backdrop": Color(0.85, 0.75, 0.5), "style": "waves", "exp": 14, "money": 9,
	},
	"jellyfish": {
		"name": "Jellyfish", "sprite": "wild_jellyfish",
		"intro": "* A Jellyfish wobbles up out of the surf.\n* It shouldn't be able to do that.",
		"hp": 60, "atk": 7, "def": 1, "patterns": ["jelly_drift", "jelly_sting"],
		"check": "* JELLYFISH - ATK 7 DEF 1\n* No brain, no heart, no bones. Plenty of sting.",
		"acts": [
			{"name": "Float", "mercy": 50, "lines": ["* {actor} lies back and floats.\n* The Jellyfish floats too. You're both just... drifting."]},
			{"name": "Back to Sea", "mercy": 40, "lines": ["* {actor} points at the ocean.\n* The Jellyfish looks. It looks for a long time."]},
		],
		"taunts": ["*bloop*", "...", "*wobble*"],
		"flavor": ["* The Jellyfish pulses gently.", "* You can see right through it.\n*  It's thinking about nothing at all."],
		"backdrop": Color(0.3, 0.55, 0.85), "style": "waves", "exp": 15, "money": 7,
	},
	"beach_kite": {
		"name": "Runaway Kite", "sprite": "wild_beach_kite",
		"intro": "* A Runaway Kite swoops down at you,\n*  string trailing!",
		"hp": 64, "atk": 7, "def": 2, "patterns": ["kite_dive", "kite_string"],
		"check": "* RUNAWAY KITE - ATK 7 DEF 2\n* Snapped its string at 9 AM. Never coming down.",
		"acts": [
			{"name": "Grab String", "mercy": 50, "lines": ["* {actor} grabs the trailing string.\n* The Kite tugs, then lets itself be held."]},
			{"name": "Run With It", "mercy": 40, "lines": ["* {actor} runs down the beach with it.\n* The Kite soars. It's the best day of its life."]},
		],
		"taunts": ["*flap*", "*WHOOSH*", "*rustle*"],
		"flavor": ["* The Runaway Kite loops the loop.", "* Somewhere, a kid is still holding\n*  the other end of a string."],
		"backdrop": Color(0.55, 0.8, 0.95), "style": "cliffs", "exp": 15, "money": 8,
	},
	"cart": {
		"name": "Runaway Cart", "sprite": "wild_cart",
		"intro": "* A shopping cart rattles toward you!\n* Nobody is pushing it.",
		"hp": 40, "atk": 4, "def": 1, "patterns": ["cart_ram", "coin_roll"],
		"check": "* RUNAWAY CART - ATK 4 DEF 1\n* Escaped the cart corral. Never looked back.",
		"acts": [
			{"name": "Return It", "mercy": 60, "lines": ["* {actor} walks the cart back to the corral.\n* It rattles. Gratefully?"]},
			{"name": "Fix Wheel", "mercy": 40, "lines": ["* {actor} straightens its wobbly wheel.\n* It rolls in a straight line for the first time ever."]},
		],
		"taunts": ["*rattle*", "*squeak squeak*", "*CLANK*"],
		"flavor": ["* The Runaway Cart's wheel wobbles.", "* There's a single coupon in its child seat."],
		"backdrop": Color(0.75, 0.35, 0.3), "style": "skyline", "exp": 6, "money": 5,
	},
	"receipt": {
		"name": "Receipt", "sprite": "wild_receipt",
		"intro": "* A very, very long receipt\n*  curls up in front of you.",
		"hp": 32, "atk": 3, "def": 0, "patterns": ["receipt_ribbon", "ink_blots"],
		"check": "* RECEIPT - ATK 3 DEF 0\n* Four feet long. You bought one gum.",
		"acts": [
			{"name": "Read It", "mercy": 50, "lines": ["* {actor} reads every line.\n* The Receipt has never felt so seen."]},
			{"name": "Fold", "mercy": 50, "lines": ["* {actor} folds it neatly.\n* It's a lot shorter now. It looks relieved."]},
		],
		"taunts": ["SAVE 10%!", "THANK YOU!", "SURVEY!!"],
		"flavor": ["* The Receipt keeps printing.", "* Take our survey for a chance to win!"],
		"backdrop": Color(0.8, 0.8, 0.8), "style": "skyline", "exp": 5, "money": 4,
	},
	"balloon": {
		"name": "Lost Balloon", "sprite": "wild_balloon",
		"intro": "* A Lost Balloon drifts down to you.",
		"hp": 28, "atk": 3, "def": 0, "patterns": ["balloon_rise", "balloon_pop"],
		"check": "* LOST BALLOON - ATK 3 DEF 0\n* Somebody let go. It's been looking for them all day.",
		"acts": [
			{"name": "Hold String", "mercy": 60, "lines": ["* {actor} holds its string.\n* For a moment, it isn't lost."]},
			{"name": "Look Around", "mercy": 40, "lines": ["* {actor} looks around for whoever lost it.\n* ...Nobody. The balloon sags a little."]},
		],
		"taunts": ["...", "*squeak*", "(bob)"],
		"flavor": ["* The Lost Balloon bobs sadly.", "* Its string trails behind it."],
		"backdrop": Color(0.9, 0.4, 0.5), "style": "skyline", "exp": 5, "money": 2,
	},
	"goose": {
		"name": "Goose", "sprite": "wild_goose",
		"intro": "* HONK.",
		"hp": 50, "atk": 5, "def": 1, "patterns": ["goose_chase", "feathers"],
		"check": "* GOOSE - ATK 5 DEF 1\n* Has no reason to be angry. Is angry.",
		"acts": [
			{"name": "Back Away", "mercy": 50, "lines": ["* {actor} slowly backs away.\n* The Goose accepts this as surrender."]},
			{"name": "Honk Back", "mercy": 50, "lines": ["* {actor} honks back.\n* The Goose stares. A mutual respect forms."]},
		],
		"taunts": ["HONK", "HONK!!", "hiss"],
		"flavor": ["* The Goose spreads its wings.", "* The Goose is looking directly at you."],
		"backdrop": Color(0.4, 0.65, 0.35), "style": "leaves", "exp": 8, "money": 3,
	},
	"sprinkler": {
		"name": "Sprinkler", "sprite": "wild_sprinkler",
		"intro": "* A sprinkler pops up out of the grass!",
		"hp": 38, "atk": 4, "def": 2, "patterns": ["spray_arc", "puddle_splash"],
		"check": "* SPRINKLER - ATK 4 DEF 2\n* On a timer. The timer is broken.",
		"acts": [
			{"name": "Turn Off", "mercy": 60, "lines": ["* {actor} twists the valve.\n* The Sprinkler sputters, and calms down."]},
			{"name": "Run Through", "mercy": 40, "lines": ["* {actor} runs through the spray.\n* ...Okay, that was actually fun."]},
		],
		"taunts": ["tick tick tick", "*fsssh*", "tick tick"],
		"flavor": ["* The Sprinkler ticks around.", "* Everything nearby is soaked."],
		"backdrop": Color(0.3, 0.6, 0.8), "style": "leaves", "exp": 6, "money": 2,
	},
	"gnome": {
		"name": "Garden Gnome", "sprite": "wild_gnome",
		"intro": "* A Garden Gnome is standing in the path.\n* It wasn't there a second ago.",
		"hp": 44, "atk": 4, "def": 3, "patterns": ["gnome_hats", "tiny_shovels"],
		"check": "* GARDEN GNOME - ATK 4 DEF 3\n* Moves when nobody's looking. You're looking.",
		"acts": [
			{"name": "Look Away", "mercy": 50, "lines": ["* {actor} looks away.\n* When they look back, the gnome is smiling."]},
			{"name": "Compliment Hat", "mercy": 50, "lines": ["* {actor} says it's a great hat.\n* The gnome stands a little taller."]},
		],
		"taunts": ["...", "(stares)", "(doesn't move)"],
		"flavor": ["* The Garden Gnome hasn't blinked.", "* Its tiny shovel is very sharp."],
		"backdrop": Color(0.35, 0.55, 0.3), "style": "leaves", "exp": 7, "money": 4,
	},
	"flamingo": {
		"name": "Lawn Flamingo", "sprite": "wild_flamingo",
		"intro": "* A plastic Lawn Flamingo\n*  steps off its lawn.",
		"hp": 40, "atk": 4, "def": 1, "patterns": ["flamingo_stomp", "pink_feathers"],
		"check": "* LAWN FLAMINGO - ATK 4 DEF 1\n* Plastic. Fabulous. Stands on one leg out of spite.",
		"acts": [
			{"name": "Stand on One Leg", "mercy": 60, "lines": ["* {actor} stands on one leg.\n* The flamingo is impressed. Reluctantly."]},
			{"name": "Admire", "mercy": 40, "lines": ["* {actor} admires its pinkness.\n* It knows."]},
		],
		"taunts": ["*clack*", "Fabulous.", "*wobble*"],
		"flavor": ["* The Lawn Flamingo balances perfectly.", "* It's very, very pink."],
		"backdrop": Color(0.95, 0.5, 0.7), "style": "leaves", "exp": 6, "money": 4,
	},
	"seagull": {
		"name": "Hungry Seagull", "sprite": "wild_seagull",
		"intro": "* A Hungry Seagull swoops down!\n* It thinks you have fries.",
		"hp": 34, "atk": 4, "def": 0, "patterns": ["seagull_dive", "fry_steal"],
		"check": "* HUNGRY SEAGULL - ATK 4 DEF 0\n* Has eaten 40 fries today. Wants 41.",
		"acts": [
			{"name": "Show Hands", "mercy": 50, "lines": ["* {actor} shows their empty hands.\n* The seagull does not believe them."]},
			{"name": "Share Snack", "mercy": 50, "lines": ["* {actor} shares a crumb.\n* The seagull screams with joy."]},
		],
		"taunts": ["MINE", "MINE!", "Fry?"],
		"flavor": ["* The Hungry Seagull eyes your pockets.", "* It smells like the beach."],
		"backdrop": Color(0.45, 0.7, 0.9), "style": "waves", "exp": 6, "money": 3,
	},
	"squirrel": {
		"name": "Squirrel", "sprite": "wild_squirrel",
		"intro": "* A Squirrel freezes in front of you.\n* Then it doesn't.",
		"hp": 26, "atk": 3, "def": 0, "patterns": ["acorn_drop", "squirrel_dash"],
		"check": "* SQUIRREL - ATK 3 DEF 0\n* Hid 200 acorns this year. Remembers 3.",
		"acts": [
			{"name": "Hold Still", "mercy": 50, "lines": ["* {actor} holds very still.\n* The Squirrel holds very still too."]},
			{"name": "Offer Acorn", "mercy": 50, "lines": ["* {actor} offers an acorn.\n* It's buried immediately. Somewhere. Forever."]},
		],
		"taunts": ["chk chk!", "!!", "chk?"],
		"flavor": ["* The Squirrel twitches its tail.", "* It has an acorn in each cheek."],
		"backdrop": Color(0.6, 0.45, 0.25), "style": "leaves", "exp": 5, "money": 2,
	},
	"bag": {
		"name": "Plastic Bag", "sprite": "wild_bag",
		"intro": "* A Plastic Bag drifts by on the wind.",
		"hp": 24, "atk": 3, "def": 0, "patterns": ["bag_drift", "gust"],
		"check": "* PLASTIC BAG - ATK 3 DEF 0\n* Drifting through the wind.\n* Wants to start again.",
		"acts": [
			{"name": "Recycle", "mercy": 60, "lines": ["* {actor} folds it up for recycling.\n* It feels like it has a purpose again."]},
			{"name": "Let It Fly", "mercy": 40, "lines": ["* {actor} lets it ride the wind.\n* It does a little loop. Happy."]},
		],
		"taunts": ["*rustle*", "(floats)", "*crinkle*"],
		"flavor": ["* The Plastic Bag rustles.", "* The wind picks up."],
		"backdrop": Color(0.75, 0.8, 0.85), "style": "static", "exp": 4, "money": 1,
	},
}

## Who lives where (scene path -> creature ids).
const ZONES := {
	"res://scenes/mt_carmel.tscn": ["squirrel", "seagull", "bag"],
	"res://scenes/pq_mall.tscn": ["cart", "receipt", "balloon", "seagull"],
	"res://scenes/westview.tscn": ["bag", "squirrel", "seagull"],
	"res://scenes/hilltop.tscn": ["goose", "sprinkler", "balloon"],
	"res://scenes/hop_house.tscn": ["gnome", "flamingo", "bag"],
	"res://scenes/mission_beach.tscn": ["sand_crab", "jellyfish", "beach_kite"],
	"res://scenes/balboa_park.tscn": ["peacock", "marble_bust", "tour_group"],
	"res://scenes/old_town.tscn": ["tumbleweed", "pinata", "wax_ghost"],
	"res://scenes/downtown.tscn": ["pigeon_gang", "parking_meter", "neon_sign"],
	"res://scenes/harbor.tscn": ["gull_captain", "lobster_trap", "rust_bot"],
	"res://scenes/torrey_pines.tscn": ["rattlesnake", "fog_wisp", "lost_kite"],
	"res://scenes/burned_hills.tscn": ["cinder", "smoke_wraith", "charred_stump"],
	"res://scenes/junkyard.tscn": ["junk_rat", "magnet", "hubcap"],
}


## The battle names for an area's wild creatures (empty if none live there).
static func encounters_for(scene_path: String) -> Array:
	var ids: Array = []
	for id in ZONES.get(scene_path, []):
		ids.append("wild_" + id)
	return ids


static func create(id: String) -> BattleData:
	var c: Dictionary = CREATURES[id]
	var data := BattleData.new()
	data.id = "wild_" + id
	data.backdrop = c["backdrop"]
	data.backdrop_style = c["style"]
	data.intro = [c["intro"]]
	var e := Enemy.new()
	e.name = c["name"]
	e.max_hp = c["hp"]
	e.hp = c["hp"]
	e.attack = c["atk"]
	e.defense = c["def"]
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/%s.png" % c["sprite"])
	e.check_text = c["check"]
	e.acts.assign(c["acts"])
	e.patterns.assign(c["patterns"])
	e.taunts.assign(c["taunts"])
	e.flavor_lines.assign(c["flavor"])
	e.bullet_speed = 90.0
	e.exp_reward = c["exp"]
	e.bond_reward = 6
	e.money_reward = c["money"]
	data.enemies.append(e)
	return data
