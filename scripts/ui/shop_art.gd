class_name ShopArt
extends RefCounted
## Little pixel pictures of everything the shops sell, for the shelves, menu
## boards and display cases behind the shopkeepers (see shop_menu.gd). Each is a
## text map, a letter per pixel, like tools/make_sprites.ps1; "." is see-through.

const PALETTE := {
	"K": Color8(30, 22, 24),     # outline
	"W": Color8(245, 245, 245),  # white
	"Y": Color8(245, 205, 70),   # yellow
	"O": Color8(230, 140, 40),   # orange / golden fried
	"L": Color8(205, 150, 85),   # bun / bread
	"B": Color8(140, 85, 45),    # brown (nuts, chocolate)
	"b": Color8(95, 55, 30),     # patty
	"T": Color8(225, 190, 120),  # taco shell / tan
	"G": Color8(95, 175, 70),    # green (lettuce, wrapper)
	"R": Color8(210, 50, 45),    # red
	"P": Color8(245, 150, 175),  # pink
	"F": Color8(245, 135, 105),  # salmon
	"N": Color8(245, 235, 205),  # cream
	"C": Color8(95, 155, 230),   # blue
	"S": Color8(190, 195, 205),  # silver
	"M": Color8(150, 90, 195),   # purple
	"D": Color8(55, 55, 64),     # dark gray (the glove)
}

