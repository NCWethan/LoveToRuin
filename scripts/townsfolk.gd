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
	# --- The junkyard ---
	"junkdealer": {
		"name": "Junk Dealer", "sprite": "junkdealer",
		"talk": {
			"lines": [["smug", "Welcome to Junk Town. Population: me.\nEverything's for sale. Everything's junk."], ["", "A kid in a fedora fought me for a taco once.\nHe won. Fair and square. I respect that kid."]],
			"options": ["The kid in the fedora?", "What's for sale?"],
			"answers": [["happy", "Scrappy little guy. Had a friend with a backpack\nthat clinked. I sold 'em a bottle cap. Good customers."], ["smug", "This hubcap. That hubcap. A tire.\nA different tire. Feelings, if you ask nice."]],
		},
		"challenged": ["angry", "A FIGHT? In MY yard?\nI've been waiting for this since the taco."],
		"spared": ["happy", "Respect. Here, a bottle cap.\nOn the house. It's the shiniest one."],
		"hp": 70, "atk": 5, "def": 2, "patterns": ["shiny_things", "dumpster_dive"],
		"check": "* JUNK DEALER - ATK 5 DEF 2\n* A raccoon in overalls. Runs the junkyard.\n* Lost a taco fight once. Still thinks about it.",
		"acts": [
			{"name": "Haggle", "mercy": 50, "lines": ["* {actor} haggles over a hubcap.\n* The Junk Dealer's eyes light up. A WORTHY opponent."]},
			{"name": "Mention Tacos", "mercy": 50, "lines": ["* {actor} mentions tacos.\n* The Junk Dealer goes very quiet. Then smiles."]},
		],
		"taunts": ["Mine!", "Shiny!", "No refunds!", "That's MY junk!"],
		"flavor": ["* The Junk Dealer counts bottle caps.", "* The freeway roars overhead."],
		"backdrop": Color(0.5, 0.45, 0.4), "style": "grid", "exp": 14, "money": 22,
	},
	# --- The burned hills ---
	"firefighter": {
		"name": "Firefighter", "sprite": "firefighter",
		"talk": {
			"lines": [["", "Careful up there. Ground's still warm in places.\nFive years, and it's still warm."], ["sad", "I was on the line that night. We lost the hill.\nI come back every weekend and plant something."]],
			"options": ["What are you planting?", "What happened that night?"],
			"answers": [["happy", "Pines, mostly. Some sage. I name every one.\nThat one's Lucky. That one's Also Lucky."], ["sad", "It started on the field. A tent, they said.\nIt moved faster than any fire I ever saw. Like it wanted to."]],
		},
		"challenged": ["angry", "Kid. I've stared down a wildfire.\nYou're not even warm."],
		"spared": ["happy", "Good. That's good. Help me plant one\nsometime. It helps. Trust me."],
		"hp": 80, "atk": 5, "def": 3, "patterns": ["hose_spray", "axe_chop"],
		"check": "* FIREFIGHTER - ATK 5 DEF 3\n* A dalmatian. Was there the night of the fire.\n* Plants a tree for every one that burned.",
		"acts": [
			{"name": "Plant a Tree", "mercy": 50, "lines": ["* {actor} helps plant a sapling.\n* The Firefighter ties a tag to it. It says FRIEND."]},
			{"name": "Thank Them", "mercy": 50, "lines": ["* {actor} thanks the Firefighter.\n* \"...Nobody ever says that. Not for that night.\""]},
		],
		"taunts": ["Stand back!", "Hose!", "Stay low!", "I've seen worse."],
		"flavor": ["* The Firefighter's helmet has a dent in it.\n* Five years old.", "* Ash drifts across the hill."],
		"backdrop": Color(0.75, 0.3, 0.2), "style": "shards", "exp": 14, "money": 12,
	},
	# --- Torrey Pines ---
	"ranger": {
		"name": "Park Ranger", "sprite": "ranger",
		"talk": {
			"lines": [["", "Welcome to Torrey Pines. Stay on the trail.\nDon't feed the gulls. Don't touch the pines."], ["smug", "There are only a few thousand of these trees left\nin the world. I know every one. By name."]],
			"options": ["What's that one called?", "What about the glider?"],
			"answers": [["happy", "That's Doris. She's four hundred years old.\nShe's my best friend. Don't tell the others."], ["sad", "Five years it's been up there. Nobody in it.\nI write it a ticket every week. It never pays."]],
		},
		"challenged": ["angry", "Off. The. Trail.\nThat's a CITATION, buddy."],
		"spared": ["happy", "Respectful. Quiet. Stayed on the trail.\nYou'd make a fine ranger. In about fifty years."],
		"hp": 75, "atk": 4, "def": 4, "patterns": ["rule_signs", "slow_and_steady"],
		"check": "* PARK RANGER - ATK 4 DEF 4\n* A tortoise. Has worked here for ninety years.\n* Is in no hurry. About anything.",
		"acts": [
			{"name": "Stay on Trail", "mercy": 50, "lines": ["* {actor} stays exactly on the trail.\n* The Ranger nods. Very, very slowly."]},
			{"name": "Ask About Trees", "mercy": 50, "lines": ["* {actor} asks about the trees.\n* Forty minutes later, he's still going. He's happy."]},
		],
		"taunts": ["Stay on the trail.", "Citation.", "Slowly, now.", "Doris is watching."],
		"flavor": ["* The Park Ranger writes you a ticket. Slowly.", "* The wind smells like pine."],
		"backdrop": Color(0.35, 0.55, 0.35), "style": "cliffs", "exp": 14, "money": 15,
	},
	"hiker": {
		"name": "Hiker", "sprite": "hiker",
		"talk": {
			"lines": [["happy", "Morning! Third time up the trail today!\nGoats don't get tired. That's a myth. We LOVE hills."], ["", "Want some trail mix? It's the good kind.\nThe raisins are optional. I took them out."]],
			"options": ["Sure, I'll take some.", "Third time?"],
			"answers": [["happy", "Here! A whole bag. Keep it.\nYou look like you've been walking a long way."], ["smug", "Up, down, up, down, up.\nIt's called CARDIO. Look into it."]],
		},
		"challenged": ["happy", "A challenge! On a CLIFF! This is the best\nday of my life! Again!"],
		"spared": ["happy", "GOOD hike. Good hike.\nSee you at the top. And the bottom. And the top."],
		"hp": 60, "atk": 5, "def": 2, "patterns": ["rockslide", "trail_mix_toss"],
		"check": "* HIKER - ATK 5 DEF 2\n* A mountain goat with a very good backpack.\n* Has never once been out of breath.",
		"acts": [
			{"name": "Share Snacks", "mercy": 50, "lines": ["* {actor} offers some snacks.\n* The Hiker offers MORE snacks back. A snack-off."]},
			{"name": "Stretch", "mercy": 50, "lines": ["* {actor} stretches like a real hiker.\n* \"YES. Good form! GOOD FORM!\""]},
		],
		"taunts": ["Uphill!", "Feel the burn!", "Trail mix!", "Goats are great!"],
		"flavor": ["* The Hiker is doing lunges.", "* A pebble tumbles down the cliff."],
		"backdrop": Color(0.75, 0.6, 0.4), "style": "cliffs", "exp": 12, "money": 10,
	},
	"birder": {
		"name": "Birdwatcher", "sprite": "birder",
		"talk": {
			"lines": [["", "Shh. SHH. There's a peregrine falcon nesting\non the cliff. Six years I've been waiting."], ["shocked", "...Oh. It's the glider again. Every time.\nEvery single time, it's the glider."]],
			"options": ["Seen anything good?", "Isn't an owl a bird?"],
			"answers": [["happy", "A brown pelican! A whimbrel! A guy in\na hat who said he was a rooster!"], ["smug", "I'm not WATCHING myself. That'd be weird.\nI have a mirror for that."]],
		},
		"challenged": ["angry", "You scared off the falcon.\nSIX. YEARS."],
		"spared": ["happy", "You're on my list now.\nThe GOOD list. Rare sighting. Very rare."],
		"hp": 55, "atk": 4, "def": 1, "patterns": ["binocular_scan", "field_guide"],
		"check": "* BIRDWATCHER - ATK 4 DEF 1\n* An owl with enormous binoculars.\n* Up all night. Up all day. Waiting for a falcon.",
		"acts": [
			{"name": "Point at Bird", "mercy": 50, "lines": ["* {actor} points at a bird.\n* \"...Is that- that's a GULL. But thank you.\""]},
			{"name": "Whisper", "mercy": 50, "lines": ["* {actor} whispers, so the birds won't hear.\n* The Birdwatcher whispers back. Best friends."]},
		],
		"taunts": ["Shh!", "Look! ...No.", "Hoo.", "SIX YEARS."],
		"flavor": ["* The Birdwatcher's binoculars glint.", "* Somewhere, a falcon. Maybe."],
		"backdrop": Color(0.55, 0.45, 0.35), "style": "cliffs", "exp": 11, "money": 9,
	},
	# --- The Harbor ---
	"sailor": {
		"name": "Old Sailor", "sprite": "sailor",
		"talk": {
			"lines": [["", "Ahoy. Forty years on the water, and they\nput me on a museum. Like a fish in a frame."], ["smug", "I give the tours. I make up half of it.\nThe tourists like my half better."]],
			"options": ["Tell me a sea story.", "Ever see a ghost ship?"],
			"answers": [["happy", "Once I wrestled a squid for a sandwich.\nThe squid won. It was a good sandwich."], ["sad", "Saw one tonight. A jet on the deck,\nengines going, nobody in it. ...Don't go up there."]],
		},
		"challenged": ["angry", "HAR! You want to tangle with a walrus?\nI've got tusks, lad. TUSKS."],
		"spared": ["happy", "Ye've got sea legs.\nCome back and I'll tell ye the squid story again."],
		"hp": 70, "atk": 5, "def": 2, "patterns": ["anchor_drop", "rope_knots"],
		"check": "* OLD SAILOR - ATK 5 DEF 2\n* A walrus. Forty years at sea.\n* Twenty of those years are made up.",
		"acts": [
			{"name": "Salute", "mercy": 50, "lines": ["* {actor} salutes.\n* The Old Sailor salutes back, with a flipper. Crisply."]},
			{"name": "Hear the Story", "mercy": 50, "lines": ["* {actor} listens to the squid story.\n* It's different every time. It's great every time."]},
		],
		"taunts": ["HAR!", "Batten down!", "Ye scallywag!", "Forty years!"],
		"flavor": ["* The Old Sailor squints at the horizon.", "* Smells like the sea. And a little like fish."],
		"backdrop": Color(0.3, 0.45, 0.7), "style": "waves", "exp": 13, "money": 15,
	},
	"tourist": {
		"name": "Tourist", "sprite": "tourist",
		"talk": {
			"lines": [["happy", "Oh! Can you take our picture? It's just me.\nI'm the 'our.'"], ["", "I've seen the carrier, the seals, the other seals.\nNext: the seal-shaped rock."]],
			"options": ["(Take the picture.)", "Where are you from?"],
			"answers": [["happy", "PERFECT. You cut off my head.\nIt's art. I'm framing it."], ["smug", "Somewhere with no ocean! Look at it!\nThere's so MUCH of it!"]],
		},
		"challenged": ["shocked", "A local custom?! How AUTHENTIC.\nHold on, let me get the camera."],
		"spared": ["happy", "Best vacation EVER.\nFive stars. Would get challenged again."],
		"hp": 50, "atk": 3, "def": 1, "patterns": ["flash_photo", "souvenir_spoons"],
		"check": "* TOURIST - ATK 3 DEF 1\n* A capybara on vacation. Very sunburned.\n* Has 3,000 photos of the same seal.",
		"acts": [
			{"name": "Pose", "mercy": 50, "lines": ["* {actor} strikes a pose.\n* *CLICK* \"That's going on the fridge.\""]},
			{"name": "Recommend", "mercy": 50, "lines": ["* {actor} recommends the fish tacos.\n* The Tourist writes it down. Underlines it twice."]},
		],
		"taunts": ["Say cheese!", "Hold still!", "*click*", "Is that a SEAL?"],
		"flavor": ["* The Tourist checks the map. It's upside down.", "* The Tourist's sunburn has a sunburn."],
		"backdrop": Color(0.9, 0.55, 0.45), "style": "waves", "exp": 11, "money": 20,
	},
	"pelican": {
		"name": "Pelican", "sprite": "pelican",
		"talk": {
			"lines": [["smug", "Fish. Fresh fish. Caught 'em myself.\n...With my face. Don't ask."], ["", "Buy one, get one free. The free one\nis the one I already ate."]],
			"options": ["One fish, please.", "Why do you sell fish?"],
			"answers": [["happy", "Good choice. Excellent choice.\nThat one was almost in my mouth."], ["sad", "Gotta do something with the ones\nthat don't fit. Don't make it sad."]],
		},
		"challenged": ["angry", "You picked a fight with a PELICAN.\nOn a PIER. Bold."],
		"spared": ["happy", "Respect. Here, a fish.\nNo, the good one. Don't tell anyone."],
		"hp": 55, "atk": 4, "def": 1, "patterns": ["fish_toss", "beak_scoop"],
		"check": "* PELICAN - ATK 4 DEF 1\n* Sells fish off the pier. Eats most of the stock.\n* Business is bad. Lunch is great.",
		"acts": [
			{"name": "Buy a Fish", "mercy": 50, "lines": ["* {actor} buys a fish.\n* The Pelican looks at it longingly. Hands it over anyway."]},
			{"name": "Compliment Beak", "mercy": 50, "lines": ["* {actor} compliments the beak.\n* The Pelican fluffs up to twice his size."]},
		],
		"taunts": ["SQUAWK.", "Fresh fish!", "Mine.", "It fits. It all fits."],
		"flavor": ["* The Pelican swallows something whole.", "* The pier creaks."],
		"backdrop": Color(0.35, 0.6, 0.75), "style": "waves", "exp": 12, "money": 12,
	},
	# --- Downtown ---
	"hotdog": {
		"name": "Hot Dog Vendor", "sprite": "hotdog",
		"talk": {
			"lines": [["happy", "HOT DOGS! Get your HOT DOGS!\n...Yes, I'm a dachshund. No, it's not weird."], ["smug", "It's a little weird."]],
			"options": ["One hot dog, please.", "Isn't that... a conflict?"],
			"answers": [["happy", "Mustard? Relish? Existential dread?\nThe dread's free. Comes with every order."], ["sad", "Every day, kid. Every single day.\nBut the tips are good."]],
		},
		"challenged": ["angry", "You wanna go? I've got tongs,\nI've got mustard, and I've got NOTHING to lose."],
		"spared": ["happy", "Here. On the house.\nDon't tell my manager. I'm my manager."],
		"hp": 55, "atk": 4, "def": 1, "patterns": ["hot_dog_toss", "mustard_squirt"],
		"check": "* HOT DOG VENDOR - ATK 4 DEF 1\n* Has sold hot dogs outside the ballpark for 11 years.\n* Doesn't think about it. Tries not to.",
		"acts": [
			{"name": "Buy One", "mercy": 50, "lines": ["* {actor} buys a hot dog, extra mustard.\n* The vendor's tail wags. He can't help it."]},
			{"name": "Tip", "mercy": 50, "lines": ["* {actor} leaves a tip.\n* \"...A TIP? Nobody tips the hot dog guy.\""]},
		],
		"taunts": ["HOT DOGS!", "Mustard's on me!", "Extra relish!", "Don't make it weird."],
		"flavor": ["* The Hot Dog Vendor waves his tongs.", "* Smells like ballpark."],
		"backdrop": Color(0.85, 0.35, 0.25), "style": "skyline", "exp": 12, "money": 14,
	},
	"statue": {
		"name": "Living Statue", "sprite": "statue",
		"talk": {
			"lines": [["", "..."], ["", "......"], ["", "(He doesn't move. Not even his eyes.)"]],
			"options": ["(Put a coin in the jar.)", "(Make a face at him.)"],
			"answers": [["happy", "(He winks. Just once. Then he's stone again.)"], ["", "(Nothing. Not even a twitch.\n His eyebrow, maybe. Maybe not.)"]],
		},
		"challenged": ["", "(For the first time in three hours,\n the Living Statue moves.)"],
		"spared": ["happy", "(He bows. Then freezes, mid-bow,\n for the rest of the afternoon.)"],
		"hp": 60, "atk": 4, "def": 3, "patterns": ["frozen_pose", "tip_jar"],
		"check": "* LIVING STATUE - ATK 4 DEF 3\n* Painted silver, head to toe. Hasn't moved since noon.\n* His record is nine hours. He wants ten.",
		"acts": [
			{"name": "Tip", "mercy": 50, "lines": ["* {actor} drops a coin in the tip jar.\n* *clink* The statue changes pose. Very slowly."]},
			{"name": "Hold Still", "mercy": 50, "lines": ["* {actor} holds very, very still.\n* The statue respects it. Deeply."]},
		],
		"taunts": ["...", "......", "(...)", "(blink)"],
		"flavor": ["* The Living Statue is perfectly still.", "* A pigeon lands on the Living Statue's head.\n* He allows it."],
		"backdrop": Color(0.6, 0.62, 0.68), "style": "skyline", "exp": 12, "money": 16,
	},
	"superfan": {
		"name": "Superfan", "sprite": "superfan",
		"talk": {
			"lines": [["happy", "LET'S GO! LET'S GO! ...Oh, there's no game today?"], ["smug", "There's always a game. In your HEART."]],
			"options": ["Who's your team?", "Do they ever win?"],
			"answers": [["happy", "The home team! Whoever that is!\nI just like the yelling!"], ["sad", "...Not since I was an egg.\nBUT THIS IS THE YEAR."]],
		},
		"challenged": ["happy", "A RIVAL?! FINALLY!\nPLAY BALL!"],
		"spared": ["happy", "GOOD GAME! GOOD GAME!\n(He shakes your hand. With his whole wing.)"],
		"hp": 50, "atk": 3, "def": 1, "patterns": ["rally_towel", "peanut_shells"],
		"check": "* SUPERFAN - ATK 3 DEF 1\n* A parrot in a jersey. Has never missed a game.\n* The team has never won one he's seen.",
		"acts": [
			{"name": "Cheer", "mercy": 50, "lines": ["* {actor} cheers.\n* The Superfan cheers LOUDER. It's a competition now."]},
			{"name": "Do the Wave", "mercy": 50, "lines": ["* {actor} does the wave, alone.\n* The Superfan joins in. Two-person wave. Historic."]},
		],
		"taunts": ["LET'S GO!", "CHARGE!", "BOOOO! (affectionate)", "PLAY BALL!"],
		"flavor": ["* The Superfan swings his rally towel.", "* Peanut shells, everywhere."],
		"backdrop": Color(0.25, 0.45, 0.8), "style": "skyline", "exp": 10, "money": 9,
	},
	# --- Old Town ---
	"rosa": {
		"name": "Doña Rosa", "sprite": "rosa",
		"talk": {
			"lines": [["happy", "Tortillas! Fresh! Made by hand since before\nyou were born, mijo."], ["smug", "Don't touch the comal. It bites."]],
			"options": ["Can I have one?", "How long have you done this?"],
			"answers": [["happy", "Of course! Here. Careful, it's hot.\n...See? It bit you."], ["", "Fifty years. My hands could do it in my sleep.\nSome nights, they do."]],
		},
		"challenged": ["angry", "You want to fight an old woman with a hot\ncomal? ...Fine. Bring it, mijo."],
		"spared": ["happy", "Ha! You're a good kid.\nCome back hungry."],
		"hp": 50, "atk": 4, "def": 1, "patterns": ["tortilla_toss", "comal_heat"],
		"check": "* DOÑA ROSA - ATK 4 DEF 1\n* A hedgehog. Fifty years of tortillas.\n* The spines are for customers who don't say thank you.",
		"acts": [
			{"name": "Eat One", "mercy": 50, "lines": ["* {actor} eats a tortilla, still hot.\n* Doña Rosa watches, very pleased."]},
			{"name": "Say Thank You", "mercy": 50, "lines": ["* {actor} says thank you. Properly.\n* Her spines go flat. \"...Good manners.\""]},
		],
		"taunts": ["¡Ay!", "Too slow!", "Eat something!", "Look at you. So skinny."],
		"flavor": ["* Doña Rosa flips a tortilla without looking.", "* The comal hisses."],
		"backdrop": Color(0.9, 0.55, 0.3), "style": "plaza", "exp": 11, "money": 12,
	},
	"cactus": {
		"name": "Mariachi Cactus", "sprite": "cactus",
		"talk": {
			"lines": [["happy", "(singing) AAAY, AY, AY, AYYYY...\n...A request? I know four songs."], ["smug", "Three of them are this one."]],
			"options": ["Play something sad.", "Play something fast."],
			"answers": [["sad", "...This one is about a cactus who wanted\nto be hugged. It's autobiographical."], ["happy", "FAST? I only have one speed, amigo.\nFIESTA."]],
		},
		"challenged": ["smug", "A duel? With a mariachi?\nWe have a song for this exact situation."],
		"spared": ["happy", "You have the soul of a trumpet.\nI mean that as a compliment."],
		"hp": 55, "atk": 4, "def": 2, "patterns": ["needle_spray", "maraca_beat"],
		"check": "* MARIACHI CACTUS - ATK 4 DEF 2\n* Plays the plaza every night. Nobody can hug him.\n* He would like that, though.",
		"acts": [
			{"name": "Request", "mercy": 50, "lines": ["* {actor} requests his best song.\n* He plays the same one. It's still good."]},
			{"name": "Dance", "mercy": 50, "lines": ["* {actor} dances, badly.\n* \"¡OLÉ!\" He means it."]},
		],
		"taunts": ["¡OLÉ!", "One more time!", "Everybody clap!", "AY AY AY!"],
		"flavor": ["* The Mariachi Cactus strums a chord.", "* His sombrero has a hole for one of his arms."],
		"backdrop": Color(0.4, 0.75, 0.4), "style": "plaza", "exp": 12, "money": 10,
	},
	"guide": {
		"name": "Tour Guide", "sprite": "guide",
		"talk": {
			"lines": [["smug", "Welcome to the Old Town Ghost Tour!\nFirst stop: that house. Do NOT go in."], ["shocked", "...Nobody goes in. The table's still set.\nIt has been for a hundred and fifty years."]],
			"options": ["Who set it?", "I'm going in."],
			"answers": [["sad", "Isabel. The hostess. Her guests never came.\nShe never stopped waiting for them."], ["shocked", "...Can I put that on the tour?\nIf you come out?"]],
		},
		"challenged": ["shocked", "FIGHT me? I'm a TOUR GUIDE.\n...Fine. This is part of the tour now."],
		"spared": ["happy", "Best tour I've ever given.\nFive stars. I'm reviewing myself."],
		"hp": 45, "atk": 3, "def": 1, "patterns": ["lantern_sweep", "ghost_story"],
		"check": "* TOUR GUIDE - ATK 3 DEF 1\n* A heron with a lantern. Has never seen a ghost.\n* Would very much like to keep it that way.",
		"acts": [
			{"name": "Take the Tour", "mercy": 50, "lines": ["* {actor} takes the tour.\n* It's actually really interesting."]},
			{"name": "Act Spooked", "mercy": 50, "lines": ["* {actor} gasps at the spooky part.\n* The Tour Guide has never been happier."]},
		],
		"taunts": ["BOO! ...Did that work?", "And to your left: danger.", "Stay with the group!"],
		"flavor": ["* The Tour Guide's lantern swings.", "* He keeps glancing at the old house."],
		"backdrop": Color(0.45, 0.4, 0.7), "style": "plaza", "exp": 10, "money": 8,
	},
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
	if person_name in ["Coach Ramirez", "Doña Rosa"]:
		return person_name
	return "the " + person_name
