# LOVE TO RUIN — Design Document

*LOVE TO RUIN* is an anagram of *REVOLUTION*.

A Deltarune/Undertale-style RPG set in San Diego, California, starring a cast based on the Revolution friend group.

---

## 1. The big idea

**Revolution** is the team that **Eggo** and **Big Joe** started in an attempt to beat **Hopkuna**.

The player, **Elric**, gets pulled into this conflict and decides, through how they play, whether to stand with Revolution, ignore the fight, or join Hopkuna.

## 2. The world

- **Setting:** Earth — San Diego, California.
- **Chapter 1 area:** the area around Westview High School and Mt. Carmel High School, and everything in between.

### Chapter 1 locations

| Location | Role | Notes |
|---|---|---|
| **Mt. Carmel High School** | **Starting area** · **Fragment 1** | Where Elric's journey begins and where Elric first meets Hop. Elric finds the **1st fragment** here — and picking it up is exactly what gets Eggo and Big Joe's attention. The **tutorial fight** happens just **outside the school**. |
| **The PQ Mall** | **Main city / hub** | Where the Vons is, near the Jack in the Box and Knotty Barrel. Shops for healing items, NPCs, and cast members hanging out between adventures. A safe place — **no fragment here**. |
| **Westview High School** | **The "dungeon"** · **Fragment 2** | Chapter 1's big exploration area — the school after hours, twisted by the fragment's power into a maze of puzzles, locked rooms and enemies (like Deltarune's Dark World). The **2nd fragment** is hidden deep inside. |
| **Westview Field** | **REVOLUTION Corps base** · **Fragment 3** · **Chapter 1's final battle** | The Corps' base. The **3rd fragment** is buried under the **big field**. When it erupts, Hop takes the hit, Hopkuna comes out, and Chapter 1's final battle — **against Hopkuna himself** — happens on the field. The Corps returns, and the **route choice** happens. |

**Chapter 1 path:** Mt. Carmel HS → PQ Mall → Westview HS → Westview Field

**SAVE points** can appear anywhere as the player progresses.

### The PQ Mall (as built)

**Stores:** Vons (groceries), Games & Cards ("BACK IN 5 MINUTES" for years, until the afternoon), Knotty Barrel (patio + salmon burgers), an empty store FOR LEASE (someone wrote "REVOLUTION HQ??" in the dust), and Jack in the Box. See **Shops** below.

### Shops

The door chimes as you go in and out. Going into a shop fades to a whole different screen, like Undertale: the shop itself at the top, with the shopkeeper big behind the counter and everything they sell drawn on the shelves, menu boards and display case behind them (pixel pictures in `scripts/ui/shop_art.gd`); what they say in the box at the bottom left (typed out in their voice, with their face changing); and **Buy / Sell / Talk / Exit** at the bottom right, with your money and how full your bag is. Browsing shows what each thing does in a little panel; buying asks first, and the shopkeeper reacts (some things get their own line). Each shop has its **own song**. Everything a shop sells and says is in `scripts/shops.gd`.

| Shop | Shopkeeper | Sells | Song |
|---|---|---|---|
| **Vons** | **Gloria**, the manager (22 years, a stopwatch, gray bun, glasses). In the evening she's out front locking up (and proud of her new hire). Once Elric has met Nassan, **Nassan** works the register: he got hired *recently* (Tuesday). | Groceries (Trail Mix, Soda, Granola Bar, Deli Sandwich); from the health & beauty and seasonal aisles, a Nail File, Rain Poncho and Flip-Flops | Grocery-store muzak |
| **Jack in the Box** | **Dex**, 16, headset, permanently unimpressed. Open late; different greeting at night. | Two Tacos, Egg Rolls, Curly Fries, Burger (the shake machine is OUT OF ORDER) | A bouncy fast-food jingle |
| **Knotty Barrel** | **Big Lou**, the chef: tall hat, huge beard, yells everything. | Clam Chowder, Fish & Chips, Salmon Burger | A sea shanty |
| **Games & Cards** | **Old Man Pip**, back from getting a sandwich (it's been years). Opens in the afternoon. The only one who **buys** things: $2 each, flat rate, since 1987. | Card Pack Gum, Candy Dice, five **cards** (see below), and the **Divergent Glove** from his glass case of oddities | An old ragtime music box |

Each shopkeeper has their own things to talk about (some only after something has happened, like Rock Paper Scissors or Nat's story), marked NEW until you've asked, their own reasons not to buy your stuff, and their own goodbye. If Elric has been killing things, they're nervous when you come in.

**On the Genocide route (once everyone has gone; it starts after Chapter 1, so this is for coming back to the mall later):** the shops are empty, the lights half off, and each shop's song plays at less than half speed, a tritone lower, drowned in echo. The menu becomes **Steal / Register / Read / Exit**: take anything for free, empty the register (once), or read the note the shopkeeper left on the counter. Every note is written to make you feel it. At Vons, Gloria's CLOSED sign is on top, and under it Nassan's note: to Elric, personally, five pages of receipt paper (LEFT / RIGHT flips them): the plan on his wall with Elric's name on it, Hop coming by every day to talk about Elric, looking for the step where he could have stopped it.

**Cards** (Games & Cards) go in their own **Card** slot, one per person, and each has a picture and a power instead of stats: **Lucky Card** (1 in 6 FIGHT hits are LUCKY, 2x damage), **Heart Card** (survive one knockout a battle at 1 HP), **Clover Card** (+50% money from battles), **Snack Card** (food heals 50% more), **Clock Card** (enemy attacks move 15% slower).

**Who hangs out there, and what they're up to:**

| Who | Where | What happens |
|---|---|---|
| **Supreme** | Outside Vons | Rattles off stats from his seven spreadsheets; knows how the tutorial fight went. |
| **Crayola** | Outside Games & Cards | Shy; offers a card trick (Seven of Hearts). Swims with N.C. Wethan. |
| **N.C. Wethan** & **Ronin** | Knotty Barrel patio | The checkers running gag ("KING ME!!!" / "THAT'S CHESS."). N.C. Wethan sparks when excited; Ronin has lost 14 in a row and got his guitar banned after "the fire alarm thing." |
| **MuffinMage** | Knotty Barrel patio | Eating a salmon burger in a fish mask. Neutral, but warns Elric about the fragment. |
| **Rooster** | Parking lot | Roasts Elric; the player can roast back ("Couldn't pick a color?" → "It's called DUALITY."). |
| **Sansworth** | Parking lot | Looking for a car he doesn't have; gives Elric a Trail Mix. |
| **Nat** | By the bench near Jack in the Box | **Lore:** the old story of twelve fragments and Hopkuna, with the last page torn out. Hop goes still. |
| **Nassan** | By the road east | **Plot:** has mapped strange reports and sends Elric to **Westview High School after dark**. Required to move on. Then his shift starts: he got hired at **Vons** recently, and walks off to work the register until closing. |

**The day goes by (as built):** after Nassan, it's only about 2 PM, and Westview only gets weird after dark. N.C. Wethan yells for a third player, and Elric gets roped into a **Rock Paper Scissors minigame** (drawn hands, a "ROCK... PAPER... SCISSORS... SHOOT!" countdown, a score). Three rounds vs. N.C. Wethan, whose lightning crackles in the *shape* of his throw; one vs. Ronin, who hides his hand but not his *shadow*; and a final round vs. **Agent**, who counts every throw you've made, says the odds out loud, and always plays the counter to your most likely throw. Follow his math and you can beat him. Win all five and Ronin pays up with Curly Fries. Then hours pass:
- **Afternoon** (golden light): everyone has moved. Supreme does "field research" at Jack in the Box, Crayola and MuffinMage play a made-up card game, Rooster power-walks laps, Sansworth checks every car. Talking to three people makes the sky go orange.
- **Evening** (pink): shops close, people say goodbye, and Nassan waves Elric over. Talking to him brings nightfall.
- **Night** (blue): only N.C. Wethan, Ronin (stargazing), Nat and Nassan are left. The road east finally opens. Trying to leave before dark, Hop stops you.

## 3. The main character

**Elric** (original character) — pronouns: **they/them**

- A traveling adventurer.
- Has no home, not because of money, but because Elric never stays anywhere for long.

### Personality
- **Soft-spoken but strong-willed.**
- **Determined** in everything they do.
- **Speaks, but rarely.** When Elric does say something, it should matter.

### Appearance
- Average size.
- Gender-neutral.
- Short **brown** hair.
- Dirty, scruffy clothing (fits a life on the road) — a patched brown tunic with a rope belt and olive pants in the current sprite.
- Soft, almost pastel **purple skin**.

### Relic

**Relic is to Elric what Chara is to Frisk.** (RELIC is an anagram of ELRIC.) Relic's color is **green** (Hopkuna's is red), so the two are never confused.

Pronouns: they/them

**Who Relic was**
- **Five years ago**, a kid showed up in San Diego alone, with a backpack and nowhere to be. A wanderer, like Elric. They slept in the **picnic shelter by Westview Field** (the same shelter that's now Revolution's base).
- **Hop** found them there one morning and brought them curly fries from Jack in the Box. They were inseparable all summer: **Hop's best friend**.
- They never told anyone their real name. They **collected things**: bottle caps, keys, a cracked compass, a single chess piece. Hop teased them that they collected "relics," and the name stuck. It's the only name anyone ever knew them by.
- Hop told Relic about the voice inside him. Relic was the only person he ever told, and they weren't scared: *"Everybody's got something in them they didn't ask for."*

**Relic's power: KEEPSAKE**
- Relic could **take something out of a person and keep it in an object**: never strength or magic, only what someone carried inside them (a fear, a bad memory, a grief). Relic would hold their hand, the weight would lift out of them, and it would settle into something small Relic carried.
- That's what the collection really was: every "relic" in their backpack held someone else's pain. They wandered from town to town carrying other people's burdens so those people didn't have to.
- **The rules:**
  - **Touch only.** Relic had to be holding on.
  - **The person has to let go.** Relic could only take what someone truly wanted gone. ("You can't pull a splinter out of a fist that won't open.")
  - **It costs Relic.** Every keepsake weighed on them a little. Small things were fine; something big could break them.
- That summer, Relic took Hop's nightmares (the ones about the voice) and kept them in a Jack in the Box curly-fry token: the last thing in the collection.
- Relic had offered before: "If you ever want him gone, I could try." Hop always said no. Hopkuna had been in him his whole life, and Hop was scared of what he'd be without him.

**The night of the fire**
- At the end of the summer, they camped on **Westview Field** in Hop's dad's old **three-person tent**. Relic joked there was room for three: "You, me, and him."
- That night the **Santa Ana winds** came in hot off the hills, and a **brush fire** jumped the canyon. In minutes the field was ringed in fire, the smoke too thick to see the road.
- Hop panicked and did the one thing he swore he never would: he **let Hopkuna out**, for the very first time, to save them both.
- Hopkuna saved Hop's body. Then he looked at the fire (the whole city lit up orange) and he *liked* it. Relic grabbed him and begged Hop to come back, and **Hopkuna turned on Relic**.
- In the middle of it, Relic saw Hop for a second, fighting from the inside, and held on: **"Hop. Let go."** For the first time in his life, Hop did. He wanted Hopkuna gone more than anything.
- So KEEPSAKE worked: Relic pulled **all of Hopkuna's power** out of Hop's chest at once. But it was far too big to keep in any object, and too big for Relic. Relic broke apart around it.
- Hopkuna's power and Relic **shattered together into twelve pieces**, and the wind carried them across San Diego. **Each fragment is Hopkuna's power wrapped in a piece of Relic**: the last keepsake they ever made. Only Hopkuna's *mind* stayed in Hop (it was tied too deep to his soul to let go of), which is why Hopkuna is weak now, and why he needs the fragments back.

**Afterward**
- Hop woke up at dawn in the burned field, alone. The tent was half melted. **Relic was never found.**
- To the city, it was a fire with one missing kid nobody could put a name to. Only Hop remembers Relic, and he's never told anyone what really happened. He hasn't had a nightmare since.

**What this explains**
- **The tent** encounter is *that* tent: "We were here, too. Two of us. There were two, when there were meant to be three." It's Relic talking: the tent was meant for three (Hop, Relic and Hopkuna), and two of them, Relic and Hopkuna's power, ended up in the fragments.
- **The wind** at the end of the tent is the Santa Ana wind that spread the fire and scattered the fragments.
- **Hopkuna's "watch the world burn"**: the first thing he ever saw was a city on fire.
- **The crater** on Westview Field in Chapter 1 is where it happened; Hopkuna breaks out in the same place ("Right here, on this field").
- **The first fragment** "hums, like it's breathing," and it's warm: Relic is in there. Hop "stares at it a little too long": he can feel them.
- **Nassan's "Don't carry it alone"** is Relic's whole tragedy: they carried everything alone, and it killed them. (And his Genocide note: "I told you not to carry it alone.")
- **BOND**: Elric grows stronger through connection, the opposite of how Relic lived. On Pacifist, Elric is what Relic never had: someone who doesn't carry it alone. Destroying the fragments finally lets Relic put the keepsakes down. On Genocide, Relic stops carrying and starts *taking*.

**Mysteries for later chapters**
- **Who tore the last page out of Nat's book?** Hop did: it had Relic's name on it (a Chapter 3 reveal).
- **What started the fire?** Never solved. Hopkuna, much later: *"I didn't start that fire, little wanderer."* ... *"Probably."*

**Hooks for later chapters**
- **Relic's lost collection**: optional items across the map (the bottle cap, the cracked compass, the chess piece...), each holding a stranger's old pain, with its story when you CHECK it. The curly-fry token is last, and it goes to Hop.
- **A green core**: in a later chapter, Elric notices a faint green light deep inside each fragment, under the red.
- Hop realizing why he never had nightmares again.
- Small Chapter 1 seeds (built): Hop laughs "a second too late" when Ronin brings up fire at the mall, and on Westview Field something behind Hopkuna's eyes flinches from Ronin's fire ("It isn't Hopkuna."); old scorched tent stakes past the edge of Westview Field ("...Leave those." "Probably from somebody's campout. A long time ago."); a faded MISSING flyer on the mall wall by the empty store, no name and no photo left, just LAST SEEN NEAR WESTVIEW FIELD (Hop won't look at it).

**Relic and Elric**
- **Keepsake memories (built: 1 to 3)** (`scripts/scenes/keepsake.gd`, `scenes/keepsake.tscn`): each fragment holds a memory of Relic's, played as Relic (their own sprites: `relic*.png`), tinted green, with a KEEPSAKE n / 12 title card and Relic's theme. The first three play the first night after the choice: after the bunk dream (Corps), on a curb at 3 AM while wandering (own way), or on Hop's couch (with Hop, where Relic adds a bitter line at the end of each, as "we"). 1: a road into San Diego at dawn ("Just passing through."), picking up a bottle cap. 2: sneaking into Westview's gym to sleep, and the kid in the trophy case glass. 3: Westview Field, Hop with two orders of curly fries, and the name: "You collect relics or something?" See STORY.md for all twelve.
- When Elric picks up the first fragment, Relic **wakes up and rides along** with them. It's why Elric always wandered without knowing why: the fragments were calling.
- Relic is **present on every route**, and the route decides what Relic becomes:
  - **The narrator:** the "* (...)" narration is quietly Relic's voice (never said outright).
  - **Dreams:** when Elric sleeps (the bunk at the Corps' base), Relic speaks to them directly. At first Relic doesn't know who Elric is, only that Elric is carrying them.
  - **Pacifist:** Relic wants Hop freed. Destroying the fragments frees Relic too, and Relic says goodbye to Hop through Elric.
  - **Neutral:** Relic stays restless and keeps pulling Elric onward: the endless wandering.
  - **Genocide:** Relic's grief turns to rage at everyone who let it happen. The narration drops the parentheses and says **"we"**; a mirror says **"It's me, RELIC."** (Relic only ever says their name on the Genocide route itself, which starts after Chapter 1.) In the end, Relic turns on Hopkuna, then on everything.

**Hints in Chapter 1 (built)**
- Meeting Elric, Hop: "Elric. ...Huh. Sorry. You just remind me of someone."
- Arriving at Westview, Hop slips: "Rel-- Elric. Stay close, okay?" (and blames the late hour).
- Nat's story: "Somebody gave everything to break it apart. The book doesn't say who."
- After Hopkuna leaves, Hop: "The last time I let him out, I lost somebody. I swore it would never happen again."
- The tent's ending: Relic's green eyes in the dark, and the wind of the field they died on (the first sign of how they died).
- Hopkuna on Westview Field: "The last time was years ago. Right here, on this field. He had a friend back then, too. ...I know that look. I killed the last one who had it." Then: "(Something in the fragments goes cold.)"
- The first dream (resting on the bunk at the base, Pacifist or Neutral): the voice in the dark, with different words for each route.
- Rooster's mirror at the base: the first time, "(For a second, the reflection looks like someone else.)" (Rooster is not happy you're using it.)
- The trophy case in Westview's hallway (set into the wall): "(In the glass: it's you.)" With some dread, the reflection looks away a moment before you do; with a lot (10+ kills), it's someone in a scorched green hoodie, and it smiles (you can't tell if you are). On the Genocide route: "It's me, RELIC."
- The Genocide end page: "Somewhere in the dark, Hop is waiting. So is someone else." Then, in green: "...And so are we."
- A Westview student (Chapter 2): her friend swears her reflection in the trophy case winked at her.
- On the Genocide route, the empty shops and people backing away are narrated as "we" ("Nobody stops us. Nobody can.").

**Continuity:** the Genocide route only starts at the end of Chapter 1 (Go with Hop), and right now it goes straight to the demo end, so its content (empty shops, "we", the RELIC mirror) is ready for when Genocide reaches those places in later chapters. During Chapter 1, killing only raises dread: Elric looks worse, people flinch and back away, shopkeepers are nervous, and the reflection goes wrong. Nobody leaves and Relic doesn't say their name yet.

### Townsfolk

Every place is full of people who aren't in the REVOLUTION Corps, and not all of them are human (`scripts/townsfolk.gd`). Each has their own sprite and their own expressions (art/portraits), and a conversation: a line, **two answers** to pick from (they react to each), and **Challenge**, which starts a real fight with them (with their own attacks, ACTs and CHECK). Defeat someone and they're **gone for good** (it counts toward dread like any other kill); spare them and they remember it. Nobody in the Corps can be challenged... yet. Talk to someone with dread and they may flinch first (now and then at low dread, always at the end); whoever flinches is nervous the whole conversation (a scared face, a stumbled first word). The more dread, the more people keep away: backing off, then running, then hiding and peeking out at you. (N.C. Wethan and Ronin never leave their game.)

**Everyone fights their own way** (`scripts/folk_attacks.gd`): Coach Ramirez lobs his key rings and runs cone drills (LAPS); the Janitor slides WET FLOOR signs and tips out trash; the Skater kickflips and grinds a rail through you; the Waiting Ghost's clock ticks fly at you, and their ride's headlights come... or don't, and one comes from the other side; the Mall Cop drops gum that sticks and patrols on his segway; the Busy Mom throws coupons and her grocery bags hop (and burst into apples); the Pigeon Man's flock flies in a V and Gerald dives for the crumbs; the Teen's notifications burst and the feed scrolls up forever; the Jogger runs laps around the box flinging sweat; the Night Janitor's moths are drawn to your SOUL (the light) and his wing dust spirals out; the Security Guard's flashlight sweeps and his Z's float up; Biscuit fetches and gets the zoomies; and students throw paper planes and backpacks full of books.

**Wild creatures** (`scripts/wild_battles.gd`): random encounters anywhere around town (once the tutorial's done; not on the night walk to Hop's, and not in the middle of the night on Westview Field), each with their own attacks: the **Runaway Cart** and **Receipt** at the mall, the **Lost Balloon** (mall and park), the **Goose** and the **Sprinkler** at Westview Field, the **Garden Gnome** and **Lawn Flamingo** in the neighborhood, the **Hungry Seagull**, the **Squirrel** and the **Plastic Bag** around Mt. Carmel and Westview. Inside Westview at night, the school's own creatures still show up.

**Killing for real** (anyone but the tutorial, the training dummy or a boss): green cracks run across them, they break into pieces, and the wind carries them away. Hop gets more nervous the more you kill: he trembles in battle, and after each kill he says something new at each step (1, 2, 4, 8, 14, 20, 40 and 75 kills: "...Your eyes. Since when are your eyes green?" ... "Who ARE you?" ... "...You look just like-" "No. No, you don't."), or just reacts.

| Where | Who |
|---|---|
| Mt. Carmel | **Coach Ramirez** (a rhino in a red tracksuit; loses his keys in a tree, daily) · the **Janitor** (a raccoon in coveralls; has heard every joke) · the **Skater** (a frog; almost landed a kickflip, spiritually) · the **Waiting Ghost** (a little ghost whose mom is "five minutes away"... still) |
| PQ Mall | the **Mall Cop** (a walrus with a mustache, tusks and a badge; at night he guards the empty lot) · the **Busy Mom** (a kangaroo, groceries and one kid in her pouch) · the **Pigeon Man** (an old man covered in pigeons, all named Gerald, after his late wife Geraldine) · the **Teen on Phone** (a jelly blob in a hoodie, texting themself) · the **Jogger** (an ostrich who can't fly, so runs; afternoons) |
| Westview (night) | the **Security Guard** (an owl who sleeps through the night shift: "I'm a MORNING owl") · the **Night Janitor** (a moth who mops while the bells ring by themselves) |
| Westview (day) | eight kinds of students: a bunny in a letterman jacket, a robot, a sleepy sloth, a lizard in a hoodie, a mushroom kid, a hamster Wolverines fan, a bookworm (an actual worm, in glasses) and a cat in headphones |
| Westview Field | the **Dog Walker** and **Biscuit** the corgi, who won't go near the middle of the field ("There was a fire out here, a few years back.") |

## 4. The cast

| Character | Notes |
|---|---|
| **Eggo** | Co-founder of Revolution. See [Eggo](#eggo) below. |
| **Big Joe** | Co-founder of Revolution. See [Big Joe](#big-joe) below. |
| **MuffinMage** | See [MuffinMage](#muffinmage) below. |
| **Nassan** | See [Nassan](#nassan) below. |
| **N.C. Wethan** | See [N.C. Wethan](#nc-wethan) below. |
| **Sansworth** | See [Sansworth](#sansworth) below. |
| **Ronin** | See [Ronin](#ronin) below. |
| **Rooster** | See [Rooster](#rooster) below. |
| **Crayola** | See [Crayola](#crayola) below. |
| **Supreme** | See [Supreme](#supreme) below. |
| **Nat** | See [Nat](#nat) below. |
| **Agent** | REVOLUTION Corps. See [Agent](#agent) below. |
| **Hop** | A friend whose evil alter ego is Hopkuna. See [Hop](#hop) below. |
| **Hopkuna** | **The villain.** Hop's evil alter ego. Inspired by the *concept* of Sukuna from *Jujutsu Kaisen* (a malevolent being sharing someone's body), but an original character. |

### Eggo

Pronouns: any/all · Co-founder of Revolution

**Personality**
- Chill.
- Talks briefly.
- Cracks puns whenever he finds a good moment.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/eggo.png))
- Yellow skin.
- Long, messy yellow hair that falls past the shoulders to the upper chest.
- A yellow beanie with **cat ears**.
- **Face:** the classic black-eyed Roblox face with a grin *(the reference picture is old and shows a different face — use the black-eyed grin instead)*.
- Black vest over a blue shirt, black pants.
- A **little bunny friend** sitting on his shoulder.

![Eggo reference](art/reference/eggo.png)

### Big Joe

Pronouns: he/him · Co-founder of Revolution

**Personality**
- Very spirited.
- Strives for **justice and truth**.
- Also a jokester, like Eggo.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/bigjoe6.png))
- Silver knight's helmet with a spiky black-and-red crest.
- Black shirt with a "777" chain necklace, white cuffs.
- Belt and blue jeans.

![Big Joe reference](art/reference/bigjoe6.png)

### MuffinMage

Pronouns: he/him · Member of the REVOLUTION Corps

**Personality**
- Neutral.
- Loves **salmon burgers**.
- Talks casually, but can be serious at times.

**Appearance**
- A big red-orange **fish mask** (goldfish-style, with a wide-open mouth) covering his whole head.
- Orange shirt.
- Blue jeans.

### Nassan

Pronouns: he/him

**Personality**
- Very wise, but youthful.
- A **planner**.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/nassan.png))
- Black head, face mostly in shadow.
- Black hat with white trim.
- Black shirt that says **"im batman"**.
- Light gray arms.
- Dark, patterned pants.

![Nassan reference](art/reference/nassan.png)

### N.C. Wethan

Pronouns: he/him

**Personality**
- A meathead — a dunce, even — but **true to himself**, and that's all that matters.
- **Very loud.**
- A **powerhouse**.

**Powers**
- **Lightning.**

**Appearance** (based on his Roblox avatar — [reference image](art/reference/ncwethan.png))
- Classic yellow Roblox skin with a simple smiling face.
- Black helmet with yellow-tinted goggles.
- White T-shirt with a red-and-orange star/flame emblem.
- Blue pants.
- Swirling **blue rune ribbons** circling around him (could become his lightning/power effect).

![N.C. Wethan reference](art/reference/ncwethan.png)

### Sansworth

Pronouns: he/him · Member of the REVOLUTION Corps

**Personality**
- A complete **idiot**.
- The **comic relief** character.
- Still makes himself **useful**.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/sansworth.png))
- White head with dark eyes and a wide, slightly unsettling smile.
- Sharp black pinstripe suit, white shirt, black tie.
- Black pants.

![Sansworth reference](art/reference/sansworth.png)

### Ronin

Pronouns: he/him

**Personality**
- **Loud** — on par with N.C. Wethan.
- Plays **guitar**.
- Always seen **losing at checkers to N.C. Wethan** (running gag).

**Battle role**
- **Mage.**

**Appearance** (based on his Roblox avatar — [reference image](art/reference/ronin.png))
- Wide-brimmed **red mage hat** topped with a jagged black crown that's **on fire**.
- Pale face with a frown, long dark hair.
- Red, rough-textured robe.
- One arm wrapped in **barbed wire**.
- Carries a tall, spiky black **staff with a cyan flame** at the top.

![Ronin reference](art/reference/ronin.png)

### Rooster

Pronouns: he/him

**Personality**
- A **goofball** who dogs on people for fun…
- …but gets **mad when he gets dogged on**.
- Thinks he's **better than everyone** — played as **satire**, not seriously.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/rooster.png))
- Light skin, messy dark hair.
- Black top hat.
- Goofy face with his **tongue sticking out**.
- A suit split down the middle: **half white, half black**, with a black tie.

![Rooster reference](art/reference/rooster.png)

### Crayola

Pronouns: he/him

**Personality**
- **Shy.**
- Likes to play **card games**.
- **Swims with N.C. Wethan** for fun.

**Battle role**
- **Support** character.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/crayola.png))
- White head with a happy, open-mouthed smile.
- His whole torso and arms are a giant **employment / job application form**, with a small blue badge on it.
- Gray, worn pants.

![Crayola reference](art/reference/crayola.png)

### Supreme

Pronouns: he/him

**Personality**
- A **nerd**.
- Loves to pull out **facts and statistics**.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/supreme.png))
- Spiky black hair with a yellow-and-white headband/visor on top.
- Black face mask with a little bear face on it; one glowing **purple eye** visible.
- Navy striped scarf.
- Yellow long-sleeve shirt with black designs on the sleeves and a big **burger** on the front.
- Black ripped jeans.
- Green-and-white sneakers.

![Supreme reference](art/reference/supreme.png)

### Nat

Pronouns: he/him

**Personality**
- **Deadpan and unbothered.** Nothing rattles him; he answers chaos with a dry one-liner.
- **A bookworm who knows the past.** Where Nassan plans the future, Nat knows history — including old stories about **Hopkuna and the fragments**. He's the character who explains the lore to Elric.
- **Running gag:** the open book on his head. Everyone assumes he's studying; half the time he's actually napping under it.

**Battle idea**
- Abilities pulled from his books: "reading up" on an enemy mid-fight to unlock new ACT options or reveal how to spare them.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/nat.png))
- Dark skin, calm half-lidded eyes.
- An **open book resting on his head** like a little roof.
- **Purple** shirt.
- Black arms and pants.

![Nat reference](art/reference/nat.png)

### Agent

Pronouns: he/him

**Personality**
- **Member of the REVOLUTION Corps.**
- **Arrogant and smart.** He knows he's the smart one, and says so ("Because it's true for everyone").
- **Quick and to the point.** Short sentences, no wasted words, always clear. ("Four. Next.")

**Where he shows up**
- **PQ Mall:** leaning by the FOR LEASE store (he wrote "REVOLUTION HQ" in the dust; the question marks were Eggo). He stays through the afternoon and evening, giving blunt advice about Westview.
- **Westview Field:** arrives with the Corps against Hopkuna ("Thirteen of us. One of you. Do the math."), and reacts to Elric's route choice.

**Appearance** (based on his Roblox avatar)
- Yellow skin and a friendly smile.
- Wavy brown "bacon" hair.
- An open **black jacket** over a **teal** T-shirt with a dark graphic on it.
- Dark patterned pants and **white** shoes.



### Hop

Pronouns: he/him

**Personality**
- Very athletic.
- Sarcastic — a jokester.

**Appearance** (based on his Roblox avatar — [reference image](art/reference/hop.png))
- Black fedora.
- Gray, blocky head with an angry, gritted-teeth grin.
- Dark gray shirt with lighter gray arms.
- Blue-gray pants.

![Hop reference](art/reference/hop.png)

### Hopkuna

Pronouns: he/him

**Who he is**
- An entity of **pure evil** who wants to **watch the entire world burn**.
- That includes **Elric** — but Elric doesn't know that. *(Even on the genocide route, Hopkuna plans to turn on Elric eventually.)*

**What he wants**
- Hopkuna needs **the fragments**: without their power, he can't continue his plan.

**How Hop and Hopkuna are connected**
- **Hop knows Hopkuna exists.**
- Hop treats Hopkuna as a **last resort**, and only lets him out when Hop is **genuinely in danger**.
- **Once Hopkuna has 12 fragments, he takes over** (for good).

**The fragments**
- There are **exactly 12** fragments in total — Hopkuna needs **every single one**.
- Every fragment the player finds is one step closer to disaster (or, on the pacifist route, one more to destroy).

**Appearance**
- Same body as Hop.
- **Very specific tattoos all over his body** (designs to be decided).
- A **light red tint** over his whole body.

## 5. Battles

- **Team battles like Deltarune:** up to **3** party members fight at once.
- **Elric chooses the team:** Elric plus 2 cast members of the player's choice.
- **The whole cast is available** — every character can be a party member, so the player can mix and match for unique team-ups and dialogue.
- **EXP without violence:** on the pacifist route, you gain EXP by doing other things, so you can grow strong without hurting anyone.

### Two ways to grow: LOVE and BOND

| Stat | Stands for | Grows from | Route |
|---|---|---|---|
| **LV (LOVE)** | **L**evel **O**f **V**iolenc**E** (as in Undertale) | Defeating and killing enemies | Genocide |
| **BOND** | **B**ound by **O**ur **N**ew **D**etermination | **Sparing enemies** (ACT/MERCY — harder spares give more) and **bonding with the cast** (hanging out, talking, making choices with Revolution members) | Pacifist |

- Both stats make Elric stronger, but in different ways.
- The player can tell which path they're on just by looking at their stats.
- Ties into the title: **LOVE** to ruin, **BOND** to save.
- **The meaning of BOND is kept secret** (like LOVE in Undertale) and revealed near the end of the pacifist route: *"BOND. Bound by Our New Determination."*
- **SAVE points and resets** work like in Undertale/Deltarune.
- **DETERMINATION** exists in this world.

## 6. Story outline

### Beginning
Elric is a traveling adventurer with no fixed home.

#### Chapter 1 opening — how Elric meets the cast
0. **The voice.** Before anything else, a voice with no face (secretly Hopkuna) explains the objective — find the 12 fragments — and the ways to get there: TALK and SPARE for BOND, or FIGHT for LOVE. Then it asks: *"Here is your objective. How will you do it?"* Elric's answer comes back to haunt them when Hopkuna is revealed at Westview Field.
1. **Hop first.** Elric arrives in the area and meets **Hop** before anyone else. Hop seems friendly, if a little strange, and the two become friends. The player has no idea that Hop and Hopkuna are the same person.
2. **The first fragment.** Elric picks up one of Hopkuna's fragments.
3. **Mistaken for an enemy.** **Eggo** and **Big Joe** catch Elric holding the fragment, assume Elric works for Hopkuna, and attack. This is the **tutorial fight** (see below).
4. **The reveal at the Chapter 1 climax.** Hop gets into **genuine danger**, and as a last resort, **Hopkuna comes out for the first time in years** (the first time since the night Relic died, on this same field; see [Relic](#relic)) — right in front of Elric. The friendship built over Chapter 1 makes the twist hit hard.
   - **The 3rd fragment erupts:** when Elric and Hop uncover it under the big field, its unstable power lashes out — straight at Elric.
   - **Hop takes the hit:** **Hop jumps in front of it** and is badly hurt.
   - **Hopkuna erupts:** tattoos spread and the red tint washes over Hop's body. Hopkuna came out to save Hop's body — and, technically, **Elric's life**.
   - **The boss is Hopkuna himself:** then Hopkuna turns on Elric. **Chapter 1's final battle is against Hopkuna** on the big field — a fight Elric can't truly win, only survive.
   - **The Corps arrives** and drives Hopkuna back; Hop returns to normal. Elric is still shaken when the Corps asks the big question.
5. **The route choice ends Chapter 1.** Right after the reveal, the full **REVOLUTION Corps** finds Elric and asks what Elric wants to do (see [The route choice](#the-route-choice)). The player knows exactly what "Go with Hop" means. Chapters 2–4 play out differently depending on the answer.

#### The tutorial fight: Eggo & Big Joe *(proposed — open to changes)*

This fight **teaches every core mechanic**, one at a time, through the characters' own dialogue instead of pop-up text boxes.

| Turn | What happens | Mechanic taught |
|---|---|---|
| **Start** | Big Joe charges in: "Hand over the fragment, Hopkuna's lackey!" | The battle screen, party HP |
| **1** | Big Joe attacks first. The SOUL appears in the box. | **Dodging** with the SOUL |
| **2** | Hop: "Don't just stand there — hit 'em!" | **FIGHT** (the timing bar) |
| **3** | Eggo, unbothered: "...you could also just talk to us." | **ACT** — starting with **CHECK** (enemy stats) |
| **4** | Elric can ACT on each enemy: tell Eggo a pun (he can't resist), tell Big Joe the truth (he values justice and truth). | **Character-specific ACTs** |
| **5** | Hop takes his own turn and acts alongside Elric. | **Team turns** (party members act too) |
| **6** | Elric takes a big hit; Hop tosses over a snack. | **ITEM** and **DEFEND** |
| **7** | Eggo and Big Joe's names turn yellow. | **MERCY / SPARE** — sparing earns **BOND** |

- **Two ways out:** the player can SPARE them (earns BOND) or FIGHT them down (earns LOVE). Either way, they're only **knocked out, not killed** — it's a tutorial, and both survive to become part of the cast.
- **Hop fights alongside Elric** as a temporary party member — which makes his later reveal hurt more.
### Middle
Elric meets the cast and recognizes the villain, **Hopkuna**. Elric works and travels the lands in search of **Hopkuna's fragments**.

#### What Elric is searching for
- **The surface goal — Hopkuna's fragments.** Pieces of Hopkuna's power are scattered across San Diego (similar in concept to Sukuna's fingers in *JJK*). Revolution wants them destroyed, Hopkuna wants them back, and Elric collects them. They give the player a clear goal and a reason to explore every corner of the map.
- **The real goal — a home.** Elric has always wandered without knowing why. What Elric is truly looking for is a place to belong.

How it pays off on each route:

| Route | The fragments | A home |
|---|---|---|
| **Pacifist** | Destroyed with Revolution to free Hop. | The cast becomes Elric's home. |
| **Neutral** | Kept, or ignored in favor of exploring. | Elric keeps wandering. |
| **Genocide** | Given to Hopkuna, making him unstoppable. | Elric destroys any chance of having one. |

### The route choice
When Elric **meets the REVOLUTION Corps**, they ask what Elric wants to do, and Elric must **manually choose a route**:

> **Go with Hop.**
> **Go my own way.**
> **Join the REVOLUTION Corps.**

The route names (Genocide, Neutral, Pacifist) are **never shown** in the game, not in the choice and not on the ending screen. The player should choose what Elric wants, not what they know will happen. (Behind the scenes: Go with Hop = Genocide, Go my own way = Neutral, Join the Corps = Pacifist.)

What each choice locks:

| Choice | Result | Pacifist later? | Genocide later? | Neutral later? |
|---|---|---|---|---|
| **Go with Hop** | The Corps kicks Elric out. | 🔒 Locked | — | 🔒 Locked |
| **Chart your own path** | The Corps offers Elric the chance to come back and join them later. | ✅ Still open | 🔒 Locked | — |
| **Join the REVOLUTION Corps** | Elric joins the team. | — | 🔒 Locked | 🔒 Locked |

So Neutral is the only choice that can still change, and only toward Pacifist.

### Endings — decided by the route choice and how the player plays

| Route | Elric's choice | Notes |
|---|---|---|
| **Pacifist** | Band together with the cast to defeat Hopkuna. | EXP comes from non-violent actions. |
| **Neutral** | Do nothing; keep expanding and exploring the world. | |
| **Genocide** | Join Hopkuna. | The player must kill everyone. |

## 7. Size

- **One big game, no chapters.** The story just goes on, and where it goes depends on what you choose. 12 fragments in all.
- (Older notes that say "Chapter 1" mean the opening, up to the choice on Westview Field; "Chapter 2" means after it. The internal flag `chapter1_done` just means the choice has been made.)

| Part | Fragments | Area |
|---|---|---|
| **The opening** | 3 (fragments 1–3) | Mt. Carmel High School, the PQ Mall, Westview High School, Westview Field |
| **After the choice** | 9 (fragments 4–12) | *to be decided* |

**Right after the choice on Westview Field:**
- **Join the REVOLUTION Corps:** the Corps opens a hatch hidden under the picnic shelter, and Elric goes straight down into their base.
- **Go my own way:** the Corps goes down; Hop stays with them. Elric wanders the city all night, and by morning their feet bring them back to Westview Field anyway (by day; the hatch is right there). Elric travels **alone** (and fights alone) until they go down to the base.
- **Go with Hop:** nothing says Genocide yet (the route is `with_hop`). Hop takes Elric back to his place for the night (`scripts/scenes/hop_house.gd`):
  - **The glowbug.** Halfway down Hop's quiet street, a tiny lost glowbug sits on the sidewalk ("Oh. Hey, little guy. You lost too?"). The fight can't be avoided. **No music.** Hop isn't in the battle at all (Elric is alone with it, already somewhere Hop can't follow: "You can't hear Hop anymore."). **MERCY, ACT, ITEM and DEFEND are greyed out and chained**; trying them, a voice in green (Relic) mocks you: "No." "That isn't for us." "Kill it." "Why are you waiting? It's so small." The glowbug can't fight back; it just trembles. FIGHT (in Relic's green) is the only way out, and it hits for **1851293** (18-5-12-9-3: R-E-L-I-C). **Killing it starts the Genocide route, officially** (and Elric's look, the green vignette and the music change from then on). **From this fight on, Elric's attacks are Relic's:** green slashes with a fainter second set a beat behind (two of them swinging), a pale green impact flash, green embers rising off the hit, and green damage numbers that jitter and flicker, with faint red and purple copies splitting off (the other two of the three).
  - Hop, after: "...Elric? It wasn't- it wasn't doing anything." He reluctantly lets Elric in: "...I said you could stay. So."
  - **Hop's house:** small, humble, one of everything (one plate, one cup, one fork), a checkers game played against himself, a push-up bar ("FORTY. CAN'T FEEL ARMS = GOOD."), and an old curly-fries coupon for two he kept. Hints at **Hopkuna**: a mirror with a towel taped over it, tally marks under DAYS that stop at yesterday, and a note: "DON'T LET HIM OUT. NOT EVER. NOT FOR ANYTHING." Hints at **Relic**: a face-down photo of two kids in front of a tent (one face rubbed away; "...Put that back. Please."), a jar of bottle caps labeled KEEP in someone else's handwriting, a calendar stopped at the end of August five years ago, and a half-melted tent in the closet. Under the towel, on this route: "It's me, RELIC."
  - **Sleep** on the couch ("Across the room, Hop doesn't sleep."), and the first three keepsake memories. **Morning:** pancake-shaped pancakes, the only plate for Elric, Hop eating as far away as the kitchen allows, and *"Are they... green? Were they always green? ...Weird lighting."*
  - **Out the door:** on the porch, Hopkuna speaks for the first time since the field: *"...Hop. That isn't your friend."* Hop: *"Shut up."* Then the next fragment: Mission Beach, by bus from the PQ Mall. The street leads back into the city (by day, from now on), and at the mall, **Dex sees Elric through the window of Jack in the Box, drops the tray and runs**, the first shopkeeper to go (Relic: *"He ran from us. Smart."*). The others leave as the killing goes on (Pip at 15 kills, Big Lou at 30, Nassan at 50).

**Mission Beach (fragment 4, built, all paths)** (`scripts/scenes/mission_beach.gd`, `scripts/beach_battles.gd`): by bus from the PQ Mall (a stop on the road at the bottom of the lot). A boardwalk, shops, sand, palm trees and the ocean; its own song ("beach"). At the west end, **the Dipper**, a wooden roller coaster from 1925, running all night with nobody on it. Fragment 4 is in its front car. Its fight has its own song ("dipper") and attacks: COASTER CARS (a train rattling along a wavy track through your row), THE DROP (cars climb in at the top, then all fall at once, with one gap) and LOOP (a ring of track closing in, one opening). Spare it by riding it properly: ACT Hands Up and Scream. Crayola and N.C. Wethan are on the sand:
  - **Corps:** they're on the mission with you. Crayola opens up (he swims; N.C. "CONDUCTS. IT'S A WHOLE THING."). After the Dipper he gives Elric the **Seven of Hearts**, from his trick at the mall ("for Elric" on the back, in crayon): a Card that heals 7 HP at the start of every turn.
  - **Own way:** they're here for the fragment too, and come running up the boardwalk too late ("NO FAIR!!! ...I GAVE you the head start.").
  - **With Hop:** they're waiting. Hop: *"We can just- we can go around."* Relic: *"We don't go around."* Crayola fights with cards (every one the Seven of Hearts) that spell COME BACK; N.C. Wethan's lightning strikes everywhere but you. MERCY is chained. They have last words before they shatter, and each leaves something in the bag that can't be used, sold or dropped (**KEPT:** Seven of Hearts, Checker Piece).
  - Then the 4th keepsake memory: the first time Relic saw the ocean, Hop teaching them to bodysurf, badly ("You're a natural! At DROWNING!" "...Again.").

**Balboa Park (fragment 5, built, all paths)** (`scripts/scenes/balboa_park.gd`, `scripts/balboa_battles.gd`): by bus from the PQ Mall or Mission Beach once fragment 4 is found. Outside: the Prado walkway, the museum with its tiled bell tower, a fountain, a lily pond; its own song ("balboa", warm, a little Spanish guitar). Inside: the arms and armor hall, and the archives through a doorway. **The Empty Knight**, a suit of armor from 1540 (on loan), walks the hall with fragment 5 glowing in its breastplate. All it has ever wanted is a worthy opponent. Its fight has its own march ("knight") and attacks: SWORD SWEEP (three slashes fanning from a top corner, the last through you), ARMOR RAIN (helmets and gauntlets tumbling down), SHIELD CHARGE (a kite shield charging along your row and back). Spare it by fighting fair: Salute, Fair Fight, Offer a Hand ("For 480 years, nobody has done that."). Then:
  - **Corps:** Big Joe is in the hall ("Salute first. Never hit it while it's down. That's justice."), and Nat is in the archives with a second copy of his book, the last page still in it: **"Their name was Relic."** Nat knows who tore his copy's page out, and asks Elric not to say anything: let Hop tell it himself.
  - **Own way:** Big Joe stands at the museum doors. A duel for the fragment, by the rules (ACTs: Tell the Truth, Salute, Fair Fight; it can be spared). Elric finds the page alone, at the reading desk.
  - **With Hop:** Big Joe is waiting at the doors ("I'm not going to call you a monster. I'm going to fight you. Fair."). MERCY is chained. He dies, and leaves his helmet crest (KEPT). Hop picks up his lance and puts it down very carefully. At the desk, Relic reads the page: "Our name. In a book. Nobody ever said it out loud."
  - The 5th keepsake memory: the museum steps after closing, Hop telling Relic about the voice inside him, and Relic: *"Everybody's got something in them they didn't ask for."*
  - Once the fragment and the page are both found, the objective points on to Old Town.

**The bus** (`Area.ride_bus`, `BUS_ROUTE`): every stop (the PQ Mall, Mission Beach, Balboa Park, Old Town) goes to every place the story has reached so far.

**Old Town (fragment 6, built, all paths)** (`scripts/scenes/old_town.gd`, `scripts/oldtown_battles.gd`): by bus once fragment 5 is found. Its own song ("oldtown", a bright plaza tune in D with an oom-pah bass). A dirt street with adobe shops under red clay roofs (new tiles: ADOBE, CLAY_ROOF): **Doña Rosa**'s tortillería (a hedgehog in an apron, comal steaming: TORTILLA TOSS, THE COMAL), the candle shop ("BACK IN 5 MIN", the sign is very old), a plaza strung with papel picado (a flagpole from 1846, four benches, pigeons, all of them Gerald), an old mail wagon, a well, the **Mariachi Cactus** (knows four songs, three are this one: NEEDLE SPRAY, MARACA BEAT) and the **Tour Guide**, a heron with a lantern who has never seen a ghost (LANTERN SWEEP, GHOST STORY). At the end of the street: the **Casa Vieja** (1851), every window dark but one.
  - Inside, a dining room: one long table set for twelve, clean plates, a grandfather clock stopped at seven, invitations that were never sent. **The Hostess** (the ghost of Isabel Arroyo) has set this table every night since 1874. Sit in the empty chair and dinner is served (her own waltz, "hostess", a lonely music box). **Her fight comes in courses** (a new battle mechanic, `Enemy.courses`): SOUP (waves of broth), THE ROAST (carving knives and forks), DESSERT (flans, bouncing and sliding down the table), one per turn, in order. Spare her by praising what's actually on the table this turn (Praise Soup / Roast / Dessert); praising the wrong dish only confuses her. Ask Her Name: "...Isabel." Spared, she sits down for the first time in 150 years, takes one bite of flan ("...It IS good. Isn't it."), and fades. Killed, the candles go out one by one. Leave before sitting down and she says it's alright, everyone does.
  - The fragment is in the candelabra.
  - **Corps:** Nat walks the plaza and tells Isabel's story ("I know too much history to get attached to anything. ...That's a lie. I just don't like ghosts."), and gives the hint: praise the RIGHT thing.
  - **Own way:** Nat is on a bench by the Casa. He won't stop you: "Just be nice to her. Whatever you are."
  - **With Hop:** Nat is sitting on the Casa's steps, reading. He has read ahead. MERCY is chained, Hop won't fight and only watches, and every turn Nat reads your next move out loud (CHAPTER BREAK, lines of text with one gap; DOG EAR, page corners folding in at you). "Page 213. The last page. ...I always wanted to know how it ended." His book is KEPT (page 213 is blank). Relic: "Dinner's ready."
  - The 6th keepsake memory: the plaza bench, five years ago. An old man crying over his wife, Geraldine. Relic takes his grief into a pigeon feather, and he laughs at the pigeons ("That one looks like a Gerald."). Hop, with churros, finds out what the backpack is really full of: "People's worst days. Somebody has to hold them." Relic tucks the feather into the bench: "I'll come back for it. I always come back for them." Afterwards, Elric understands: Relic's "junk" was everyone's pain.
  - **The feather** is still in the bench. Take it (KEPT), and, off the Genocide path, the Pigeon Man at the mall gets a new option: give it back. His grief comes back, all of it, five years at once; you (and your partner) sit with him until he's done. "It's supposed to be heavy, isn't it. She was worth carrying." (BOND +5.) Or keep carrying it for him. With Hop, Relic keeps it: "We keep what's ours."

**Downtown (fragment 7, built, all paths)** (`scripts/scenes/downtown.gd`, `scripts/downtown_battles.gd`, `scripts/downtown_attacks.gd`): by bus once fragment 6 is found. The city at night (its own song, "downtown", a walking bass in F minor): the Hotel Grande (the doorman is asleep standing up), the All-Night Diner (OPEN 24 HOURS, except when it's not), an office tower with one window lit, gaslamps, a red trolley that rings its bell as it goes by, a plaza with palms and a fountain (one of the pennies looks like a Jack in the Box token; it isn't), and the brick ballpark. Three new townsfolk: the **Hot Dog Vendor** (a dachshund; yes, it's weird: HOT DOG TOSS, MUSTARD), the **Living Statue** (silver from head to toe, hasn't moved since noon: FROZEN POSE, coins that stop in mid-air, TIP JAR) and the **Superfan** (a parrot in a jersey who has never seen the team win: RALLY TOWELS, PEANUT SHELLS). Wild: seagulls, bags, carts.
  - Inside the ballpark: the field, forty thousand empty seats, "R + H" scratched into the outfield wall, and **the Big Screen** over it, playing to an empty stadium for five years (HOME 0, VISITORS 0, IS ANYONE THERE?). Walk out to the mound and it wakes up (its own song, "big_screen", a ballpark organ that's lost its mind). **It replays your own last turn back at you** (INSTANT REPLAY: the battle records where the SOUL went, and lights come on along that path at the same moments), plus KISS CAM (a heart closing in, one gap), THE WAVE (every seat stands up, column after column: time it), FOUL BALLS, HOME RUN FIREWORKS and THE SCORE (0 to 7, falling). Spare it by giving it a crowd: Do the Wave, Cheer, Kiss Cam (it gets bored of the same thing twice). Spared: THANK YOU, [CROWD]!, and a replay of you doing the wave alone, over and over. Killed: it goes dark bulb by bulb, like a wave going the wrong way.
  - **Corps:** Supreme is in the dugout, and in the fight he **calls out the Big Screen's next attack every turn, with a hint** (`BattleData.announcer`; that attack is locked in). Afterwards, the 0.4%: "Statistically, I should leave. Emotionally, I'm staying. ...I didn't know I had that column."
  - **Own way:** Supreme is on the field, giving you your odds (61% against the screen; 12% of being nice about it). Afterwards: "Updating my model. You're 23% more decent than I predicted."
  - **With Hop:** Supreme is at home plate, computing ("Four for four. There's no outlier. I checked. Twice."). A bullet-hell made of statistics, and **every attack is labeled over his head with its odds of hitting you** (`Enemy.odds`): BELL CURVE 68%, STANDARD DEVIATION 95%, PIE CHART 75%, BAR GRAPH 50%, SCATTER PLOT 33%, REGRESSION LINE 81% (drawn through where you've been), MARGIN OF ERROR 97%; finale 0.4%. "I kept the odds you'd stop above zero. ...I rounded up." His spreadsheet printout is KEPT (STAYING ANYWAY, under the 0.4%). Relic: "Five."
  - The 7th keepsake memory: the same ballpark, after midnight, five years ago. Hop wakes up screaming (the voice, the fire, his own hands). Relic puts his nightmares into the only empty thing left in their pocket, a Jack in the Box curly-fry token, and wears it on a cord from then on. "It's quiet. It's never quiet." "...Will you stay up?" "Someone has to." Afterwards: "...What's it holding now?"

**The Harbor (fragment 8, built, all paths)** (`scripts/scenes/harbor.gd`, `scripts/harbor_battles.gd`, `scripts/harbor_attacks.gd`): by bus once fragment 7 is found. Its own song ("harbor", a sea shanty in G). The pier, gulls, a fish stand, a bronze seal in a sailor hat, and the old aircraft carrier (number 41, a museum now, three city blocks long). Three new townsfolk: the **Old Sailor** (a walrus; forty years at sea, twenty of them made up: ANCHOR, KNOTS), the **Tourist** (a sunburned capybara: FLASH PHOTO, SOUVENIR SPOONS) and the **Pelican** (sells fish, eats the stock: FISH TOSS, BEAK SCOOP). Up the gangway, the hangar deck (old planes, roped off); up the elevator, the flight deck at sunset.
  - **Flight Deck**, an old jet that's never landed on a carrier and always wanted to (its own song, "flight_deck", jet-engine rock; a new carrier backdrop: the deck running to the horizon, the sea, the island tower). **A two-part fight:** first it shows off (JET WASH, AFTERBURNER, CATAPULT LAUNCH, BARREL ROLL, FLARES); from the fourth turn (or half its HP) it's low on fuel and keeps trying to land (LANDING APPROACH, the runway lights closing in). **Spare it by guiding it in**: "Guide It In" only works right after its landing approach (an ACT's `when`, `Enemy.last_pattern`); Signal and Clear the Deck help a little. Spared, it catches the wire: its first carrier landing. Killed, it skids off the end of the deck.
  - **Corps:** Agent and Eggo are on the pier (Eggo: "That's a plane-ly strange situation"), Hop came too (he's on probation). **Agent calls every dodge** from the tower (the announcer). Then everything changes:
    - **The feeding.** Agent has tracked Hop since the beach: every broken fragment, Hop gets worse. Hopkuna's power doesn't die; it drifts home. "We haven't been destroying him. We've been feeding him." He calls a vote.
    - **Hop's confession**, on the flight deck at night: Relic, the curly fries, the summer, the tent for three, the fire, his hands, twelve pieces. "I killed the last one who had it." "I didn't want you to be a replacement. I wanted you to be you."
    - **The vote**, in the hangar, all twelve of them in a circle under the old planes. Agent, Supreme, Rooster and Sansworth start at SEAL; Eggo, Crayola, N.C., Nat and MuffinMage at KEEP; Big Joe, Nassan and Ronin are torn, and Elric can win each one (justice is for what you DO; step two is together; Hop didn't choose the fire either). With BOND level 4+, Supreme adjusts for the outlier. Then Elric's own vote. (Flags hb_vote, hb_votes_keep.)
    - **However it falls, Hop leaves that night.** At the base, the couch is empty and the blanket is folded: "Don't carry me. You've got enough. - H" (KEPT). Hop can't be the partner after this (`Game.hop_left()`).
  - **Own way:** Agent is at the gangway: a Rock Paper Scissors rematch, five throws, for who goes up first (you go up either way: he wants the data). Hop is on a bench, on probation: "I miss you, man." After this, **the Corps' hatch is locked**: "The offer stood. It doesn't anymore." (Nassan's note.)
  - **With Hop:** Agent is on the flight deck. **The hardest fight in the game**: he reads where the SOUL is going (from how it's been moving) and throws there. PREDICTION, COUNTER (a slash where you're heading), ROCK PAPER SCISSORS (rock where you'll go, paper on the side you favor, scissors closing on you), DART VOLLEY, BULLSEYE (rings closing on where you're going), CHECKMATE (walls from every side but the one you'd run to), ZUGZWANG (pieces that move when you do). Finale: THE VARIABLE (he's panicking: nothing follows a rule). "I ran it a thousand times. You never did this in any of them. ...That's the one variable I'd change." His bullseye dart is KEPT. Relic: "Six."
  - The 8th keepsake memory: the same flight deck at sunset, five years ago. "Hop. If you ever want him gone... I could try." "...No. What if he's the only interesting thing about me?" "You'd be Hop. That's plenty." "Not yet. Ask me again someday."

**Torrey Pines (fragment 9, built, all paths)** (`scripts/scenes/torrey_pines.gd`, `scripts/torrey_battles.gd`, `scripts/torrey_attacks.gd`): by bus once fragment 8 is found. Its own song ("torrey", airy, in D with the bright raised fourth). Cliffs over the ocean (sandstone, the beach far below), the rarest pines in the world bent by the wind (one of them, Doris, is four hundred years old), a lodge (NO GLIDERS LANDING HERE, crossed out), a gliderport with a windsock, a viewpoint with a bench. Three new townsfolk: the **Park Ranger** (a tortoise, ninety years on the job: RULE SIGNS, SLOW AND STEADY), the **Hiker** (a mountain goat: ROCKSLIDE, TRAIL MIX) and the **Birdwatcher** (an owl waiting six years for a falcon: BINOCULARS, THE FIELD GUIDE).
  - **The Glider**, a hang glider with nobody in the harness, hanging over the edge for five years (its own song, "glider", a soaring waltz; a new cliffs backdrop). **The fight is in the open sky: the box drifts on the wind** (`BattleData.box_drift`). UPDRAFT, THERMAL, CROSSWIND, GULL ESCORT, DIVE, PINECONES; from the fifth turn, when the wind dies, THE GROUND (it's coming down, terrified, with one landing strip). Spare it by convincing it that coming down isn't giving up (Talk It Down, Coming Down); with the Corps, **Rooster admits he's scared of heights** (a "once" ACT: "Coming down is the bravest thing I do. Every single time."); going your own way, Elric admits they're scared too. Spared, it lands on the grass, skids a little, and it's okay.
  - **Corps:** Hop left the base after the vote. He's at the viewpoint. "I left so you wouldn't have to carry me." "You don't get to decide that." After the fragment and the memory, **Hopkuna takes him over**, stronger than he's ever been ("You've been breaking my things. Thank you."): a fight you can't win, only survive (4 turns, the whole team). Every fragment tears out of Elric's pockets and flies to him, and he steps off the cliff and flies north. Rooster: "He took HOP. ...No joke. I don't have one."
  - **Own way:** Relic's voice, gentle for the first time: "You keep walking away from people. I did that too." Hop is at the viewpoint, and tells Elric everything (Relic, the summer, the fire, twelve pieces): "You walk just like them. ...I wish you'd come with us." Rooster is at the gliderport, "supervising."
  - **With Hop:** Rooster is at the edge of the cliff (he hates cliffs; he's there anyway). He roasts you the whole fight (THE ROAST, TOP HAT TRICK, MIC DROP, SPLIT DOWN THE MIDDLE, HECKLE, CALLBACK, TONGUE OUT); past half his HP the jokes fall apart (`Enemy.finale_taunts`: "...okay that one wasn't good." "Say something. Please.") and NOT A JOKE: just his hat, falling. "You were my favorite person to roast. You always roasted back." (It isn't a joke.) His top hat is KEPT. Relic: "Seven."
  - The 9th keepsake memory: the same cliff at dawn, five years ago. Relic, packed to leave town like every town before. They stand at the edge a long time, then take everything out of the backpack and set it in the grass. "First place I ever wanted to stay." Far up the trail, Hop is yelling their name with his mouth full.
  - **Every Corps boss's HP now grows with Elric's LV** (`CorpsAttacks.boss_hp`), so they stay real fights however strong Elric gets.

**The burned hills (fragment 10, built, all paths)** (`scripts/scenes/burned_hills.gd`, `scripts/hills_battles.gd`, `scripts/hills_attacks.gd`): by bus once fragment 9 is found. The hills behind Westview Field, where the fire went: black stumps, ash drifting, a fire road switchbacking up, a lookout over the field (the crater, perfectly round, "like something left"), and saplings, each with a name tag (one says RELIC, very small). Its own song ("burned_hills", sparse, E minor). One townsperson: the **Firefighter** (a dalmatian who was on the line that night and plants a tree every weekend: HOSE, AXE).
  - **Ember**, the fire's leftover heart, at the top in a ring of burned stumps (its own song, "ember"). **Hitting it feeds it** (`Enemy.feeds_on_hits`: the damage heals it, "+X" in orange, and costs mercy). **Spare it by letting it burn out**: every turn it isn't hit, it burns lower (`Enemy.burnout_mercy`); Hold Still and Smother help; and **Ronin, who has fire in him too, learns to hold his flame still instead of throwing it** (a "once" ACT, Corps and own way). WILDFIRE, SPARK BURST, SMOKE (with a coal hiding in it), FIRESTORM, HEAT SHIMMER, THE TENT (a tent made of fire, room for three), ASH; from the seventh turn, BURNING OUT. It goes out gently, like it was tired.
  - **Corps:** Ronin is at the top. Afterwards: "We're not breaking this one. Not ever again. We know now." Then Hopkuna's trail: burned grass, north, through the junkyard.
  - **Own way:** the Corps got here first and Ember beat them; Ronin stays, in case, and helps anyway.
  - **With Hop:** Ember doesn't fight. It bows into the ash, like a dog that knows whose it is: "It remembers us." Ronin is waiting at the top with his guitar plugged into nothing. He plays his POWER RIFF, the last time, and **the battle music doesn't step aside for it** (it plays Relic's slowed theme, not silence). POWER CHORD, FLAME SOLO, FEEDBACK, PICK SLIDE, STAGE DIVE, ENCORE, RIFF LOOP; finale THE HELD NOTE, which he never finishes. He says nothing at all: the note rings out over the hills after him. His guitar pick is KEPT. Relic: "Eight."
  - The 10th keepsake memory: Westview Field, the last night of the summer. The tent, way too big for two. "Why'd you buy a tent for THREE people?" "Room for three. Whoever shows up. There's always room for one more." "...The voice is quiet tonight." The token is colder than it's ever been.

**The junkyard (no fragment, built, all paths)** (`scripts/scenes/junkyard.gd`, `scripts/junkyard_battles.gd`, `scripts/junkyard_attacks.gd`): by bus once fragment 10 is found. Under the freeway: a chain-link fence, mountains of junk, crushed cars stacked like pancakes (one still has fuzzy dice), an office shack (WE ARE JUNK - MGMT), and in the back corner, a van under a tarp. Its own song ("junkyard", clanky funk). The **Junk Dealer** (a raccoon; a kid in a fedora once fought him for a taco and won, and he sold that kid's friend a bottle cap: SHINY THINGS, DUMPSTER DIVE).
  - **Scrap Heap**, a crane with a car crusher for a body and a magnet for a hand (its own song, "scrap_heap"): CAR FLING, THE CRUSHER (closing to one row, then one column), MAGNET, TIRES, HUBCAPS, SPRINGS; overheating from the sixth turn, THE COMPACTOR. Spare it by calming it down: Kick the Tires, Sort the Junk, and with the Corps, **Sansworth tries his 31 keys on it** (key 30 fits; he has no idea why); going your own way, oil its gears.
  - **Corps:** Hopkuna's trail runs straight through. After Scrap Heap, **Sansworth finds his van**: a note under the wiper, "FOR MY NEPHEW. HE'LL KNOW WHICH KEY. - UNCLE S." Key thirty-one starts it. "I TOLD you I had a car!" Then **Nassan admits it**: one of the twelve circles was always on Hop's house; he knew from the first week and couldn't plan around his friend lying to him. "EVERYBODY IN THE VAN."
  - **Own way:** Elric ducks behind the hubcaps as the Corps walks in, and watches Sansworth find the van, and everyone cheer. Nobody looks behind the hubcaps. Relic: "You could still go over there." You don't.
  - **With Hop:** Sansworth is sitting on the van's bumper, smiling. "I'm gonna drive everybody somewhere safe! Where's everybody?" HONK, KEY RING, REV, HIGH BEAMS, WRONG TURN, PARALLEL PARKING, TRAFFIC; finale VROOM (the van sputters; it never starts). "...Vroom?" One of his keys is KEPT (the thirty-first: it would have started the van).
  - **Relic counts the Corps as they go** (`Game.corps_dead_count`), however the order falls.

**The end (built, all paths)**
  - **With Hop, the last of the Corps** (`scripts/endgame_battles.gd`, `scripts/endgame_attacks.gd`). Down the hatch, the bunker is quiet, every door open, every room empty, the beds made (`corps_base.gd`, hunt mode). **Eggo** is on the couch: he uses the same attacks as the day you met (yolk, straw, the bullseye, eggs, bunnies) plus HARD BOILED, TOAST and SUNNY SIDE UP, and only FIGHT works; past 60% he stops defending himself at all (JUST TALK, a finale that's for good). "...you could also just talk to us. Welp. Guess I'm... over easy." Nobody laughs. Toast hops away. (Cat-ear beanie, KEPT.) **MuffinMage** is at the stove, back turned, salmon burger in hand, face never shown: MUFFIN RAIN, THE GRILL, SPATULA FLIP, SALMON LEAP, SPRINKLES, OVEN TIMER, MAGIC MISSILE; finale THE WARNING. "I warned you about the fragment. Should've warned you about yourself." (The extra salmon burger, FOR ELRIC, KEPT; it never goes bad.) **Nassan** is at the only open register at Vons (`pq_mall.gd`), the last of them: STEP ONE, RED STRING, FIVE PAGES, CIRCLE THE MAP, CONTINGENCY (where you'd dodge TO), PUSH PINS, PRICE CHECK; at half HP he stops and holds out his note, five pages, and waits. "I told you not to carry it alone." (His name tag, KEPT.) Then Hop: "Come home with me. I kept it for you." The map in the bunker now has a thirteenth circle, small, in the corner: ELRIC.
  - **Hop's house: fragment 11** (`hop_house.gd`; by bus to Hop's Street after the junkyard). The jar of bottle caps labeled KEEP, in Relic's handwriting. Hop found the eleventh fragment in the ash at dawn, five years ago, and never broke it or told anyone. (With Hop, he gives it to Elric himself.) **The 11th keepsake memory is the fire:** the tent burning, Hop laughing with someone else's laugh, Relic grabbing him with both arms: "Hop. Let go." Hop lets go; all of Hopkuna pours into Relic; they start to come apart. Then the windows go red: Hopkuna takes the fragment and flies north (with Hop, he tears it out of Hop's own hand, terrified: "Let him run. We know where he's going."). The Corps' van: "EVERYBODY IN THE VAN." Going your own way, it goes past without you; you follow on foot, all night.
  - **Sabre Springs** (`sabre_springs.gd`): the park up the road from Mt. Carmel High, at night. Hopkuna absorbs the last fragment, and **the last keepsake floods out into Elric** (the screen washes green-white): Relic breaking, their blood on the last piece, their wish for a home, too big for a bottle cap, made into a keepsake that could walk; at dawn, in this park, someone with purple skin opens their eyes. Relic's voice: "It's me. Relic. I made you. I'm sorry I made you lonely."
    - **Corps:** all twelve step out of the van and form the circle. Agent: "Thirteen of us. One of you." **Hopkuna, Unbound** (`hopkuna_unbound`): everything from the whole game (and TWELVE TATTOOS); you can't hurt him. Talk to Hop works a little more each time, and **every friend you call adds their voice** (`Enemy.mercy_per_call`). **The first time Elric would fall, they hang on at 1 HP and BOND appears: Bound by Our New Determination** (`BattleData.bond_reveal`): everyone is healed and Hop gets much closer. MERCY is "Hop. Let go." The token holds Hopkuna ("...It's dark in here." "Yeah. I know. I'll talk to you sometimes."). Ending: **HOME**.
    - **Own way:** Elric learns what they are alone. Hopkuna and the Corps both ask for the fragments: walk away (**THE ROAD**), give them to the Corps (**THE GIFT**: Hop carries Hopkuna alone), or give them to Hopkuna (**THE BARGAIN**: the city burns).
    - **With Hop:** Relic: "A home. Ha. We don't need a home." Relic turns on Hopkuna, who fights for his life (`hopkuna_underdog`: the underdog now, his tattoos burning green one by one; finale LAST STAND). Then Hop: "Relic. Please. Let go." At 75 kills, Relic keeps him: **ONE** (the token goes dark, the Santa Ana wind, the city burning, "There were two, when there were meant to be three. Now there is one.", and a pair of green eyes). Under 75, Elric is still in there and can let go: **LET GO** (harsh and quiet: nothing is fixed, but Hop isn't in a token, and he doesn't walk away).
  - **The ending screen** (`scenes/ending.tscn`): a few pages of text at a time, a title card (HOME ends with a small purple light that doesn't move), and on the Corps and own-way endings, where everyone is now (the Pigeon Man's line if you gave the feather back).
  - **The keepsakes come home** (Corps, after Torrey Pines, at the PQ Mall): people are crying on benches, in the lot, in line at Jack in the Box. Five years of the pain Relic carried is coming back to them. The Corps sits with them: Crayola with the Pigeon Man (pick a card: the Seven of Hearts), Big Joe on patrol with the Mall Cop, MuffinMage feeding the Busy Mom, Supreme next to the Teen while they text an old friend back. (If the feather already went back, the Pigeon Man is smiling through it.)
  - (The stage-4 dread heart could bend so far it couldn't be drawn; now it eases off for that frame.)

## 8. Build order — Chapter 1

Build the game in **milestones**. Each one ends with something playable, so progress is always visible.

### Milestone 1 — The tutorial fight (battle system)
Use the Eggo & Big Joe fight as the target: when it plays start to finish, the battle system works.
- [x] Battle box and SOUL movement
- [x] Enemy attacks (bullets) and taking damage / HP
- [x] Battle menu: **FIGHT · ACT · ITEM · MERCY** (+ DEFEND)
- [x] FIGHT timing bar
- [x] ACT options and CHECK
- [x] Sparing (names turn yellow) → **BOND**; defeating → **LOVE** (EXP)
- [x] Party turns (Elric + Hop)
- [x] The full tutorial fight, scripted turn by turn
- [x] Pixel-art battle sprites for Eggo, Big Joe, Elric and Hop (`art/sprites/`, drawn by `tools/make_sprites.ps1`)
- [x] Sound effects (generated in code by `scripts/sfx.gd`)
- [ ] Pixel font *(needs a download — waiting for approval)*
- [x] Music: 7 original chiptune tracks (title, Mt. Carmel, PQ Mall, Westview, battle, boss, GAME OVER), composed as note lists in `tools/make_music.gd` and crossfaded between areas
- [x] A proper GAME OVER screen (the SOUL cracks and shatters, "Stay determined...")

### Milestone 2 — Talking
- [x] Dialogue box with letter-by-letter text and voice beeps (each speaker has their own pitch and name tag)
- [x] Character portraits (head-and-shoulders from each sprite)
- [x] Facial expressions in portraits: happy, angry, sad, shocked, smug (`art/portraits/`, made by `tools/make_sprites.ps1`). MuffinMage and Supreme use their normal face (their masks cover it).
- [x] Dialogue choices (Yes / No, Save / Return)

### Milestone 3 — Walking around
- [x] Elric's overworld movement and animation (front/back sprites, walking bounce)
- [x] Walls / collision and the camera
- [x] Talking to characters and inspecting objects
- [x] Followers (Hop walks behind Elric)
- [x] Side-view walking sprites with a 2-frame walk (Elric, Hop, Eggo, Big Joe)
- [x] Moving between areas (Mt. Carmel ↔ PQ Mall)

### Milestone 4 — The opening (first playable demo)
- [x] Title screen: **REVOLUTION** rearranges into **LOVE TO RUIN**
- [x] Opening narration
- [x] Mt. Carmel High School area (school, parking lot, courtyard, field, road)
- [x] Meeting Hop
- [x] Finding fragment 1
- [x] Tutorial fight outside Mt. Carmel, with different reactions for sparing / fighting
- [x] **SAVE points** and save/load (Continue on the title screen)
- [x] "To be continued" screen when leaving toward the PQ Mall

### Milestone 5 — The PQ Mall hub
- [x] Shops and items (money, 8-item bag)
- [x] NPCs and cast members to talk to (9 cast members with sprites, portraits and dialogue)
- [x] Nat's lore and Nassan pointing the way to Westview
- [ ] Party selection (Elric + 2 of the cast) — *needs decisions: see Open questions*

### Overworld features (from feedback)
- [x] **Bag** (B only, anywhere outside battle): party HP, LV, money, BOND, fragments; items can be USED, CHECKED (description) or DROPPED
- [x] **Storage boxes** next to each SAVE point; every box shares the same storage (12 slots), saved with the game
- [x] **Random encounters** in hostile areas (Westview's hallway and classroom), with a "!" over Elric
- [x] Wandering enemies you walk into are gone for good after the fight
- [x] **Objectives**: a "NEW OBJECTIVE" banner at each story beat; the current one is shown in the bag
- [x] Eggo and Big Joe get picked up by a car after the tutorial fight
- [x] SAVE stars twinkle between two frames, like in Undertale
- [x] Looking at scenery: trees ("It's a tree."), benches, walls, windows, lockers, desks, chalkboards...
- [x] Mt. Carmel's front doors lock the moment Elric touches them
- [x] **Hidden-in-plain-sight puzzles:** nothing says "PUZZLE", but something clearly blocks the way
  - Mt. Carmel: the field gate is chained shut. Hop mentions the coach loses his keys ("...the week before, a tree"). One courtyard tree glints: shake it for the keys.
  - PQ Mall: Rock Paper Scissors, where you read each opponent's tell.
  - Westview: the endless hallway (humming locker) and the bell order (chalkboard).
  - Westview Field: the field's sprinklers push you back. A control box by the benches has four switches labeled NW, NE, SW, SE: turn off the corner you want to walk through.
- [x] **Sprinting:** hold Shift to run (1.75x speed) with running sprites (side view: a leaning stride and a knee-up frame; front/back: bigger steps and pumping arms). A stamina bar slides in at the bottom right, drains over about 2.6 seconds and refills after you stop. Run it dry and Elric is WINDED until it's about a third full. Hop runs to keep up.
- [x] SAVE stars glow yellow and light up the ground around them. FRAGMENTS glow deep red, and the music fades to an eerie drone whenever you get near one (anywhere, any time).
- [x] PQ Mall: once the sky turns orange, Vons and Knotty Barrel hang CLOSED signs (Jack in the Box stays open late). Streetlights glow orange in the evening and brighter at night, and the music softens at night ("Mall at Night").
- [x] Westview has school decorations outside: the name over the doors, pennants, a marquee and a flagpole. The bell puzzle remembers your progress through random encounters.
- [x] The opening's first picture shows Elric from behind, walking down the road toward the sunset.
- [x] Names shown in game: "Big Joe" and "N.C. Wethan". N.C. Wethan wears a black hard hat with a yellow brim and stripe (like Roblox's Outrageous Builders Club hat). Mt. Carmel's MC is centered on the field, and the tree hiding Coach's keys has a small glint.
- [x] Music: an overly ambitious, epic theme for Rock Paper Scissors; Wally's fight song is now a faster, more serious chase theme.
- [x] **Status effects:** shown as little colored tags with the turns left (under an enemy, or under a party member's HP), counting down at the end of every enemy turn. Enemies: STRAVANT (from N.C. Wethan). The party, from enemy hits (a chance per hit): STICKY (SOUL 30% slower; Eggo, Wally), SHAKEN (FIGHT does 30% less; Big Joe, Overdue Book), DIZZY (the FIGHT bar moves faster; Pop Quiz, Hall Pass, Tardy Bell), QUEASY (food heals half; Mystery Meat), BURN (lose 2 HP each enemy turn, never below 1; Hopkuna). They don't carry over between battles.
- [x] **Encyclopedia** (in the bag): every enemy in the game down the left ("???" until you've met them), and a page for each one you've met: picture, HP/ATK/DEF, description, attacks, what status effect it can cause (with its chance and turns), and its ACTs. Ones you haven't met say "Haven't seen yet."
- [x] **Elric picks what to say:** whenever Elric speaks, the line they're answering stays up with two options under it ("You're working for Hopkuna, aren't you?" → "Who?" / "...I'm not."). Both lead on to the same next line.
- [x] **Gear is one of a kind:** weapons and things to wear in shops can only be bought once; then they show SOLD OUT.
- [x] **The team screen** (TEAM in the bag, once Hop has joined): a card for each member with their picture, HP, ATK and DEF, and what's in each slot (Weapon, Torso, Shoes). A/D picks a member, W/S a slot, ENTER takes that item off (it goes back in the bag). At the base, "Change partner" is there too. Picking who wears something from the bag uses A/D (the names are side by side).
- [x] Rock Paper Scissors: N.C. Wethan's and Ronin's throws are random every game (their tells still give them away). Agent still plays the odds against your throws.
- [x] Random encounters come more often (every 550 to 1000 pixels walked).
- [x] Wally's fight: a scoreboard flashing "WALLY! WALLY!" on the beat with chasing bulbs, colored light pools sweeping the floor, crisscrossing lasers, fireworks on the beat, camera flashes and pom-poms in the crowd, and multicolored spotlights.
- [x] The crater's shockwave: right after the beam hits Hop, a ring of force tears out of the crater and burns the field and grass to scorched earth, the trees to stumps, and wrecks the sprinklers. The damage stays for the rest of the game.
- [x] The opening tells you WASD works too, and that holding Shift sprints.

### Battle polish (from feedback)

- **The Corps are bosses** (`scripts/corps_attacks.gd`). Every Corps fight (Crayola, N.C. Wethan, Big Joe's duel and his last stand, Nat) is a real boss: 170 to 230 HP, at least seven attacks each, and a finale they only use when they're nearly beaten (under a third of their HP, announced the first time: `Enemy.finale_patterns`, `finale_line`). They speed up as the fight goes on.
  - **Crayola:** COME BACK (his cards spell it, and one is always flicked at you), CARD FAN, RIFFLE SHUFFLE (rows from both sides, interleaving), PICK A CARD (your card hunts you), 52 PICKUP (the whole deck, every direction, one gap), VANISHING ACT (a ring of cards closing in), UNDERTOW (he swims: waves along the bottom, and the riptide along the top). Finale: SEVEN OF HEARTS ("...Pick one. PLEASE.").
  - **N.C. Wethan:** his lightning hits everything around you, and every attack leaves a way out: he isn't aiming at you, he never was. NEAR MISS, CHECKERBOARD (strikes every black square, then every red one), KING ME (a hopping checker), CHAIN LIGHTNING (bolts closing in on you, the last one just missing), STORM FRONT, LIVE WIRE (current running laps around the box), DOUBLE JUMP. Finale: THE LOUDEST MAN YOU EVER MET (rings of thunder, each with one quiet gap).
  - **Big Joe** (by the rules: every attack is announced with a warning): LANCE, SHIELD WALL, JUSTICE STRIKE, JOUST, SHIELD PRESS (walls closing from the top and bottom), THE RULEBOOK (lances falling like dominoes), SALUTE (his sword swings like a pendulum while stars come in), HELMET BASH. Finale: JUSTICE FOR ALL (stars from all four sides). His duel (own way) plays his and Eggo's theme.
  - **Nat** (he reads ahead): CHAPTER BREAK, DOG EAR, FOOTNOTES, SPOILER (a ribbon where you are, then where you're about to go), PAGE TURN, CROSS-REFERENCE, HISTORY REPEATS (the same book, three times). Finale: THE LAST PAGE ("I know how this ends. I'm skipping to it.").
- [x] Several attacks per enemy, a different one each turn (Eggo: rain, egg drop, bunny hop · Big Joe: lance, sweeping wall, aimed stars)
- [x] "Ready?" check after choosing, with X to go back and change anything
- [x] On-screen control hints in menus
- [x] ENTER is the only confirm key (Z removed)
- [x] Button icons: FIGHT (sword), ACT (megaphone), ITEM (bag), MERCY (white flag), DEFEND (shield)
- [x] Clear turn indicator: an arrow, "NAME'S TURN", a glow under whoever is choosing; teammates dim
- [x] FIGHT: a "READY..." wind-up before the timing bar moves, colored zones (green = CRITICAL), a slash animation, white hit flash, bouncing damage numbers and draining HP bars
- [x] Bigger HP bars
- [x] Hop attacks differently from Elric: three fast punches with red shockwaves and a red X (a hint of Hopkuna)
- [x] **Flee**: MERCY opens Spare / Flee. Fleeing turns Elric and Hop around and they walk off the left side of the screen, then you're back in the overworld where the fight started. (Not allowed in boss, story or scripted fights.)
- [x] The title screen: centered, with a red glow, twelve red fragments circling the title, rising embers and a glowing crack under "LOVE TO RUIN"
- [x] People walking around stop when you talk to them
- [x] **Levels:** LV (from EXP) and BOND level (from BOND) both raise max HP and attack for the whole party (LV: +3 HP +2 ATK; BOND: +4 HP +1 ATK). The bag shows progress to the next of each, and each member's ATK and DEF. Battle shows LV next to party names (not enemies). Level-ups are announced after a fight.
- [x] **Accessories:** four slots per member (Weapon, Torso, Shoes, Card), one item each. Only accessories raise defense. EQUIP them from the bag (whatever was worn goes back in). Vons sells a Nail File (ATK +2), Rain Poncho (DEF +2) and Flip-Flops (DEF +1); Games & Cards sells cards with powers (see Shops); Cleats (ATK +1 DEF +1) are hidden under the Mt. Carmel bleachers; Wally's Foam Finger (ATK +3) is in his empty costume.
- [x] Title screen: with a save, Continue / Reset / Settings (Reset asks first, then erases the save); without one, Begin / Settings. More particles: glints, shooting shards, sparks off the crack.
- [x] The opening narration has Undertale-style sepia pictures: Elric on an endless road at sunset, at a bus stop in the rain, on a cliff over the ocean; the whispering city; a humming fragment; a shadow with red eyes.
- [x] Side-view walking swings the arms.
- [x] Each kind of battle has its own animated background, with several layers each: a turning star over drifting diamonds (tutorial); a graph-paper floor with falling pencils and red marks (Pop Quiz); rushing lockers and a spinning clock (Hall Pass); a cafeteria with flickering lights, floating trays and a bubbling vat of stew (Mystery Meat); a swinging bell with sound rings and notes (Tardy Bell); a starfield with flapping books (Overdue Book); spotlights, confetti and a cheering crowd (Wally); a red heartbeat with falling shards (Hopkuna); TV static (the tent).
- [x] When Eggo or Big Joe is knocked out, the other reacts (Eggo goes quiet and sad; Big Joe gets furious and hits harder).
- [x] "HOLD IT!" opens with a stinger; Revolution's theme starts as they walk in. Car engine and brake sounds. A sharp "!" sound for random encounters.
- [x] Shading: every sprite is shaded (lit from the top-left), arms and legs have space between them, characters and objects cast soft shadows, walls and trees shade the ground, and the screen edges have a soft vignette
- [x] Smoother walking: a four-step cycle (step, stand, other step, stand) with legs lifting and arms swinging, for everyone
- [x] WASD works as well as the arrow keys
- [x] A hidden quarter-second pause after each ENTER in text, so it can't be mashed through
- [x] Mt. Carmel: a big yellow MC outlined in red at midfield, and a HOME OF THE SUNDEVILS banner. Westview: a big black W outlined in white and gold at center court, and a HOME OF THE WOLVERINES banner
- [x] Battle poses (sprites) for Elric and Hop: windup, strike, guard, arm raised, hurt and knocked out. Elric draws back their arm (nails glinting) then dashes in claws-first with afterimages; Hop crouches and charges a punch (energy gathering at his fist) then rockets in. Enemies each wind up and throw their own way (Eggo bounces, Big Joe lunges, papers flutter, the bell swings, Mystery Meat jiggles, Hopkuna swells). Eggo and Big Joe flash a shocked face when hit. Everyone has a KO: party members topple over with stars circling; enemies shudder, fall over and kick up dust. The FIGHT bar can come from either side.
- [x] **Impact frames:** when a blow lands, everything freezes for an instant (hit-stop) and the screen flashes white with the enemy as a black silhouette and speed lines bursting from the hit, manga-style. A CRITICAL flips to an inverted frame too (black screen, white silhouette, red lines). Hop's quick punches each get a tiny freeze.
- [x] **Hit sounds** depend on the attack: Elric's claws slice (shhk), Hop's punch thuds, the Nail File rings (ting), the Foam Finger squeaks and BONKs. Taking damage always makes the same sound.
- [x] **Weapon attacks:** the Nail File attacks with a flurry of silver jabs and sparks; the Foam Finger swings down and BONKS the enemy flat, with stars circling their head. Without a weapon, Elric slashes with claws and Hop punches.
- [x] Battle animations: everyone breathes and bobs; FIGHT winds up then leaps at the enemy; ACT hops; ITEM squashes with sparkles; MERCY waves; DEFEND crouches behind a shimmering shield; getting hit flashes red and flinches; knocked-out members lie down. Enemies bob gently too.
- [x] Wally's CLAW SWIPE: three glowing claw marks rake right through the SOUL (after dashed scratch warnings), then a second set crosses them from the other side
- [x] Boss health bars across the top of the screen, styled per boss (Wally: gold fur and claw marks; Hopkuna: pulsing red with tattoo zigzags and "??? / ???")
- [x] **Choose who takes the hits:** during the enemy's turn, X switches whose SOUL is in the box (and who loses HP). Elric's SOUL is red. Hop's is **fragmented**: silver shards drifting apart over a pulsing red glow.
- [x] **No safe spots:** every attack aims some of its shots at the SOUL (or puts its gap away from you), so standing still always gets you hit. Checked by a test that runs every attack against a SOUL that never moves.
- [x] New looks for Eggo's and Big Joe's attacks: runny yolk drops with trails; shaded, wobbling eggs that crack as they fall and splatter into yolk; bunnies with floppy ears that hop exactly as high as your SOUL; lances with red-and-gold pennants; a wall of blue kite shields; spinning gold JUSTICE stars trailing light.
- [x] **Nail File:** three thinner bars cross the FIGHT bar one after another, and ENTER stops each one. Every bar deals a third of the damage (by its own accuracy), each jab shows its share, and all three in the green is a CRITICAL.
- [x] **Divergent Glove** (Games & Cards' glass case, $35, Weapon ATK +1): "It wants a hand the FRAGMENTS have already touched." On Hop, every hit has a 1 in 20 chance to be a **BLACK FLASH**: 2.5x damage, a long freeze that flickers between black and red, black and red lightning crashing into the enemy, its own sound, and crackling sparks afterward.
- [x] Hopkuna's background: his eyes and a ring of orbs throb on every beat of his music (184 BPM, hardest on the first beat of each bar), and every two bars a black-and-red BLACK FLASH bolt strikes in the background.

### Milestone 6 — Westview High School
- [x] The twisted school dungeon: rooms, puzzles, enemies
- [x] Fragment 2

**As built:** Elric and Hop sneak in after midnight (party is just Elric + Hop for now).
- **Outside** — the school at night, SAVE point, front doors that creak open on their own.
- **The endless hallway** — walking to the far end loops you back to the start; a poster gets more frantic each loop ("NO RUNNING" → "TURN BACK" → "TURN BACK!!" → "YOU'VE BEEN HERE"). Opening the **humming locker** breaks the loop.
- **The classroom** — the chalkboard says to ring the bells **3rd, then 1st, then 2nd**; a wrong bell buzzes and resets. Solving it unlocks the gym.
- **The gym** — SAVE point, then **Wally Wolverine**, Westview's mascot (he/him): an empty costume brought to life by fragment 2. Look: brown furry wolverine, darker markings around yellow-green eyes, tan snout and belly, black nose, fangs, big clawed paws. Attacks: confetti, claw swipe (three diagonal claw marks flash, then slash), claw drop (sets of three claws plunge from the top), red dodgeballs (from the sides and the top, each bouncing to its own height), giant foam finger. ACTs: Cheer ("GO WOLVERINES!"), Look Inside, Paw Five.
- **Random encounters only** (no enemies wandering around), each with its own odds per room (see `westview_battles.gd`). Every enemy has 3+ attacks:
  - **Pop Quiz**: pencils, answer bubbles, scantron columns (one blank bubble is the way through). ACT: Answer, Study.
  - **Hall Pass**: fluttering passes, dashing zoom, tardy slips from the corners. ACT: Sign It, Ask Directions.
  - **Mystery Meat** (cafeteria): gravy blobs that splatter, spinning lunch trays, a spread of peas. ACT: Compliment, Add Salt, Take a Bite (don't).
  - **Tardy Bell** (all sound): rolling sound waves with a gap, SONAR rings that pulse out with a quiet gap to slip through, the CLAPPER swinging across the box like a pendulum, a ring of notes, and the alarm. ACT: Cover Ears, Be On Time.
  - **Overdue Book** (47 years late): fluttering pages, bookmarks aimed at you, a sliding bookshelf with a gap. ACT: Read It, Return It, Shush.
  - **The tent** (very rare, ~1%): a three-person tent. **It's Relic talking** (canon): the "we" is Relic and Hopkuna, the two who ended up in the fragments. The music cuts off. Green text (Relic's color) crawls silently into the box ("We were here, too." "Two of us." "There were two, when there were meant to be three." "We remember."), then everything darkens and **DID YOU THINK WE WOULD FORGET?** appears in green, one word at a time (each word just appears), in silence. Then everything goes black, and after a long, silent black, **two glowing green eyes** appear (Relic's): nothing else, just a pair of tall oval eyes made of chunky green pixels with a blocky glow, close together in the dark. They don't move; they stay there, perfectly still, for six seconds, and then you're put back where you were. The only sound is **wind**: the wind over the field where Relic died, the first sign of how they died. It fades out as the eyes go. (audio/sfx/relic_wind.mp3, kept out of the public repo until its license is confirmed; without it, the game makes its own wind: Sfx.wind.) Earlier, during "Two of us.", two pairs of eyes open in the dark above the text: **green** in front (Relic), with **red** (Hopkuna) behind. They stay open through "We remember." and the scream, until the screen goes black.
- **Wally is a miniboss** with **his own upbeat fight song** ("wally"), a dance in battle (hopping to the beat, swaying, spinning every eighth beat), a gold boss health bar with claw marks, **500 HP**, faster attacks that speed up again below half health, and three extra attacks (rising bleachers, a mascot spin that flings claws in a spiral, and FRENZY: claws and dodgeballs at once). Sparing him is a challenge: four ACTs (Cheer, Look Inside, Paw Five, The Wave) worth a little each, and he gets bored if the same ACT is used twice in a row, even by different party members.
- **Afterwards** — Wally's costume slumps to the floor (it stays there, empty), and fragment 2 floats up out of it and **hangs in the air**. Elric has to walk over to take it. Hop reaches for it, his shadow looks *wrong* for a moment, and he slips: *"Two down, huh?"* Elric asks if he's okay. The emergency exit leads on toward Westview Field.

### Milestone 7 — Westview Field and the climax
- [x] The 3rd fragment erupts → Hop takes the hit → Hopkuna erupts (cutscene)
- [x] The final battle against **Hopkuna** on the big field
- [x] The REVOLUTION Corps arrives
- [x] **The route choice** — end of Chapter 1

**As built:**
- **Westview Field at night** — the big field, the Corps' picnic shelter with a hand-painted REVOLUTION banner, and a map with twelve red circles (two crossed out, a third on this very field). SAVE point. Music: "Westview Field at Night." N.C. Wethan's lightning visibly arcs from him into Hopkuna, then Ronin's fire roars in, then both at once ("TOGETHER!!!"). In the Corps ending, N.C. Wethan's group hug yanks everyone into a huddle and zaps them. After the chapter, Hop can be talked to (different on each route).
- **The eruption** — walking toward the glow, the field goes dark and the buried fragment charges up: red light spirals into the crater, a black-and-red orb swells out of it, and a thin aiming line locks onto Elric. Then it fires a huge beam (black edge, white-hot core, black lightning crawling along it, shockwaves pumping out of the crater). Hop shoves in front of it ("ELRIC, MOVE!!"), takes the blast, begs Elric to get away, and Hopkuna takes over: tattoos, red tint, glowing red eyes. *"...Finally."* He wants the two fragments Elric carries. Elric: *"...No."*
- **Hopkuna (survive, don't win)** — Elric fights **alone**. Hopkuna can't be spared or meaningfully hurt ("It barely leaves a mark."). Survive **5 enemy turns**. Attacks (all aimed at the SOUL, with warnings, 6 damage, faster every turn): **Cleave** (glowing slashes through your position), **Slash Grid** (three slashes crossing where you stand, one after another), **Red Arrows** (volleys of three that curve toward you), **Closing Ring** (shards circle you and collapse inward; one gap), **Flaming Arrow** (a big burning arrow that chases you). A red aura pulses around the box during his turns. ACTs: Talk to Hop, Stand Firm. Music: "Hopkuna."
- **Hopkuna has DETERMINATION too, from the very first line.** The faceless voice at the start of the game knows if you RESET. If you reset before ever reaching him, it stops mid-sentence: "I HAVE seen you. Recently. ...How strange." If you reset after meeting him, it knows exactly what you did ("Back at the very beginning, are we? ...They've all forgotten you already. Not me."), counts your resets, and remembers your answer to "How will you do it?" from last time ("Same answer as last time. Of course it is." / "That's not what you said last time. Changing your story already?").
- **Hopkuna has DETERMINATION too.** Resetting (erasing the save from the title) is remembered outside the save file. After a reset, Hopkuna knows: if you'd already met him, he calls it out ("You RESET. I felt it... Everyone except me."), counts how many times, and adds "Even if you go back and do this all again" when he leaves. If you reset before ever reaching him, he only feels that this has happened before. Without a reset, none of this appears.
- **The Corps arrives** — Big Joe, Eggo, Nassan, Nat, N.C. Wethan, Ronin, Supreme, Crayola, Rooster, Agent, MuffinMage and Sansworth form an even circle around Hopkuna, with a spot for Elric, ("LIGHTNING TIME!!!" / "FIRE TIME!!!"). Elric speaks to Hop ("Come back."). Hopkuna lets go — *"Three fragments, little wanderer. Nine to go. I can wait."* — and Hop collapses, then explains: he only ever let Hopkuna out when there was no other choice. Elric picks up **fragment 3**.
- **The route choice** (with an "Are you sure?" confirm):

| Choice | What happens | Locks |
|---|---|---|
| **Join the REVOLUTION Corps? (Pacifist)** | Elric joins; N.C. Wethan's group hug; "You saved me. We'll save you." The Corps resolves to destroy the fragments. | Genocide, Neutral |
| **Chart your own path? (Neutral)** | Elric walks away alone; the Corps' offer stays open; Hop stays with the Corps. | Genocide |
| **Go with Hop? (Genocide)** | The Corps throws Elric out ("GET OUT."); Elric and Hop walk into the dark. *"Good choice, little wanderer."* | Pacifist, Neutral |

- The game saves the choice, then shows **CHAPTER 1 COMPLETE** with the route, over a slowly turning ring of twelve pieces, one per FRAGMENT. The three found fill in deep red one by one.

### Milestone 8 — Chapter 2 begins: the Corps' bunker
- [x] **CONTINUE** after Chapter 1: the CHAPTER 1 COMPLETE screen now says CONTINUE. On the Pacifist and Neutral routes it goes down into the REVOLUTION Corps' base. On Genocide the hatch is bolted shut ("Somewhere in the dark, Hop is waiting. So is someone else.") and it's back to the title for now.
- [x] **The bunker** (under the shelter at Westview Field), with its own music ("bunker": warm and steady, like the hum of the generators). Dim concrete, pipes, caged lamps.
  - **Main hall:** the ladder down from the hatch, a REVOLUTION banner, the map table (twelve red circles, three crossed out), security monitors, a couch with a checkers game in progress, bunk beds (on Pacifist, one has a sign: "ELRIC", with a backwards E), a kitchen corner ("EGGO'S EGGS. DO NOT TOUCH."), the Corps' emblem on the floor, a SAVE point, a storage box, and Gerald the training dummy to spar with.
  - **Corridor:** a steel door for each member with their name on it in their color. Walk up into a door (or press ENTER at it) to go in.
  - **Twelve rooms**, one per member, each decorated like them, with them inside to talk to:
    MuffinMage's Kitchen (a grill, a fish tank whose fish is named Burger, a SALMON BURGER FRIDAY poster) · Sansworth's Garage (a RESERVED parking spot with no car in it, 31 keys that open nothing, a steering wheel on the wall, a race car bed) · Big Joe's Knight's Quarters (armor, crossed lances, JUSTICE banner) · Eggo's Nest (egg beanbag, fairy lights, Toast the bunny, an EGGS ONLY fridge) · Nassan's Planning Room (a wall of notes and red string) · Nat's Library (the book with the torn last page) · N.C. Wethan's LAB (a sparking tesla coil, KING ME!!! poster, checkers) · Ronin's Studio / Observatory (smoking amp, scorch marks, telescope, the fire extinguisher Nassan made him get) · Supreme's Data Center (seven monitors of graphs, all going up) · Crayola's Art & Cards (crayon scribbles, an easel, a duck pool float) · Rooster's Royal Chamber (half white, half black, a throne and a mirror) · Agent's Strategy room (chalkboard math, every dart in the bullseye, chess).
  - Arriving: on Pacifist, Big Joe and Nassan welcome Elric as a recruit; on Neutral, the offer stood ("Fine. But you're on dish duty."), Hop has been living there, and everyone has a word about Elric coming back.

- **Getting to the base by day:** the base is under the shelter at Westview Field (the park). From the base, the ladder goes up to a hatch in front of the shelter; from the park, the road south leads back into Westview through the gym's emergency exit. In Chapter 2 Westview is just a school again: daytime, school music, no random fights, the spooky things are ordinary (the locker isn't humming; "3, 1, 2" is still on the chalkboard), and it's full of students (eight new student sprites) who are still talking about last night. Each one says something and Elric picks one of two answers.

### Routes during play
- **Genocide (dread):** every real kill counts (someone who shatters). Knockouts don't: the tutorial, the training dummy and the bosses (Wally, Hopkuna) only knock out, and sparing never counts. At 8, 20, 40 and 75 kills, Elric slowly **becomes Relic**. At first, the only sign is **Relic's green eyes.** Halfway: grayer skin, dark circles, darker hair, deep green stains, and a wide smile. Nearly gone: Relic's ash-pale skin and black hair, Elric's clothes going green and stained all over. At the very end: **Relic, in the flesh**: ash-pale skin, black hair, Relic's green hoodie with its hem scorched black from the fire, dark jeans, the curly-fry token on a cord around their neck, green eyes, the same wide smile, and a deep green haze. (All of it is Relic's green, never red: red is Hopkuna's. The smile never shows teeth.) The Genocide route (after the glowbug) starts at least halfway; only the very end of the killing makes Elric into Relic. Every Elric picture changes (overworld, walking, running, battle poses, portraits). The world keeps its colors, but something's wrong: every so often a deep green vignette creeps in around the edges of the screen, pulsing like a heartbeat, more often and stronger at each stage. The music drags a little at the first stages; in Relic's form (and on the Genocide route), every area plays the Genocide song (the fragment music, slowed down, lower, and drowned in reverb), and ordinary fights play **Relic's theme**, slowed and drowned in reverb. Elric's SOUL warps and cracks with green at each stage; at the end it's a twisted, dark green thing.
- **Elric's strike turns into Relic's** (`_relic_power`, `_draw_relic_strike`), little by little with every kill (the square root of kills / 75, so the first kills change it fastest). It starts out as Elric's three claw slashes. With a few kills, the claws go green and a second set swings a beat behind. By about 20, an old circle of runes turns under the target and flares on the hit. By about 40, green motes are pulled in to the target before the blow, and on the hit a pillar of green light erupts through it, with a shockwave and rune-shards thrown outward (and a low hum under the hit). At 75 (Relic, in the flesh) there are no claws left at all: three crescents of ancient light close on the target like a hand, inside a full sigil with a six-pointed star. From halfway, the impact flash and the damage numbers are green. The Genocide route (after the glowbug) starts at least halfway, and the glowbug itself at three quarters.
- **With Hop, from the glowbug on, Hop never fights again.** In every battle (the Corps, the townsfolk, the wild), Elric fights alone, and Hop stands back behind them in the dark, watching. The more Elric has killed, the more he shakes, the further back he stands and the darker he gets. Now and then a turn is about him instead ("* Hop is watching you instead of the enemy." "* Hop is looking at the exit."), and he still reacts to every kill.
- **Pacifist (call a friend):** only once Elric has joined the Corps (the Pacifist choice), MERCY has **Call a friend**: pick any Corps member who isn't in the party, and they run in, do their move, and leave. It can't be spammed: after any call, nobody can be called for 3 turns, and each friend can have a longer wait and a limited number of charges per battle (a charge is one use; they refill after the battle). The call list shows who's ready, who's waiting (and for how many turns), and charges left.
  - **Big Joe (tank):** SHIELD WALL. He plants his shield in front of the party: all damage is cut by 80% for the next enemy turn (a golden wall and shield show while it's up). After calling him, 3 more turns on top of the usual 3 before he can come again, and only 2 charges per battle.
  - **Eggo (support):** THE-EGGO BENEDICT. He strolls in with a plate ("order up.") and whoever called him eats it: +13 overheal HP. Overheal is blue: it first fills in any HP that's missing (red still missing stays red), and anything past the max makes the HP bar physically longer, with the numbers showing the max over the new total ("30 / 43"). Hits use up the blue first. It stacks up to 26 and lasts for that battle only. No extra wait; 2 charges per battle.
  - **Nassan (planner):** CONTINGENCY PLAN. He stays beside the party for the next enemy turn, and after every hit the SOUL stays invincible twice as long (2 seconds instead of 1). 4 turns before he can be called again; no charge limit.
  - **Nat (lore):** FOOTNOTE. He wanders in, book over his face ("...I'm reading."), and reads up on an enemy: it gets 15% closer to being spared, and he reads out every enemy's next attack ("Page 212. Eggo's next attack: yolk, raining down."). Those are the attacks they then use. 1 charge per battle; the usual 3-turn wait.
  - **N.C. Wethan (lightning):** STRAVANT'S LIGHTNING. Only when whoever calls him is below half HP. He floats up with glowing blue rune ribbons spiraling around him, then fires a huge beam at an enemy that swells and throbs the whole time, its edges crackling, bright bands racing along it, with a pulsing burst where it hits: real damage, and the enemy is STRAVANT for 3 turns (its attacks move at 60% speed and come less often). 1 charge per battle.
  - **Ronin (music):** POWER RIFF. He runs in, plugs into his amp (a little black combo with a purple cable), and plays his POWER RIFF (an original 8-bit riff written note by note in tools/make_riff.gd: galloping E-minor chugs and power chords on two square waves with a triangle bass and noise drums, a solo that races up the pentatonic, one big held note with vibrato, and a final chord left ringing; about 12 seconds) on his guitar (based on his real one: a black superstrat with a quilted top, white binding, shark-fin inlays and a pointy headstock). The same notes drive his animation (scripts/ronin_riff.gd, written by the same tool), so they can't drift apart: his picking hand strikes on every note and blurs through the solo; his fretting hand stays low on the neck for the chugs and climbs it during the solo; on the held note and the last chord he raises the neck, leans back, lifts his picking hand off and shakes the note with vibrato. While he plays he's in the zone: eyes shut, grinning, bobbing on every note and swaying to it. The battle music steps aside while he plays, and music notes fly out of the guitar and circle the team. Only when the riff is over: everyone gets 5 purple overheal (it stacks with Eggo's blue: the bar shows blue, then purple, and purple is used up first, up to 15) and AMPED for 2 turns (the SOUL moves 30% faster). The usual 3-turn wait; no charge limit.
  - **Supreme (analyst):** THREAT ASSESSMENT. He pulls up spreadsheet #4 on the target: it's ANALYZED for 3 turns, and every FIGHT hit on it ignores its DEF and does 50% more. 2 charges.
  - **Crayola (support):** PICK A CARD. His card trick from the mall: you pick a card (shown over the target, always a Seven), and the suit decides: Hearts heals everyone 12, Spades hits the target, Diamonds is $15, Clubs brings it 20% closer to being spared. 2 charges.
  - **Rooster (roasts):** ROAST. The target is ROASTED for 2 turns, too embarrassed to hit hard (half damage). One time in four it roasts him back, better, and he storms off ("...WHATEVER."), having done nothing.
  - **Agent (strategy):** THREE MOVES AHEAD. He calls the next enemy turn before it happens: it's 40% shorter, and everything in it moves 20% slower. 4 turns between calls.
  - **MuffinMage (cook):** SALMON BURGER FRIDAY. A tiny grill over the party ("It's Friday somewhere."): everyone heals 10, loses their bad effects, and is FED for 3 turns (+4 HP at the end of every enemy turn). 2 charges.
  - **Sansworth (comic relief):** HONK. He runs in going "VROOM" with a car horn and no car. Every enemy is STARTLED and skips its next attack (if nobody can attack, the turn is over in a moment). 1 charge.
- **The team:** Elric always goes, plus one partner, in battle and following around town. In Chapter 1 it's Hop. Once the Corps' base exists, TEAM in the bag picks the partner from Hop and all twelve Corps members, but only at the base (anywhere else it says so). The partner follows Elric everywhere, fights with their own stats, and isn't in their room while they're out. When Hop isn't the partner, he hangs out on the couch in the main hall.
- **Reduce flashing** (Settings): keeps hit-stop and shaking but skips the full-screen impact flash, makes the Black Flash one steady dark frame, holds the jumpscare without strobing cuts or glitch bars, and softens the field's flashes.

### Throughout
- Pixel-art sprites for Elric and the cast (from the [reference images](art/reference/))
- Music and sound effects
- Saving progress to GitHub after every working step

---

## Open questions

- Exactly how much BOND each action gives, and what BOND improves vs. what LV improves.
- When does each character become available to join the party? Hop is with Elric for all of Chapter 1 (the story needs him there for the climax) — so does party selection start in Chapter 1 with Hop locked in, or after the route choice?
- Each cast member's battle abilities (ideas so far: Supreme = super CHECK, Crayola = support cards, N.C. Wethan = lightning, Ronin = fire/guitar magic, Nat = "reading up" to unlock ACTs, Nassan = strategy, Rooster = roasts).
- Where do Chapters 2–4 take place?
- What do Hopkuna's tattoos look like?
- What are each character's personality and battle abilities?
