extends RefCounted
## The REVOLUTION Corps members Elric can CALL into a fight on the Pacifist route
## (MERCY > Call, once per battle). Whoever isn't in the party can be called: they
## run in, do one move, and leave.
##
## Each entry: the name shown, their color, what's said when they arrive, and the
## move's name. The moves are placeholders for now (each one is a single hit in the
## helper's color) until every member's battle ability is decided.
## On a Pacifist run, a helper's hit never knocks an enemy out.

const CORPS := ["BigJoe6", "Eggo", "Nassan", "Nat", "NCWethan", "Ronin", "Supreme", "Crayola", "Rooster", "Agent"]

const HELPERS := {
	"BigJoe6": {"color": Color(1.0, 0.82, 0.25), "line": "Big Joe charges in!", "move": "JUSTICE STRIKE"},
	"Eggo": {"color": Color(1.0, 0.9, 0.35), "line": "Eggo hops in!", "move": "EGG TOSS"},
	"Nassan": {"color": Color(0.45, 0.65, 1.0), "line": "Nassan slides in with a plan!", "move": "CALCULATED HIT"},
	"Nat": {"color": Color(0.45, 0.85, 0.5), "line": "Nat runs in, book open!", "move": "PAGE SLAP"},
	"NCWethan": {"color": Color(0.45, 0.85, 1.0), "line": "N.C. Wethan bursts in! LIGHTNING TIME!!!", "move": "LIGHTNING"},
	"Ronin": {"color": Color(1.0, 0.55, 0.15), "line": "Ronin strolls in, guitar first!", "move": "FIRE CHORD"},
	"Supreme": {"color": Color(0.8, 0.82, 0.9), "line": "Supreme arrives with a spreadsheet!", "move": "STATISTICAL STRIKE"},
	"Crayola": {"color": Color(1.0, 0.55, 0.8), "line": "Crayola shyly steps in!", "move": "CARD FLICK"},
	"Rooster": {"color": Color(1.0, 0.3, 0.3), "line": "Rooster struts in!", "move": "ROAST"},
	"Agent": {"color": Color(0.7, 0.5, 1.0), "line": "Agent walks in, already calculating!", "move": "THE ODDS"},
}
