class_name Townsfolk
extends RefCounted
## People around town who aren't in the REVOLUTION Corps. Not all of them are
## human. Talking to any of them: they say something, and Elric picks one of two
## answers (they react), or CHALLENGES them to a fight. (Nobody in the Corps can be
## challenged... yet.)
##
## Fight them and win by FIGHTing, and they're gone for good (it counts toward
## dread, like any other kill). SPARE them, and they remember it.
##
## Each person: name, sprite (art/sprites, with expressions in art/portraits), a
## conversation ("talk", plus "talk_later" / "talk_night" for other times: lines,
## two options, and an answer to each), how they react to being challenged, what
## they say after being spared, and their fight: HP, ATK, DEF, attacks (patterns
## from attacks.gd), CHECK text, ACTs, taunts, flavor lines, backdrop, rewards.
## Every line is [mood, text] (mood: "", happy, angry, sad, shocked, smug).
## The Westview students (westview.gd) all fight with the "student" profile.
## In areas, they're placed with Area.add_person(); battles are "person_<id>".

const PEOPLE := {
	# --- Mt. Carmel High ---
	"coach": {
		"name": "Coach Ramirez", "sprite": "coach",
		"talk": {
			"lines": [["angry", "You kids seen my keys? I put them somewhere safe.\nI just don't remember where safe IS."]],
			"options": ["Check a tree?", "Want help looking?"],
			"answers": [["shocked", "A TREE? Why would they be in a-\n...They're in a tree, aren't they."], ["happy", "Now THAT'S hustle!\nYou've got the spirit, kid."]],
		},
		"talk_later": {
			"lines": [["shocked", "Hey! Those are my keys!\n...You got them out of the tree, didn't you."], ["happy", "Keep 'em. I've got eleven spare sets.\nThe tree's got the other ten."], ["smug", "Just don't lose them.\n...I'm aware of how that sounds."]],
			"options": ["Are you sure?", "Thanks, Coach."],
			"answers": [["happy", "Kid, I lose a set a week.\nConsider it a scholarship."], ["happy", "Don't thank me. Thank the tree.\n...Actually, don't. It doesn't deserve it."]],
		},
		"challenged": ["smug", "You want to go a round with ME? Ha!\nAlright, kid. Warm-up's over."],
		"spared": ["happy", "...Good hustle. Real good hustle.\nNow hit the showers. ...Wait, you don't go here."],
		"hp": 55, "atk": 4, "def": 1, "patterns": ["coach_keys", "coach_laps"],
		"check": "* COACH RAMIREZ - ATK 4 DEF 1\n* A rhino. Thirty years of P.E. Loses his keys daily.",
		"acts": [
			{"name": "Find Keys", "mercy": 60, "lines": ["* {actor} points at the tree.\n* Coach Ramirez sighs. \"...Again?\""]},
			{"name": "Push-ups", "mercy": 40, "lines": ["* {actor} drops and does ten push-ups.\n* Coach nods. \"Form's bad. Heart's good.\""]},
		],
		"taunts": ["HUSTLE!", "Laps! LAPS!", "Is that all you got?"],
		"flavor": ["* Coach Ramirez blows his whistle at nothing.", "* He's checking his pockets for his keys."],
		"backdrop": Color(0.9, 0.35, 0.3), "style": "stripes", "exp": 12, "money": 12,
	},
	"janitor": {
		"name": "Janitor", "sprite": "janitor",
		"talk": {
			"lines": [["", "Don't walk on the wet part. ...It's all the wet part.\nI mopped the whole campus."], ["smug", "Raccoon. Janitor. Yes, I know.\nI've heard every joke. I clean up trash. Ha ha."]],
			"options": ["Thanks for cleaning.", "Any good trash?"],
			"answers": [["shocked", "...Nobody's ever said that to me.\nHuh. You're welcome, I guess."], ["smug", "Found half a sandwich in the bleachers yesterday.\nNot telling you which half."]],
		},
		"challenged": ["shocked", "You want to fight the guy with the mop?\nBold. Very bold."],
		"spared": ["happy", "Huh. You let me be.\nThat's more than most people do for the janitor."],
		"hp": 45, "atk": 3, "def": 2, "patterns": ["wet_floor", "trash_toss"],
		"check": "* JANITOR - ATK 3 DEF 2\n* A raccoon. Mops the whole school. Nobody says thanks.",
		"acts": [
			{"name": "Thank", "mercy": 60, "lines": ["* {actor} thanks the janitor for keeping things clean.\n* He stops. Nobody's ever said that before."]},
			{"name": "Pick Up Trash", "mercy": 40, "lines": ["* {actor} picks up a wrapper.\n* The janitor nods, approvingly."]},
		],
		"taunts": ["Watch your step.", "I just mopped that!", "..."],
		"flavor": ["* The janitor leans on his mop.", "* It smells like lemon floor cleaner."],
		"backdrop": Color(0.35, 0.7, 0.45), "style": "bubbles", "exp": 10, "money": 8,
	},
	"skater": {
		"name": "Skater", "sprite": "skater",
		"talk": {
			"lines": [["happy", "Dude. DUDE. I almost landed a kickflip.\nAlmost. Like, spiritually."]],
			"options": ["Show me!", "Frogs can skate?"],
			"answers": [["sad", "...I would, but I'm out of spiritual energy.\nTomorrow. Definitely tomorrow."], ["smug", "Frogs can JUMP, dude.\nSkating's just jumping with extra steps."]],
		},
		"challenged": ["happy", "A fight? Sick. Okay. Okay okay okay.\nHold my board. ...Actually, I'll keep it."],
		"spared": ["happy", "Respect, dude. Total respect.\nYou wanna see the kickflip? ...Some other time."],
		"hp": 35, "atk": 4, "def": 0, "patterns": ["kickflip", "grind_rail"],
		"check": "* SKATER - ATK 4 DEF 0\n* A frog. Has almost landed a kickflip 400 times.",
		"acts": [
			{"name": "Cheer", "mercy": 50, "lines": ["* {actor} cheers for the kickflip.\n* The skater beams. \"You SAW that?\""]},
			{"name": "Ask for Tips", "mercy": 50, "lines": ["* {actor} asks how to skate.\n* The skater talks for a very long time."]},
		],
		"taunts": ["Gnarly!", "Watch this!", "Ribbit, bro."],
		"flavor": ["* The skater rolls back and forth.", "* There's a scrape on both of his elbows."],
		"backdrop": Color(0.3, 0.75, 0.75), "style": "skyline", "exp": 9, "money": 6,
	},
	"waiting": {
		"name": "Waiting Ghost", "sprite": "waiting",
		"talk": {
			"lines": [["sad", "My mom said she'd pick me up at 3.\nIt's 4:30. She's \"five minutes away.\""], ["", "...I've been a ghost for a while now.\nShe's still five minutes away."]],
			"options": ["I'll wait with you.", "Want a ride?"],
			"answers": [["happy", "...Really? Okay.\nIt's less boring with two."], ["shocked", "From a stranger?? My mom would KILL me.\n...Again."]],
		},
		"challenged": ["angry", "...Seriously? I've been waiting for an HOUR\nand THIS is what happens?"],
		"spared": ["happy", "...Thanks. My mom just texted.\nShe's five minutes away. Again."],
		"hp": 30, "atk": 3, "def": 0, "patterns": ["five_minutes", "headlights"],
		"check": "* WAITING GHOST - ATK 3 DEF 0\n* Their ride is \"five minutes away.\" It always will be.",
		"acts": [
			{"name": "Wait With", "mercy": 60, "lines": ["* {actor} sits down and waits with them.\n* It's less boring with two."]},
			{"name": "Joke", "mercy": 40, "lines": ["* {actor} tells a joke.\n* The ghost snorts. \"...That was bad.\""]},
		],
		"taunts": ["Ugh.", "Leave me alone.", "Where IS she?"],
		"flavor": ["* The ghost checks their phone. Again.", "* Their phone is at 3%. It's been at 3% for years."],
		"backdrop": Color(0.65, 0.5, 0.9), "style": "skyline", "exp": 8, "money": 5,
	},

	# --- PQ Mall ---
	"mallcop": {
		"name": "Mall Cop", "sprite": "mallcop",
		"talk": {
			"lines": [["angry", "Move along. Nothing to see here.\n...Unless you saw who stuck gum on my Segway."]],
			"options": ["I'll keep an eye out.", "Nice mustache."],
			"answers": [["happy", "Good. A mall is only as safe as\nthe eyes watching it. And my eyes are TIRED."], ["smug", "Thank you. Thirty years in the making.\nThe tusks came with it."]],
		},
		"talk_night": {
			"lines": [["sad", "Mall's closed, kid. Well. The parking lot isn't.\nThe parking lot never closes. I'm here all night."]],
			"options": ["Want company?", "Seen anything weird?"],
			"answers": [["happy", "...You know, nobody's ever asked.\nMaybe for a minute."], ["shocked", "Lights at Westview, after midnight.\nNot my jurisdiction. Not going over there."]],
		},
		"challenged": ["shocked", "Are you... resisting? Is this resisting?\nI'll have to call this in. To myself."],
		"spared": ["smug", "...I'll let it slide. This time.\nThat's what a hero does. A mall hero."],
		"hp": 60, "atk": 4, "def": 2, "patterns": ["gum_stick", "segway"],
		"check": "* MALL COP - ATK 4 DEF 2\n* A walrus. Protects the PQ Mall. Mostly from gum.",
		"acts": [
			{"name": "Salute", "mercy": 50, "lines": ["* {actor} salutes.\n* The Mall Cop stands up straighter. He salutes back."]},
			{"name": "Report Gum", "mercy": 50, "lines": ["* {actor} reports some gum by Vons.\n* \"Thank you for your service, citizen.\""]},
		],
		"taunts": ["Halt!", "Freeze!", "That's a violation!"],
		"flavor": ["* The Mall Cop polishes his badge.", "* He's guarding the parking lot. From you."],
		"backdrop": Color(0.3, 0.4, 0.8), "style": "skyline", "exp": 14, "money": 15,
	},
	"mom": {
		"name": "Busy Mom", "sprite": "mom",
		"talk": {
			"lines": [["", "Six bags, two kids, one car somewhere in this lot.\nIf you see a minivan, it's probably mine."]],
			"options": ["Need a hand?", "Where are the kids?"],
			"answers": [["happy", "Oh, aren't YOU sweet. I'm fine, sweetie.\nI've got a pouch. It holds everything."], ["shocked", "...In the pouch. Hold on.\n...Okay. One kid. ONE kid in the pouch."]],
		},
		"challenged": ["angry", "Honey. I have been up since five.\nYou do NOT want to do this."],
		"spared": ["happy", "...Thank you, sweetie. That was nice of you.\nNow, have you seen a minivan?"],
		"hp": 50, "atk": 4, "def": 1, "patterns": ["coupons", "grocery_hop"],
		"check": "* BUSY MOM - ATK 4 DEF 1\n* A kangaroo. Has a coupon for everything. Even this.",
		"acts": [
			{"name": "Carry Bags", "mercy": 60, "lines": ["* {actor} offers to carry a bag.\n* \"Oh! Aren't YOU sweet.\""]},
			{"name": "Find Car", "mercy": 40, "lines": ["* {actor} points at a minivan.\n* \"...That's not mine. But thank you.\""]},
		],
		"taunts": ["Don't make me count to three.", "One...", "Two..."],
		"flavor": ["* The Busy Mom juggles six bags at once.", "* A coupon falls out of her pouch."],
		"backdrop": Color(0.95, 0.55, 0.7), "style": "skyline", "exp": 12, "money": 14,
	},
	"pigeons": {
		"name": "Pigeon Man", "sprite": "pigeons",
		"talk": {
			"lines": [["happy", "The pigeons know me. That one's Gerald.\nThat one's also Gerald. They're all Gerald."]],
			"options": ["Hi, Gerald.", "Why all Gerald?"],
			"answers": [["happy", "Gerald says hello back.\n...All of them do. Coo."], ["sad", "My wife's name was Geraldine.\nShe liked pigeons. So now I do too."]],
		},
		"challenged": ["angry", "Gerald. Geralds. Assemble."],
		"spared": ["happy", "You've got a kind face, wanderer.\nThe Geralds approve."],
		"hp": 40, "atk": 3, "def": 1, "patterns": ["pigeon_flock", "breadcrumbs"],
		"check": "* PIGEON MAN - ATK 3 DEF 1\n* Feeds the pigeons every day. Every pigeon is Gerald.",
		"acts": [
			{"name": "Feed Gerald", "mercy": 60, "lines": ["* {actor} tosses a crumb.\n* A Gerald coos. The old man smiles."]},
			{"name": "Listen", "mercy": 40, "lines": ["* {actor} listens to a story about Gerald.\n* It's mostly about Gerald."]},
		],
		"taunts": ["Coo.", "The Geralds are watching.", "Back in my day..."],
		"flavor": ["* A Gerald lands on the old man's head.", "* It smells like breadcrumbs."],
		"backdrop": Color(0.7, 0.7, 0.72), "style": "leaves", "exp": 10, "money": 9,
	},
	"teen": {
		"name": "Teen on Phone", "sprite": "teen",
		"talk": {
			"lines": [["", "Hold on, I'm texting."], ["", "..."], ["shocked", "...Okay, what. Oh. Hi."]],
			"options": ["Who're you texting?", "Can I see?"],
			"answers": [["smug", "Myself. From my other phone.\nIt's called networking."], ["angry", "Absolutely not. You'd need to be\nmy friend for at least four years."]],
		},
		"challenged": ["happy", "Wait wait wait. Let me get my phone out.\nThis is going on my story."],
		"spared": ["happy", "That was actually kind of nice of you.\nNot posting that. Too wholesome."],
		"hp": 30, "atk": 3, "def": 0, "patterns": ["notifications", "doomscroll"],
		"check": "* TEEN ON PHONE - ATK 3 DEF 0\n* A jelly. Hasn't looked up since 2019.",
		"acts": [
			{"name": "Selfie", "mercy": 60, "lines": ["* {actor} poses for a selfie.\n* The teen actually looks up. \"Okay, that's cute.\""]},
			{"name": "Ignore", "mercy": 30, "lines": ["* {actor} ignores them back.\n* The teen respects that."]},
		],
		"taunts": ["lol", "brb", "k."],
		"flavor": ["* The teen types with three tentacles at once.", "* Their phone buzzes. And buzzes."],
		"backdrop": Color(0.75, 0.5, 0.95), "style": "skyline", "exp": 8, "money": 6,
	},
	"jogger": {
		"name": "Jogger", "sprite": "jogger",
		"talk": {
			"lines": [["angry", "Can't stop. Personal best. Lap 9.\n...Okay, I stopped. Ruined. Thanks."]],
			"options": ["Sorry!", "Can ostriches fly?"],
			"answers": [["happy", "Eh, it's fine. Lap 1! Again!\nBest part of running is starting over."], ["sad", "No. That's why I run.\n...Don't make it weird."]],
		},
		"challenged": ["smug", "You want to go? Let's GO.\nI've got cardio for DAYS."],
		"spared": ["happy", "Good sportsmanship. I like that.\nAlright. Lap 10. Try to keep up next time."],
		"hp": 45, "atk": 4, "def": 0, "patterns": ["laps", "sweat_spray"],
		"check": "* JOGGER - ATK 4 DEF 0\n* An ostrich. Running laps around the parking lot. For fun.",
		"acts": [
			{"name": "Stretch", "mercy": 50, "lines": ["* {actor} stretches with the jogger.\n* \"Hamstrings! Love it!\""]},
			{"name": "Race", "mercy": 50, "lines": ["* {actor} races the jogger to the lamppost.\n* The jogger wins. They're thrilled."]},
		],
		"taunts": ["Keep up!", "Feel the burn!", "Hydrate!"],
		"flavor": ["* The jogger jogs in place.", "* They're wearing three fitness trackers. On one leg."],
		"backdrop": Color(0.35, 0.8, 0.95), "style": "skyline", "exp": 11, "money": 8,
	},

	# --- Westview High (at night) ---
	"nightjanitor": {
		"name": "Night Janitor", "sprite": "nightjanitor",
		"talk": {
			"lines": [["shocked", "...You shouldn't be here. Nobody should be here."], ["sad", "The bells ring by themselves after midnight.\nI just keep mopping. Keep my head down."]],
			"options": ["Why not leave?", "Isn't the light nice?"],
			"answers": [["sad", "Somebody has to clean up after\nwhatever's going on in there."], ["happy", "...The one in the hallway? Yeah.\nI stare at it on my breaks. Don't tell anyone."]],
		},
		"challenged": ["sad", "Please. I just clean the floors.\n...Fine. If you have to."],
		"spared": ["happy", "...Thank you. Get out of here, okay?\nThis school's not right at night."],
		"hp": 45, "atk": 4, "def": 2, "patterns": ["moths", "wing_dust"],
		"check": "* NIGHT JANITOR - ATK 4 DEF 2\n* A moth. Works the night shift. Hears the bells.",
		"acts": [
			{"name": "Reassure", "mercy": 60, "lines": ["* {actor} says it'll be okay.\n* The janitor almost believes it."]},
			{"name": "Help Mop", "mercy": 40, "lines": ["* {actor} grabs a mop and helps.\n* For a moment, it's just two people cleaning."]},
		],
		"taunts": ["Go home.", "...", "It's not safe."],
		"flavor": ["* The night janitor's antennae are shaking.", "* Somewhere, a bell rings."],
		"backdrop": Color(0.15, 0.6, 0.55), "style": "grid", "exp": 12, "money": 10,
	},
	"guard": {
		"name": "Security Guard", "sprite": "guard",
		"talk": {
			"lines": [["", "Zzz..."], ["shocked", "...Huh? Wha-- I'm awake! Totally awake."], ["smug", "Nothing's going on in there. Definitely nothing.\nI'm not going in to check, either."]],
			"options": ["Aren't owls nocturnal?", "Go back to sleep."],
			"answers": [["angry", "I'm a MORNING owl. It's a whole thing.\nThe night shift was a scheduling error."], ["happy", "...You're a good kid.\nZzz..."]],
		},
		"challenged": ["shocked", "Okay. Okay okay okay. This is the part where\nI'm supposed to be brave. Here goes."],
		"spared": ["happy", "...Phew. Thanks.\nI'm going back to sleep. You saw nothing."],
		"hp": 55, "atk": 4, "def": 2, "patterns": ["flashlight", "zzz"],
		"check": "* SECURITY GUARD - ATK 4 DEF 2\n* An owl. Guards Westview at night. Mostly sleeps.",
		"acts": [
			{"name": "Let Sleep", "mercy": 60, "lines": ["* {actor} tiptoes past.\n* The guard pretends he didn't notice."]},
			{"name": "Say Boo", "mercy": 40, "lines": ["* {actor} says \"boo.\"\n* The guard hoots. Then laughs. Then hoots."]},
		],
		"taunts": ["Halt! ...Please?", "I'm armed! With a flashlight.", "Hoo goes there?!"],
		"flavor": ["* The security guard yawns.", "* His flashlight flickers."],
		"backdrop": Color(0.25, 0.3, 0.6), "style": "stripes", "exp": 13, "money": 12,
	},

	# --- Westview Field ---
	"dogwalker": {
		"name": "Dog Walker", "sprite": "dogwalker",
		"talk": {
			"lines": [["", "Biscuit won't go near the middle of the field.\nNever has. Pulls the other way every time."], ["sad", "Dogs know things, I think."]],
			"options": ["Can I pet Biscuit?", "What's in the middle?"],
			"answers": [["happy", "Go for it. He loves everybody.\n...Except the middle of the field."], ["sad", "Nothing, now. There was a fire out here,\na few years back. Grass grew back. Mostly."]],
		},
		"talk_later": {
			"lines": [["sad", "Biscuit still won't go near the middle.\n...Especially not now."]],
			"options": ["Can I pet Biscuit?", "Smart dog."],
			"answers": [["happy", "Go for it. He's earned it."], ["", "Smarter than me.\nI walked straight past it for years."]],
		},
		"challenged": ["shocked", "Whoa, whoa! Biscuit, stay back.\n...Okay. I guess we're doing this."],
		"spared": ["happy", "Biscuit likes you.\nThat's rare. He doesn't like anybody."],
		"hp": 40, "atk": 3, "def": 1, "patterns": ["fetch", "zoomies"],
		"check": "* DOG WALKER - ATK 3 DEF 1\n* Walks Biscuit here every night. Biscuit avoids the middle.",
		"acts": [
			{"name": "Pet Biscuit", "mercy": 60, "lines": ["* {actor} pets Biscuit.\n* Biscuit's tail goes everywhere."]},
			{"name": "Throw Ball", "mercy": 40, "lines": ["* {actor} throws a tennis ball.\n* Biscuit brings it back. Covered in spit."]},
		],
		"taunts": ["Biscuit, no!", "Good boy!", "Sit! ...Not you."],
		"flavor": ["* Biscuit is wagging.", "* Biscuit is looking at the middle of the field. Then away."],
		"backdrop": Color(0.4, 0.75, 0.35), "style": "leaves", "exp": 10, "money": 8,
	},

	# --- Westview's students (by day; see westview.gd) ---
	"student": {
		"name": "Student",
		"challenged": ["shocked", "Wait, what? Like, FIGHT fight?\nI have a quiz third period!"],
		"spared": ["happy", "...You let me go? Okay. Cool. Cool cool cool.\nI'm going to class now. Bye."],
		"hp": 30, "atk": 3, "def": 0, "patterns": ["paper_planes", "backpack"],
		"check": "* STUDENT - ATK 3 DEF 0\n* Just trying to get to class.",
		"acts": [
			{"name": "Help Study", "mercy": 60, "lines": ["* {actor} quizzes them on their notes.\n* They're actually getting it!"]},
			{"name": "Compliment", "mercy": 40, "lines": ["* {actor} says they look cool.\n* \"...Really?\" They stand a little taller."]},
		],
		"taunts": ["Leave me alone!", "I'm gonna be late!", "Not cool!"],
		"flavor": ["* The student clutches their backpack.", "* A bell rings somewhere. They flinch."],
		"backdrop": Color(0.35, 0.6, 0.95), "style": "grid", "exp": 8, "money": 5,
	},
}