const ICONS := {
	"Two Tacos": [
		"...KKKKKK...",
		".KKGRGGRGKK.",
		"KGRGGGGRGGGK",
		"KTTTTTTTTTTK",
		"KTTBTTTTBTTK",
		".KTTTTTTTTK.",
		"..KKTTTTKK..",
		"....KKKK....",
	],
	"Egg Rolls": [
		"..KKKKKKK...",
		".KOYOYOYOK..",
		".KYOYOYOYK..",
		"..KKKKKKKKK.",
		"...KOYOYOYOK",
		"...KYOYOYOYK",
		"....KKKKKKK.",
	],
	"Curly Fries": [
		"..Y...YY..Y.",
		".YOY.YOOY.YO",
		"..YOYO..YOY.",
		".KRRRRRRRRK.",
		".KRRRRRRRRK.",
		".KRRWWWWRRK.",
		".KRRRRRRRRK.",
		"..KRRRRRRK..",
		"..KKKKKKKK..",
	],
	"Burger": [
		"...KKKKKK...",
		".KKLLLLLLKK.",
		"KLLNLLLNLLLK",
		"KLLLLLLLLLLK",
		"KGGGGGGGGGGK",
		"KYYYYYYYYYYK",
		"KbbbbbbbbbbK",
		"KLLLLLLLLLLK",
		".KKKKKKKKKK.",
	],
	"Shake": [
		"......K.....",
		".....K......",
		"...KKKKKK...",
		"..KWWWWWWK..",
		"..KPPPPPPK..",
		"..KPPPPPPK..",
		"...KPPPPK...",
		"...KPPPPK...",
		"....KPPK....",
		"....KKKK....",
	],
	"Trail Mix": [
		"..KKKKKKKK..",
		".KGGGGGGGGK.",
		".KGNNNNNNGK.",
		".KGNBTBYNGK.",
		".KGNTBYBNGK.",
		".KGNNNNNNGK.",
		".KGGGGGGGGK.",
		".KKKKKKKKKK.",
	],
	"Soda": [
		"..KKKKKK..",
		"..KSSSSK..",
		".KRRRRRRK.",
		".KRWWWWRK.",
		".KRRRRRRK.",
		".KRRWWRRK.",
		".KRRRRRRK.",
		"..KSSSSK..",
		"..KKKKKK..",
	],
	"Granola Bar": [
		"KKKKKKKKKKKK",
		"KYOOOOOOOOYK",
		"KYOLLBLLBOYK",
		"KYOOOOOOOOYK",
		"KKKKKKKKKKKK",
	],
	"Deli Sandwich": [
		"K.........",
		"KK........",
		"KLK.......",
		"KLGK......",
		"KLRFK.....",
		"KLGNNK....",
		"KLFFRRK...",
		"KLLLLLLK..",
		"KKKKKKKKK.",
	],
	"Nail File": [
		"........KS",
		".......KSK",
		"......KSK.",
		".....KSK..",
		"....KSK...",
		"...KPK....",
		"..KPK.....",
		".KPK......",
		"KKK.......",
	],
	"Rain Poncho": [
		"....KKKK....",
		"...KCCCCK...",
		"..KCKKKKCK..",
		".KCCCCCCCCK.",
		"KCCCWCCCCCCK",
		"KCCCCCCCWCCK",
		"KCCCCCCCCCCK",
		".KKKKKKKKKK.",
	],
	"Flip-Flops": [
		".KKK...KKK.",
		"KGRGK.KGRGK",
		"KRGRK.KRGRK",
		"KGGGK.KGGGK",
		"KGGGK.KGGGK",
		"KGGGK.KGGGK",
		".KKK...KKK.",
	],
	"Clam Chowder": [
		"..W...W...W.",
		"...W...W....",
		".KKKKKKKKKK.",
		"KNNNTNNNTNNK",
		"KNTNNNNTNNNK",
		".KCCCCCCCCK.",
		"..KCCCCCCK..",
		"...KKKKKK...",
	],
	"Fish & Chips": [
		"......KKKK..",
		"....KKOOOOK.",
		"..KKOOOOOOK.",
		".KOOOOOOOK..",
		"KYKYKYKYKYK.",
		"KKKKKKKKKKKK",
		"KRWRWRWRWRWK",
		".KRWRWRWRWK.",
		"..KKKKKKKK..",
	],
	"Salmon Burger": [
		"...KKKKKK...",
		".KKLLLLLLKK.",
		"KLLNLLLNLLLK",
		"KGGGGGGGGGGK",
		"KFFFFFFFFFFK",
		"KFFFFFFFFFFK",
		"KLLLLLLLLLLK",
		".KKKKKKKKKK.",
	],
	"Card Pack Gum": [
		"KKKKKKKK",
		"KMMMMMMK",
		"KMYYYYMK",
		"KMYPPYMK",
		"KMYYYYMK",
		"KMMMMMMK",
		"KKKKKKKK",
	],
	"Candy Dice": [
		"KKKKKK.....",
		"KPPPPK.....",
		"KPKPPK.....",
		"KPPKPKKKKKK",
		"KKKKKKCCCCK",
		".....KCKCCK",
		".....KCCKCK",
		".....KKKKKK",
	],
	"Lucky Card": [
		"KKKKKKKKK",
		"KWKWWWWWK",
		"KWWWKWWWK",
		"KWWKKKWWK",
		"KWKKKKKWK",
		"KWWWKWWWK",
		"KWWKKKWWK",
		"KWWWWWKWK",
		"KKKKKKKKK",
	],
	"Heart Card": [
		"KKKKKKKKK",
		"KWWWWWWWK",
		"KWRRWRRWK",
		"KRRRRRRRK",
		"KRRRRRRRK",
		"KWRRRRRWK",
		"KWWRRRWWK",
		"KWWWRWWWK",
		"KKKKKKKKK",
	],
	"Clover Card": [
		"KKKKKKKKK",
		"KWWWWWWWK",
		"KWGGWGGWK",
		"KWGGWGGWK",
		"KWWWGWWWK",
		"KWGGWGGWK",
		"KWGGBGGWK",
		"KWWWWBWWK",
		"KKKKKKKKK",
	],
	"Snack Card": [
		"KKKKKKKKK",
		"KCMCMCMCK",
		"KMKKKKKMK",
		"KCLLLLLCK",
		"KMGGGGGMK",
		"KCbbbbbCK",
		"KMLLLLLMK",
		"KCMCMCMCK",
		"KKKKKKKKK",
	],
	"Clock Card": [
		"KKKKKKKKK",
		"KWWWWWWWK",
		"KWWKKKWWK",
		"KWKYKYKWK",
		"KWKYKKKWK",
		"KWKYYYKWK",
		"KWWKKKWWK",
		"KWWWWWWWK",
		"KKKKKKKKK",
	],
	"Divergent Glove": [
		"..K.K.K....",
		".KDKDKDK...",
		".KDKDKDKK..",
		".KDDDDDKDK.",
		".KDRDRDDDK.",
		".KDDRDDDK..",
		".KDRDRDDK..",
		"..KDDDDK...",
		"..KRRRRK...",
		"..KKKKKK...",
	],
}


## Draws a picture with its top-left at `at`, each pixel `scale` big. `dim`
## darkens it (the lights are off in an empty shop).
static func draw(canvas: CanvasItem, icon: String, at: Vector2, scale: float, dim: bool = false) -> void:
	var rows: Array = ICONS.get(icon, [])
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var color: Color = PALETTE.get(row[x], Color.TRANSPARENT)
			if color.a == 0.0:
				continue
			canvas.draw_rect(Rect2(at + Vector2(x, y) * scale, Vector2(scale, scale)), color.darkened(0.55) if dim else color)


## How big a picture is, in its own pixels.
static func size_of(icon: String) -> Vector2:
	var rows: Array = ICONS.get(icon, [])
	if rows.is_empty():
		return Vector2.ZERO
	return Vector2(str(rows[0]).length(), rows.size())


## Draws a picture centered on `center`.
static func draw_centered(canvas: CanvasItem, icon: String, center: Vector2, scale: float, dim: bool = false) -> void:
	draw(canvas, icon, center - size_of(icon) * scale / 2.0, scale, dim)