## The profile for a person id. Students are "student-<look>-<n>" (their sprite is
## student<look>), and share one profile.
static func profile(id: String) -> Dictionary:
	if id.begins_with("student-"):
		var person: Dictionary = PEOPLE["student"].duplicate()
		person["sprite"] = "student" + id.get_slice("-", 1)
		return person
	return PEOPLE.get(id, PEOPLE["student"])


## A line as dialogue from this person: [mood, text] -> {"who", "tag", "text", "mood"}.
static func line(person: Dictionary, said: Array) -> Dictionary:
	return {"who": person["sprite"], "tag": person["name"], "text": said[1], "mood": said[0]}


## Gone for good (they were defeated, not spared).
static func is_gone(id: String) -> bool:
	return Game.flags.get("killed_person_" + id, false)


static func was_spared(id: String) -> bool:
	return Game.flags.get("spared_person_" + id, false)


## The fight with someone: battle id "person_<id>".
static func create_battle(id: String) -> BattleData:
	var person := profile(id)
	var data := BattleData.new()
	data.id = "person_" + id
	data.backdrop = person["backdrop"]
	data.backdrop_style = person["style"]
	data.intro = ["* You challenged %s!" % _the(person["name"])]
	var e := Enemy.new()
	e.name = person["name"]
	e.max_hp = person["hp"]
	e.hp = person["hp"]
	e.attack = person["atk"]
	e.defense = person["def"]
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/%s.png" % person["sprite"])
	e.check_text = person["check"]
	e.acts.assign(person["acts"])
	e.patterns.assign(person["patterns"])
	e.taunts.assign(person["taunts"])
	e.spare_taunts.assign(["...Okay. Okay."])
	e.flavor_lines.assign(person["flavor"])
	e.bullet_speed = 90.0
	e.exp_reward = person["exp"]
	e.bond_reward = 10
	e.money_reward = person["money"]
	data.enemies.append(e)
	return data


## "the Mall Cop", but just "Coach Ramirez" for a name.
static func _the(person_name: String) -> String:
	if person_name in ["Coach Ramirez"]:
		return person_name
	return "the " + person_name
