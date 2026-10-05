# Draws the battle sprites from text "maps" and saves them as PNGs in art/sprites/.
# Each letter in a map is one pixel; "." is see-through. The palette below says
# which color each letter means. A gray outline is added automatically so dark
# clothes still show up against the black battle background.
#
# Run it from the project folder:  powershell -ExecutionPolicy Bypass -File tools\make_sprites.ps1

Add-Type -AssemblyName System.Drawing

# Case-sensitive, so 'P' and 'p' can be different colors.
$palette = New-Object System.Collections.Hashtable ([StringComparer]::Ordinal)
# Shared
$palette['K'] = @(20, 20, 24)      # black
$palette['D'] = @(60, 60, 66)      # dark gray (shoes, belt)
$palette['W'] = @(240, 240, 245)   # white
$palette['p'] = @(255, 170, 190)   # pink
# Eggo
$palette['Y'] = @(255, 220, 70)    # yellow skin
$palette['H'] = @(215, 165, 25)    # yellow hair
$palette['b'] = @(245, 200, 55)    # yellow beanie
$palette['V'] = @(38, 38, 46)      # black vest
$palette['S'] = @(45, 95, 205)     # blue shirt
$palette['P'] = @(32, 32, 38)      # black pants
$palette['k'] = @(70, 70, 80)      # line between the legs
# BigJoe6
$palette['R'] = @(210, 35, 35)     # red crest
$palette['G'] = @(190, 195, 205)   # silver helmet
$palette['g'] = @(95, 100, 112)    # helmet slits
$palette['C'] = @(42, 42, 50)      # black shirt
$palette['A'] = @(230, 190, 60)    # gold chain
$palette['J'] = @(70, 100, 160)    # blue jeans
$palette['j'] = @(50, 75, 125)     # line between the legs
# Elric
$palette['L'] = @(200, 170, 235)   # pastel purple skin
$palette['h'] = @(110, 72, 42)     # brown hair
$palette['T'] = @(125, 95, 62)     # scruffy brown tunic
$palette['t'] = @(95, 72, 48)      # patches
$palette['d'] = @(80, 68, 50)      # dirt
$palette['r'] = @(175, 145, 95)    # rope belt
$palette['O'] = @(88, 88, 62)      # olive pants
$palette['o'] = @(66, 66, 46)      # line between the legs
# Hop
$palette['N'] = @(165, 165, 172)   # gray head
$palette['s'] = @(72, 72, 80)      # dark gray shirt
$palette['l'] = @(180, 180, 186)   # light gray arms
$palette['B'] = @(120, 140, 165)   # blue-gray pants
$palette['n'] = @(95, 112, 135)    # line between the legs
# Fragment
$palette['F'] = @(150, 20, 45)     # dark red
$palette['f'] = @(235, 70, 95)     # bright red shine
$palette['c'] = @(45, 0, 12)       # black-red core
# SAVE star
$palette['*'] = @(255, 240, 120)   # pale yellow
# Shared skin tone for the mall cast
$palette['Q'] = @(228, 184, 145)   # light skin
# MuffinMage
$palette['M'] = @(225, 85, 40)     # fish mask
$palette['m'] = @(245, 150, 70)    # fish fins
$palette['E'] = @(240, 140, 40)    # orange shirt
# Supreme
$palette['v'] = @(185, 95, 255)    # glowing purple eye
$palette['e'] = @(200, 140, 60)    # burger bun / bear face
$palette['u'] = @(32, 42, 92)      # navy scarf
$palette['1'] = @(80, 175, 70)     # green (lettuce, sneakers)
# Crayola
$palette['a'] = @(150, 150, 155)   # printed lines on the job application
$palette['x'] = @(112, 112, 118)   # worn gray pants
# NCWethan
$palette['y'] = @(245, 215, 80)    # goggle lenses
$palette['i'] = @(110, 200, 255)   # lightning sparks / cyan flame
# Ronin
$palette['2'] = @(228, 222, 215)   # pale skin
$palette['3'] = @(150, 25, 25)     # dark red robe folds
# Nat
$palette['4'] = @(100, 64, 42)     # dark skin
$palette['5'] = @(130, 70, 175)    # purple shirt
# Sansworth / Nassan
$palette['7'] = @(85, 85, 96)      # pinstripes / pattern
# Wally Wolverine
$palette['6'] = @(132, 86, 52)     # brown fur
$palette['8'] = @(78, 48, 28)      # dark brown markings / paws
$palette['9'] = @(196, 156, 110)   # tan snout and belly
$palette['Z'] = @(205, 205, 85)    # yellow-green eyes
# Hopkuna (Hop, tinted red)
$palette['U'] = @(196, 138, 140)   # red-tinted head
$palette['X'] = @(96, 54, 62)      # red-tinted shirt
$palette['q'] = @(206, 150, 152)   # red-tinted arms
$palette['z'] = @(146, 104, 122)   # red-tinted pants
$palette['I'] = @(255, 40, 50)     # glowing red eyes
# Agent
$palette['w'] = @(140, 82, 44)     # wavy brown "bacon" hair
$palette['0'] = @(190, 128, 76)    # lighter hair streaks
$palette['#'] = @(45, 175, 170)    # teal shirt
# Mystery Meat, Overdue Book and the tent
$palette['%'] = @(135, 88, 58)     # mystery meat
$palette[':'] = @(88, 52, 30)      # gravy
$palette['@'] = @(45, 105, 75)     # green book cover
$palette['~'] = @(98, 112, 72)     # olive tent fabric
$palette['^'] = @(66, 78, 48)      # tent seams
$outline = @(125, 125, 140)

$sprites = @{
    'elric_back' = @(
        "........................",
        "........................",
        ".........h.hh.h.........",
        "........hhhhhhhh........",
        ".......hhhhhhhhhh.......",
        "........hhhhhhhh........",
        "........hhhhhhhh........",
        "........hhhhhhhh........",
        "........hhhhhhhh........",
        "........hhhhhhhh........",
        "........LhhhhhhL........",
        ".........LLLLLL.........",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTTTTTTTTtTTTTTT...",
        "...TTTTdTTTTTTttTTTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTrrrrrrrrrrTTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...LLLLTTTTTTTTTTLLLL...",
        "...LLLLTTTTTTTTTTLLLL...",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOtO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......DDDDD.DDDD.......",
        ".......DDDDD.DDDD......."
    )
    'hop_back' = @(
        "........................",
        "........KKKKKKKK........",
        "........KKKKKKKK........",
        "........DDDDDDDD........",
        "......KKKKKKKKKKKK......",
        "........NNNNNNNN........",
        "........NNNNNNNN........",
        "........NNNNNNNN........",
        "........NNNNNNNN........",
        "........NNNNNNNN........",
        "........NNNNNNNN........",
        "........NNNNNNNN........",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......DDDDD.DDDD.......",
        ".......DDDDD.DDDD......."
    )
    'fragment' = @(
        ".....F......",
        "....FFf.....",
        "....FfF.....",
        "...FFFFf....",
        "...FfFFF....",
        "..FFFFFfF...",
        "..FFcFFFF...",
        "..FFFcFFf...",
        "...FFFcFF...",
        "...FFFFF....",
        "....FfFF....",
        "....FFF.....",
        ".....FF.....",
        ".....F......"
    )
    'save_star' = @(
        ".....*.....",
        ".....*.....",
        "....***....",
        "***********",
        ".*********.",
        "..*******..",
        "...*****...",
        "..***.***..",
        "..**...**..",
        ".**.....**.",
        "..........."
    )
    # The SAVE star's second frame: turned partway, so it looks like it's spinning.
    'save_star2' = @(
        ".....*.....",
        ".....*.....",
        ".....*.....",
        "...*****...",
        "....***....",
        "....***....",
        "....***....",
        "....*.*....",
        "...**.**...",
        "...*...*...",
        "..........."
    )
    'elric' = @(
        "........................",
        "........................",
        ".........h.hh.h.........",
        "........hhhhhhhh........",
        ".......hhhhhhhhhh.......",
        "........hLLLLLLh........",
        "........LLLLLLLL........",
        "........LKLLLLKL........",
        "........LLLLLLLL........",
        "........LLLKKLLL........",
        "........LLLLLLLL........",
        ".........LLLLLL.........",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTTTTtTTTTTTTTTT...",
        "...TTTTTTTttTTTTTdTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...TTTTTTTTTTTdTTTTTT...",
        "...TTTTrrrrrrrrrrTTTT...",
        "...TTTTTTTTTTTTTTTTTT...",
        "...LLLLTTTtTTTTTTLLLL...",
        "...LLLLTTTTTTTTTTLLLL...",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOtOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOdO.......",
        ".......OOOOOoOOOO.......",
        ".......OOOOOoOOOO.......",
        ".......DDDDD.DDDD.......",
        ".......DDDDD.DDDD......."
    )
    'hop' = @(
        "........................",
        "........KKKKKKKK........",
        "........KKKKKKKK........",
        "........DDDDDDDD........",
        "......KKKKKKKKKKKK......",
        "........NNNNNNNN........",
        "........NKKNNKKN........",
        "........NNKNNKNN........",
        "........NNNNNNNN........",
        "........NKKKKKKN........",
        "........NKWKWKWN........",
        "........NKKKKKKN........",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        "...llllssssssssssllll...",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......BBBBBnBBBB.......",
        ".......DDDDD.DDDD.......",
        ".......DDDDD.DDDD......."
    )
    'eggo' = @(
        "........b......b........",
        "........bp....pb........",
        "........bbbbbbbb........",
        ".......bbbbbbbbbb.......",
        "......HHHHHHHHHHHH......",
        "......HHYYYYYYYYHH......",
        "......HHYKYYYYKYHH......",
        "...W.WHHYKYYYYKYHH......",
        "...W.WHHYYYYYYYYHH......",
        "..WWWWHHYKYYYYKYHH......",
        ".pWKWWHHYYKKKKYYHH......",
        "..WWWWHHYYYYYYYYHH......",
        "...YYYHHVVSSSSVVHHYYY...",
        "...YYYHHVVSSSSVVHHYYY...",
        "...YYYHHVVVSSVVVHHYYY...",
        "...YYYYHVVVSSVVVHYYYY...",
        "...YYYYVVVVVVVVVVYYYY...",
        "...YYYYVVVVVVVVVVYYYY...",
        "...YYYYVVVVVVVVVVYYYY...",
        "...YYYYVVVVVVVVVVYYYY...",
        "...YYYYVVVVVVVVVVKKKK...",
        "...YYYYVVVVVVVVVVKKKK...",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......PPPPPkPPPP.......",
        ".......DDDDD.DDDD.......",
        ".......DDDDD.DDDD......."
    )
    'bigjoe6' = @(
        "..........K..R..........",
        ".........RK.KR.K........",
        "........KRKRKRKR........",
        "........RKRKRKRK........",
        "........GGGGGGGG........",
        "........GGGGGGGG........",
        "........gggggggg........",
        "........GgGGGGgG........",
        "........GGGGGGGG........",
        "........GgGgGgGG........",
        "........GGGGGGGG........",
        "........GGGGGGGG........",
        "...CCCCCACCCCCCACCCCC...",
        "...CCCCCCACCCCACCCCCC...",
        "...CCCCCCCAWWACCCCCCC...",
        "...CCCCCCCCWWCCCCCCCC...",
        "...CCCCCCCCCCCCCCCCCC...",
        "...CCCCCCCCCCCCCCCCCC...",
        "...CCCCCCCCCCCCCCCCCC...",
        "...CCCCCCCCCCCCCCCCCC...",
        "...WWWWCCCCCCCCCCWWWW...",
        "...CCCCDDDDDGDDDDCCCC...",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......JJJJJjJJJJ.......",
        ".......DDDDD.DDDD.......",
        ".......DDDDD.DDDD......."
    )
}

# --- The mall cast (front views) ---------------------------------------------

$sprites['muffinmage'] = @(
    "........................",
    "...........mm...........",
    "..........mmmm..........",
    "......MMMMMMMMMMMM......",
    ".....MMMMMMMMMMMMMM.....",
    ".....MMWKMMMMMMKWMM.....",
    ".....MMWWMMMMMMWWMM.....",
    ".....MMMMMMKKMMMMMM.....",
    ".....MMMMMKKKKMMMMM.....",
    ".....MMMMMKKKKMMMMM.....",
    "......MMMMMKKMMMMM......",
    "....mm.MMMMMMMMMM.mm....",
    "...EEEEEEEEEEEEEEEEEE...",
    "...EEEEEEEEEEEEEEEEEE...",
    "...EEEEEEEEEEEEEEEEEE...",
    "...QQQQEEEEEEEEEEQQQQ...",
    "...QQQQEEEEEEEEEEQQQQ...",
    "...QQQQEEEEEEEEEEQQQQ...",
    "...QQQQEEEEEEEEEEQQQQ...",
    "...QQQQEEEEEEEEEEQQQQ...",
    "...QQQQEEEEEEEEEEQQQQ...",
    "...QQQQEEEEEEEEEEQQQQ...",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......JJJJJjJJJJ.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

$sprites['supreme'] = @(
    "........................",
    ".........K.K.K..........",
    "........KKKKKKKK........",
    ".......WYYYYYYYYW.......",
    "........KKKKKKKK........",
    "........QQQQQQQQ........",
    "........QvQQQQKQ........",
    "........KKKKKKKK........",
    "........KKeKKeKK........",
    "........KKKeeKKK........",
    "........KKKKKKKK........",
    ".......uuuuuuuuuu.......",
    "...YYYYuuYYYYYYYuYYYY...",
    "...KYYYuuYeeeeYYuYYYK...",
    "...YKYYuYY1111YYYYYKY...",
    "...KYYYYYYDDDDYYYYYYK...",
    "...YKYYYYYeeeeYYYYYKY...",
    "...KYYYYYYYYYYYYYYYYK...",
    "...YKYYYYYYYYYYYYYYKY...",
    "...KYYYYYYYYYYYYYYYYK...",
    "...QQQQYYYYYYYYYYQQQQ...",
    "...QQQQYYYYYYYYYYQQQQ...",
    ".......PPPPPkPPPP.......",
    ".......PPkPPkPPPP.......",
    ".......PPPPPkPPPP.......",
    ".......PPPPPkPPkP.......",
    ".......PPPPPkPPPP.......",
    ".......PkPPPkPPPP.......",
    ".......PPPPPkPPPP.......",
    ".......PPPPPkPPPP.......",
    ".......11W11.1W11.......",
    ".......WWWWW.WWWW......."
)

$sprites['crayola'] = @(
    "........................",
    "........................",
    "........................",
    "........................",
    "........WWWWWWWW........",
    "........WWWWWWWW........",
    "........WKWWWWKW........",
    "........WKWWWWKW........",
    "........WWWWWWWW........",
    "........WWKKKKWW........",
    "........WWKppKWW........",
    "........WWWWWWWW........",
    "...WWWWWWWWWWWWWWWWWW...",
    "...WaaaaaaaaaaSSaaaaW...",
    "...WWWWWWWWWWWSSWWWWW...",
    "...WaaaWaaaaaaaaaaaaW...",
    "...WWWWWWWWWWWWWWWWWW...",
    "...WaaaaaaWaaaaaaaaaW...",
    "...WWWWWWWWWWWWWWWWWW...",
    "...WaaaaaaaaaaaWaaaaW...",
    "...WWWWWWWWWWWWWWWWWW...",
    "...WWWWWWWWWWWWWWWWWW...",
    ".......xxxxxkxxxx.......",
    ".......xxxxxkxxxx.......",
    ".......xxkxxkxxxx.......",
    ".......xxxxxkxxxx.......",
    ".......xxxxxkxkxx.......",
    ".......xxxxxkxxxx.......",
    ".......xkkxxkxxkx.......",
    ".......xxxxxkxxxx.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

$sprites['ncwethan'] = @(
    "........................",
    "........KKKKKKKK........",
    ".......KKKKKKKKKK.......",
    ".......KyyyKKyyyK.......",
    ".......KyyyKKyyyK.......",
    "........YYYYYYYY........",
    "........YKYYYYKY........",
    "........YKYYYYKY........",
    "........YYYYYYYY........",
    ".....i..YKYYYYKY........",
    "........YYKKKKYY........",
    "........YYYYYYYY........",
    "...WWWWWWWWWWWWWWWWWW...",
    "...WWWWWWWWRRWWWWWWWW...",
    ".i.YYYYWWWRRRRWWWYYYY...",
    "...YYYYWWRREERRWWYYYY...",
    "...YYYYWWWRRRRWWWYYYY...",
    "...YYYYWWWWRRWWWWYYYY...",
    "...YYYYWWWWWWWWWWYYYY...",
    "...YYYYWWWWWWWWWWYYYY.i.",
    "...YYYYWWWWWWWWWWYYYY...",
    "...YYYYWWWWWWWWWWYYYY...",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......SSSSSjSSSS.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

$sprites['ronin'] = @(
    "......................i.",
    "..........E.Y.E......ii.",
    ".........EKYKEK......iK.",
    ".........KKKKKK.......K.",
    "........RRRRRRRR......K.",
    "....RRRRRRRRRRRRRRRR..K.",
    ".......K22222222K.....K.",
    ".......K2K2222K2K.....K.",
    ".......K22222222K.....K.",
    ".......K222KK222K.....K.",
    ".......K22K22K22K.....K.",
    ".......K.222222.K.....K.",
    "...2K2KRRR3RR3RRRRRRR..K",
    "...K2K2RRR3RR3RRRRRRR..K",
    "...2K2KRRR3RR3RRRRRRR..K",
    "...K2K2RRR3RR3RRRRRRR..K",
    "...2K2KRRR3RR3RRRRRRR..K",
    "...K2K2RRR3RR3RRRRRRR..K",
    "...2K2KRRR3RR3RRRRRRR..K",
    "...K2K2RRR3RR3RRRRRRR..K",
    "...2222RRR3RR3RRRQQQQQQK",
    "...2222RRR3RR3RRRQQQQ..K",
    ".......RRR3RR3RRR......K",
    ".......RRR3RR3RRR......K",
    ".......RRR3RR3RRR......K",
    ".......RRR3RR3RRR......K",
    ".......RRR3RR3RRR......K",
    ".......RRR3RR3RRR......K",
    ".......CCCCCkCCCC......K",
    ".......CCCCCkCCCC......K",
    ".......DDDDD.DDDD......K",
    ".......DDDDD.DDDD......K"
)

$sprites['rooster'] = @(
    "........................",
    "........KKKKKKKK........",
    "........KKKKKKKK........",
    "........KKKKKKKK........",
    "......KKKKKKKKKKKK......",
    "......hhQQQQQQQQhh......",
    "........QKQQQQKQ........",
    "........QQQQQQQQ........",
    "........QQKKKKQQ........",
    "........QQQppQQQ........",
    "........QQQppQQQ........",
    "........QQQQQQQQ........",
    "...WWWWWWWWKKCCCCCCCC...",
    "...WWWWWWWWKKCCCCCCCC...",
    "...WWWWWWWWKKCCCCCCCC...",
    "...WWWWWWWWKKCCCCCCCC...",
    "...WWWWWWWWWCCCCCCCCC...",
    "...WWWWWWWWWCCCCCCCCC...",
    "...WWWWWWWWWCCCCCCCCC...",
    "...WWWWWWWWWCCCCCCCCC...",
    "...QQQQWWWWWCCCCCQQQQ...",
    "...QQQQWWWWWCCCCCQQQQ...",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......WWWWWCCCCC.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

$sprites['nat'] = @(
    "........................",
    "..........CCCC..........",
    "........CCWWWWCC........",
    "......CCWWWWWWWWCC......",
    ".....CWWWWWWWWWWWWC.....",
    "........44444444........",
    "........44444444........",
    "........4KK44KK4........",
    "........4WK44WK4........",
    "........44444444........",
    "........444KK444........",
    "........44444444........",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...CCCC5555555555CCCC...",
    "...444455555555554444...",
    "...444455555555554444...",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......CCCCCkCCCC.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

$sprites['sansworth'] = @(
    "........................",
    "........................",
    "........................",
    "........................",
    "........WWWWWWWW........",
    "........WWWWWWWW........",
    "........WKKWWKKW........",
    "........WKKWWKKW........",
    "........WWWWWWWW........",
    "........KWWWWWWK........",
    "........WKKKKKKW........",
    "........WWWWWWWW........",
    "...7CC7CC7WKKW7CC7CC7...",
    "...7CC7C7CWKKWC7C7CC7...",
    "...7CC7C7CCKKCC7C7CC7...",
    "...7CC7C7CCKKCC7C7CC7...",
    "...7CC7C7CC7CCC7C7CC7...",
    "...7CC7C7CC7CCC7C7CC7...",
    "...7CC7C7CC7CCC7C7CC7...",
    "...7CC7C7CC7CCC7C7CC7...",
    "...WWWWC7CC7CCC7CWWWW...",
    "...WWWWC7CC7CCC7CWWWW...",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......C7CCC7CC7C.......",
    ".......WWWWW.WWWW.......",
    ".......WWWWW.WWWW......."
)

$sprites['nassan'] = @(
    "........................",
    "........KKKKKKKK........",
    "........KKKKKKKK........",
    "........WWWWWWWW........",
    "......KKKKKKKKKKKK......",
    "........CCCCCCCC........",
    "........CCCCCCCC........",
    "........CWCCCCWC........",
    "........CCCCCCCC........",
    "........CCCCCCCC........",
    "........CCCKKCCC........",
    "........CCCCCCCC........",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKWKWWKWKWKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    "...llllKKKKKKKKKKllll...",
    ".......C7C7CC7C7C.......",
    ".......C7C7CC7C7C.......",
    ".......7C7CC7C7CC.......",
    ".......C7C7CC7C7C.......",
    ".......7C7CC7C7CC.......",
    ".......C7C7CC7C7C.......",
    ".......7C7CC7C7CC.......",
    ".......C7C7CC7C7C.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

# Agent: wavy brown hair, a black jacket over a teal graphic tee.

$sprites['agent'] = @(
    "........................",
    "........ww0ww0ww........",
    "......ww0www0www0w......",
    ".....w0www0www0www0.....",
    ".....ww0www0www0www.....",
    ".....w0wYYYYYYYYw0w.....",
    ".....wwwYKYYYYKYwww.....",
    "......w0YKYYYYKY0w......",
    "......wwYYYYYYYYww......",
    "......w0YKYYYYKY0w......",
    ".......wYYKKKKYYw.......",
    "........YYYYYYYY........",
    "...CCCCCC######CCCCCC...",
    "...CCCCCC######CCCCCC...",
    "...CCCCC#KK##KK#CCCCC...",
    "...CCCCC#KKKKKK#CCCCC...",
    "...CCCCC##KKKK##CCCCC...",
    "...CCCCC###KK###CCCCC...",
    "...CCCCC########CCCCC...",
    "...CCCCC########CCCCC...",
    "...YYYYC########CYYYY...",
    "...YYYYC########CYYYY...",
    ".......PP7PPkPP7P.......",
    ".......P7PPPkP7PP.......",
    ".......PPP7PkPPP7.......",
    ".......P7PPPk7PPP.......",
    ".......PP7PPkPP7P.......",
    ".......P7PPPkP7PP.......",
    ".......PPP7PkPPP7.......",
    ".......P7PPPk7PPP.......",
    ".......WWWWW.WWWW.......",
    ".......WWWWW.WWWW......."
)

# --- Westview High School enemies -------------------------------------------

$sprites['pop_quiz'] = @(
    "........................",
    "........................",
    "........................",
    "........................",
    "......WWWWWWWWWW........",
    "......WWWWWWWWWWW.......",
    "......WWWWWWWWWWWW......",
    "......WaaaaaaWWWWW......",
    "......WWWWWWWWWWWW......",
    "......WWKKWWWKKWWW......",
    "......WWWKWWWKWWWW......",
    "......WWWWWWWWWWWW......",
    "......WWWKKKKKWWWW......",
    "......WWKWWWWWKWWW......",
    "......WWWWWWWWWWWW......",
    "......WaaaaaaaaaaW......",
    "......WWWWWWWWWWWW......",
    "......WaaaaWWaaaaW......",
    "......WWWWWWWWWWWW......",
    "......WKWWaaaaaaaW......",
    "......WWWWWWWWWWWW......",
    "......WKWWaaaaaaaW......",
    "......WWWWWWWWWWWW......",
    "......WWWWWWWWRRWW......",
    "......WWWWWWWWRWWW......",
    "......WWWWWWWWWWWW......",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................"
)

$sprites['hall_pass'] = @(
    "........................",
    "........................",
    ".........eeeeee.........",
    "........ee....ee........",
    "........ee....ee........",
    "......eeeeeeeeeeee......",
    "......eeeeeeeeeeee......",
    "......eKKKKKKKKKKe......",
    "......eKWWWWWWWWKe......",
    "......eKKKKKKKKKKe......",
    "......eeeeeeeeeeee......",
    "......eeKKeeeeKKee......",
    "......eeKWeeeeKWee......",
    "......eeeeeeeeeeee......",
    "......eeeeKKKKeeee......",
    "......eeeeKKKKeeee......",
    "......eeeeeeeeeeee......",
    "......eeeeeeeeeeee......",
    "..K...eeeeeeeeeeee...K..",
    "...K..eeeeeeeeeeee..K...",
    "....K.eeeeeeeeeeee.K....",
    ".....KeeeeeeeeeeeeK.....",
    "......eeeeeeeeeeee......",
    "........K......K........",
    ".......K........K.......",
    "......K..........K......",
    ".....K............K.....",
    "....K..............K....",
    "...KK..............KK...",
    "........................",
    "........................",
    "........................"
)

# Wally Wolverine, Westview's mascot: a brown furry wolverine costume.
$sprites['wally'] = @(
    "................................",
    "......666..............666......",
    ".....66866............66866.....",
    ".....6666666666666666666666.....",
    ".....6668886666666666888666.....",
    ".....6688886666666666888866.....",
    ".....668ZZK8666666668KZZ866.....",
    ".....6688886666666666888866.....",
    ".....6666666999999996666666.....",
    ".....666666999KKKK999666666.....",
    ".....6666669999999999666666.....",
    ".....666666999KKKK999666666.....",
    ".....66666699WKKKKW99666666.....",
    ".....66666669WWKWW966666666.....",
    ".....6666666699999966666666.....",
    ".......666666666666666666.......",
    "..........666666666666..........",
    "....666666666666666666666666....",
    "...66666666999999999966666666...",
    "...66666666999999999966666666...",
    "...66666666999999999966666666...",
    "...66666666999999999966666666...",
    "...66666666999999999966666666...",
    "...66666666999999999966666666...",
    "...66666666999999999966666666...",
    "...66666666699999999666666666...",
    "...88888666666999966666688888...",
    "...88888666666666666666688888...",
    "...W.W.W6666666666666666W.W.W...",
    "........6666666..6666666........",
    "........6666666..6666666........",
    "........6666666..6666666........",
    "........6666666..6666666........",
    "........6666666..6666666........",
    "......888888888..888888888......",
    "......888888888..888888888......"
)


# Hopkuna: Hop's body, tinted red, covered in black tattoo markings, eyes glowing red.
$sprites['hopkuna'] = @(
    "........................",
    "........KKKKKKKK........",
    "........KKKKKKKK........",
    "........DDDDDDDD........",
    "......KKKKKKKKKKKK......",
    "........UKUUUUKU........",
    "........UKKUUKKU........",
    "........UUIUUIUU........",
    "........KUUUUUUK........",
    "........UKKKKKKU........",
    "........UKWKWKWU........",
    "........KKKKKKKK........",
    "...qqqqXXXXXXXXXXqqqq...",
    "...KKKKXXKXXXXKXXKKKK...",
    "...qqqqXXXKXXKXXXqqqq...",
    "...qqqqXXXXKKXXXXqqqq...",
    "...qKqqXXXKXXKXXXqqKq...",
    "...qqqqXXKXXXXKXXqqqq...",
    "...KKKKXXXXXXXXXXKKKK...",
    "...qqqqXXXXXXXXXXqqqq...",
    "...qqKqXXXXXXXXXXqKqq...",
    "...qqqqXXXXXXXXXXqqqq...",
    ".......zzzzznzzzz.......",
    ".......zKzzznzzKz.......",
    ".......zzzzznzzzz.......",
    ".......zzKzznzKzz.......",
    ".......zzzzznzzzz.......",
    ".......zKzzznzzKz.......",
    ".......zzzzznzzzz.......",
    ".......zzzzznzzzz.......",
    ".......DDDDD.DDDD.......",
    ".......DDDDD.DDDD......."
)

# --- More Westview enemies, the tent, and Wally's empty costume -------------

# Mystery Meat: a brown lump with googly eyes, sitting in gravy on a lunch tray.
$sprites['mystery_meat'] = @(
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "..........%%%%..........",
    "........%%%%%%%%........",
    ".......%%%%%%%%%%.......",
    "......%%%%::%%%%%%......",
    "......%%WWK%%%WWK%......",
    ".....%%%WKK%%%WKK%%.....",
    ".....%%%%%%%%%%%%%%.....",
    ".....%%%%%::::%%%%%.....",
    "....%%%%%:KKKK:%%%%%....",
    "....%%%%%%::::%%%%%%....",
    "....%%:%%%%%%%%%%:%%....",
    "...:%%%%%%%%%%%%%%%%:...",
    "...::%%%%%%%%%%%%%%::...",
    "..GG::::::::::::::::GG..",
    "..GGGGGGGGGGGGGGGGGGGG..",
    "..GggggggggggggggggggG..",
    "..GGGGGGGGGGGGGGGGGGGG..",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................"
)

# Tardy Bell: a red school bell with angry eyes and a gold rim, on stubby legs.
$sprites['tardy_bell'] = @(
    "........................",
    "........................",
    "........................",
    "..........DDDD..........",
    "..........D..D..........",
    "..........RRRR..........",
    "........RRRRRRRR........",
    ".......RRRRRRRRRR.......",
    "......RRRRRRRRRRRR......",
    "......RRKRRRRRRKRR......",
    "......RRWKRRRRKWRR......",
    ".....RRRKKRRRRKKRRR.....",
    ".....RRRRRRRRRRRRRR.....",
    ".....RRRRR3333RRRRR.....",
    "....RRRRR3KKKK3RRRRR....",
    "....RRRRRR3333RRRRRR....",
    "....RRRRRRRRRRRRRRRR....",
    "...RRRRRRRRRRRRRRRRRR...",
    "...AAAAAAAAAAAAAAAAAA...",
    "..AAAAAAAAAAAAAAAAAAAA..",
    "..........DDDD..........",
    "..........DDDD..........",
    "...........DD...........",
    "........K......K........",
    "........K......K........",
    ".......KK......KK.......",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................"
)

# Overdue Book: a fat green library book with a red bookmark tongue and a due-date stamp.
$sprites['overdue_book'] = @(
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "....@@@@@@@@@@@@@@@.....",
    "....@@@@@@@@@@@@@@@W....",
    "....@@@@@@@@@@@@@@@WW...",
    "....@@AAAAAAAAAAA@@WW...",
    "....@@@@@@@@@@@@@@@WW...",
    "....@@@WWK@@@@WWK@@WW...",
    "....@@@WKK@@@@WKK@@WW...",
    "....@@@@@@@@@@@@@@@WW...",
    "....@@@@@KKKKKK@@@@WW...",
    "....@@@@@KRRRRK@@@@WW...",
    "....@@@@@@@RR@@@@@@WW...",
    "....@@@@@@@RR@@@@@@WW...",
    "....@@@@@@@@@@@@@@@WW...",
    "....@@WWWWWWWWWW@@@WW...",
    "....@@WRRRRRRRRW@@@WW...",
    "....@@WWWWWWWWWW@@@WW...",
    "....@@@@@@@@@@@@@@@WW...",
    "....@@AAAAAAAAAAA@@WW...",
    "....@@@@@@@@@@@@@@@W....",
    "....@@@@@@@@@@@@@@@.....",
    "......KK.......KK.......",
    "......KK.......KK.......",
    ".....KKK......KKK.......",
    "........................",
    "........................",
    "........................",
    "........................"
)

# A three-person dome tent. Olive green, zipped almost shut. Just a tent.
$sprites['tent'] = @(
    "................................",
    "................................",
    "..............~~~~..............",
    "...........~~~~^^~~~~...........",
    ".........~~~~~~^^~~~~~~.........",
    ".......~~~~~~~~^^~~~~~~~~.......",
    "......~~~~~~~~~^^~~~~~~~~~......",
    ".....~~~~~~~~~~^^~~~~~~~~~~.....",
    "....~~~~~~~~~~K^^K~~~~~~~~~~....",
    "....^^~~~~~~~KK^^KK~~~~~~~^^....",
    "...~~^^~~~~~KKK^^KKK~~~~^^~~~...",
    "...~~~~^^~~KKKK^^KKKK~~^^~~~~...",
    "..~~~~~~~^^KKKK^^KKKK^^~~~~~~~..",
    "..~~~~~~~~KKKKK^^KKKKK~~~~~~~~..",
    "..~~~~~~~KKKKKK^^KKKKKK~~~~~~~..",
    ".~~~~~~~~KKKKKK^^KKKKKK~~~~~~~~.",
    ".~~~~~~~KKKKKKK^^KKKKKKK~~~~~~~.",
    ".^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^.",
    "D..............................D",
    "................................"
)

# Wally's costume after the fragment leaves it: an empty, slumped pile of fur.
$sprites['wally_slump'] = @(
    "..................................",
    "..................................",
    ".....666................666.......",
    "....66866..............66866......",
    "....666666666666666666666666......",
    "....666K8K666666666666K8K666......",
    "....6668K866999999996668K866......",
    "....666K8K69999KKK999666K8K666....",
    "...666666669999999999666666666....",
    "..666666666666666666666666666666..",
    ".66666699999999999999999966666666.",
    ".666666699999999999999996666666666",
    "88888666666666666666666666668888W.",
    "W.W.W.8888888888888888888888W.W..."
)

# A storage box: a wooden chest with a silver band and a gold lock.
$sprites['storage_box'] = @(
    "..KKKKKKKKKKKK..",
    ".KeeeeeeeeeeeeK.",
    "KeeeeeeeeeeeeeeK",
    "KGGGGGGGGGGGGGGK",
    "KeeeeeeAAeeeeeeK",
    "KeeeeeeAAeeeeeeK",
    "KeeeeeeeeeeeeeeK",
    "KeeeeeeeeeeeeeeK",
    "KGGGGGGGGGGGGGGK",
    "KKKKKKKKKKKKKKKK"
)

# --- Side views (walking right; the game flips them for walking left) -------
# Each character gets two frames: legs together and mid-step.

function Get-Legs([string]$c, [string]$shoe, [bool]$step) {
    if (-not $step) {
        $rows = @()
        for ($i = 0; $i -lt 8; $i++) { $rows += ".........." + ($c * 5) + "........." }
        $rows += ".........." + ($shoe * 6) + "........"
        $rows += ".........." + ($shoe * 6) + "........"
        return $rows
    }
    $c3 = $c * 3
    # (Each row is in parentheses so PowerShell joins the pieces before making the list.)
    return @(
        (".........." + ($c * 5) + "........."),
        ("........." + $c3 + "." + $c3 + "........"),
        ("........" + $c3 + "..." + $c3 + "......."),
        ("........" + $c3 + "..." + $c3 + "......."),
        ("......." + $c3 + "....." + $c3 + "......"),
        ("......." + $c3 + "....." + $c3 + "......"),
        ("......" + $c3 + "......." + $c3 + "....."),
        ("......" + $c3 + "......." + $c3 + "....."),
        ("....." + ($shoe * 4) + "......." + ($shoe * 4) + "...."),
        ("....." + ($shoe * 4) + "......." + ($shoe * 4) + "....")
    )
}

$sideUpper = @{
    'elric' = @(
        "........................",
        "........................",
        "..........h.hh..........",
        ".........hhhhhh.........",
        "........hhhhhhhh........",
        "........hhhLLLLL........",
        "........hhLLLLLL........",
        "........hhLLLLKL........",
        "........hhLLLLLL........",
        "........hhLLLLKL........",
        "........hLLLLLLL........",
        ".........LLLLLL.........",
        ".........TTTTTTT........",
        ".........TTtttTT........",
        ".........TTtttTT........",
        ".........TTtttTd........",
        ".........TTtttTT........",
        ".........TTtttTT........",
        ".........rrtttrr........",
        ".........TTtttTT........",
        ".........TTLLLTT........",
        ".........TTLLLTT........"
    )
    'hop' = @(
        "........................",
        ".........KKKKKK.........",
        ".........KKKKKK.........",
        ".........DDDDDD.........",
        ".......KKKKKKKKKK.......",
        ".........NNNNNNN........",
        ".........NNNNKKN........",
        ".........NNNNNKN........",
        ".........NNNNNNN........",
        ".........NNNNKKK........",
        ".........NNNNWKW........",
        ".........NNNNKKK........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........",
        ".........sslllss........"
    )
    'eggo' = @(
        "..........b...b.........",
        "..........bbbbb.........",
        ".........bbbbbbb........",
        "........bbbbbbbbb.......",
        ".......HHHHHHHHHH.......",
        ".......HHHYYYYYYY.......",
        ".......HHHYYYYKYY.......",
        ".......HHHYYYYKYY.......",
        ".......HHHYYYYYYY.......",
        ".......HHHYYYYYKK.......",
        ".......HHHYYYYYYY.......",
        ".......HHH.YYYYY........",
        ".......HHHVYYYVV........",
        ".......HHVVYYYVS........",
        ".......HHVVYYYVS........",
        "........HVVYYYVS........",
        ".........VVYYYVS........",
        ".........VVYYYVS........",
        ".........VVYYYVS........",
        ".........VVYYYVS........",
        ".........VVYYYVV........",
        ".........VVKKKVV........"
    )
    'bigjoe6' = @(
        "...........K.R..........",
        "..........RK.KR.........",
        ".........KRKRKRK........",
        ".........RKRKRKR........",
        ".........GGGGGGG........",
        ".........GGGGGGG........",
        ".........GGGGggg........",
        ".........GGGGGgG........",
        ".........GGGGGGG........",
        ".........GGGGgGg........",
        ".........GGGGGGG........",
        ".........GGGGGGG........",
        ".........CCDDDCA........",
        ".........CCDDDAC........",
        ".........CCDDDCW........",
        ".........CCDDDCC........",
        ".........CCDDDCC........",
        ".........CCDDDCC........",
        ".........CCDDDCC........",
        ".........CCDDDCC........",
        ".........CCWWWCC........",
        ".........DDCCCGD........"
    )
}
$sideLegs = @{ 'elric' = @('O', 'D'); 'hop' = @('B', 'D'); 'eggo' = @('P', 'D'); 'bigjoe6' = @('J', 'D') }

# The arm (a 3-pixel column in the middle of the body, columns 11-13) swings: on
# one step it reaches forward a pixel, on the other it swings back.
function Swing-Arm([string[]]$rows, [int]$dir) {
    $out = [string[]]$rows.Clone()
    for ($y = 17; $y -le 21; $y++) {
        $c = $out[$y].ToCharArray()
        if ($c[10] -eq '.' -or $c[14] -eq '.') { continue }
        # The hand swings further than the elbow, so the arm angles.
        $shift = if ($y -ge 19) { 2 } else { 1 }
        $arm = $c[11..13]
        $body = if ($dir -gt 0) { $c[10] } else { $c[14] }
        for ($i = 11; $i -le 13; $i++) { $c[$i] = $body }
        for ($i = 0; $i -lt 3; $i++) { $c[11 + $i + $shift * $dir] = $arm[$i] }
        $out[$y] = -join $c
    }
    return $out
}

foreach ($who in $sideUpper.Keys) {
    $legs = $sideLegs[$who]
    $sprites["${who}_side"] = $sideUpper[$who] + (Get-Legs $legs[0] $legs[1] $false)
    $step = $sideUpper[$who] + (Get-Legs $legs[0] $legs[1] $true)
    $sprites["${who}_side2"] = Swing-Arm $step 1
    $sprites["${who}_side3"] = Swing-Arm $step -1
}

# --- Limbs that aren't glued to the body ---------------------------------------
# Most of the cast share one body layout: shoulders on rows 12-14, arms in columns
# 3-6 and 17-20 down to row 21, legs below with a dividing line in column 12.
# Below the shoulders, each arm moves out by one pixel, and the legs get a gap
# between them. The outline then fills those gaps, so arms and legs read as
# separate limbs instead of one solid block.

function Add-LimbGaps([string[]]$rows) {
    $out = [string[]]$rows.Clone()
    if ($rows[0].Length -ne 24 -or $rows.Count -lt 32) { return $out }
    # Only for sprites with this exact layout: arms on both sides, room to move out.
    $r = $rows[15]
    if ($r[3] -eq '.' -or $r[20] -eq '.' -or $r[2] -ne '.' -or $r[21] -ne '.') { return $out }
    for ($y = 15; $y -le 21; $y++) {
        $c = $out[$y].ToCharArray()
        if ($c[2] -ne '.' -or $c[21] -ne '.') { continue }
        $left = $c[3..6]
        $right = $c[17..20]
        for ($i = 0; $i -lt 4; $i++) { $c[2 + $i] = $left[$i]; $c[18 + $i] = $right[$i] }
        $c[6] = '.'
        $c[17] = '.'
        $out[$y] = -join $c
    }
    # A gap between the legs (above the shoes).
    for ($y = 22; $y -le 29; $y++) {
        $c = $out[$y].ToCharArray()
        if ($c[11] -ne '.' -and $c[13] -ne '.') { $c[12] = '.' }
        $out[$y] = -join $c
    }
    return $out
}

foreach ($name in @($sprites.Keys)) {
    $sprites[$name] = Add-LimbGaps $sprites[$name]
}

# --- Facial expressions (dialogue portraits only) -----------------------------
# Each mood is a little 8 x 6 stamp drawn over the face (columns 8-15, rows 6-11
# of the front view). In a stamp:
#   .  keep the original pixel     s  skin     K  eyes / mouth
#   W  white                       i  a tear
# The finished portraits go in art/portraits/ as name_mood.png.

$moods = [ordered]@{
    'happy' = @(
        ".KssssK.",
        "KsKssKsK",
        ".ssssss.",
        ".KssssK.",
        ".sKKKKs.",
        ".ssssss."
    )
    'angry' = @(
        ".KssssK.",
        ".sKssKs.",
        ".KKssKK.",
        ".ssssss.",
        ".sKKKKs.",
        ".KssssK."
    )
    'sad' = @(
        ".sKssKs.",
        ".KssssK.",
        ".KssssK.",
        ".isssss.",
        ".ssKKss.",
        ".sKssKs."
    )
    'shocked' = @(
        ".ssssss.",
        ".KKssKK.",
        ".KKssKK.",
        ".ssssss.",
        ".ssKKss.",
        ".ssKKss."
    )
    'smug' = @(
        ".ssssss.",
        ".KKssKK.",
        ".ssssss.",
        ".sssssK.",
        ".ssKKKs.",
        ".ssssss."
    )
}

# Who gets expressions: skin letter, and the letter used for eyes / mouth.
$faces = [ordered]@{
    'elric'     = @('L', 'K')
    'hop'       = @('N', 'K')
    'eggo'      = @('Y', 'K')
    'crayola'   = @('W', 'K')
    'ncwethan'  = @('Y', 'K')
    'ronin'     = @('2', 'K')
    'rooster'   = @('Q', 'K')
    'nat'       = @('4', 'K')
    'sansworth' = @('W', 'K')
    'nassan'    = @('C', 'W')
    'agent'     = @('Y', 'K')
}
# Hop keeps his gritted-teeth grin for these moods (only his eyes change).
$keepMouth = @{ 'hop' = @('happy', 'angry', 'smug') }

$portraits = [ordered]@{}
foreach ($who in $faces.Keys) {
    $skin = $faces[$who][0]
    $feature = $faces[$who][1]
    foreach ($mood in $moods.Keys) {
        $rows = [string[]]($sprites[$who].Clone())
        $stamp = $moods[$mood]
        $stampRows = $stamp.Count
        if ($keepMouth.ContainsKey($who) -and $keepMouth[$who] -contains $mood) { $stampRows = 3 }
        for ($r = 0; $r -lt $stampRows; $r++) {
            $chars = $rows[6 + $r].ToCharArray()
            for ($c = 0; $c -lt 8; $c++) {
                $s = $stamp[$r][$c]
                if ($s -eq '.') { continue }
                $chars[8 + $c] = switch ($s) { 's' { $skin } 'K' { $feature } default { $s } }
            }
            $rows[6 + $r] = -join $chars
        }
        $portraits["${who}_$mood"] = $rows
    }
}

# BigJoe6's helmet hides his face, so his eyes glow through the visor slit instead.
$visor = @{
    'happy'   = "........gWggggWg........"
    'angry'   = "........gRRggRRg........"
    'sad'     = "........giiggiig........"
    'shocked' = "........gWWggWWg........"
    'smug'    = "........ggggyyyg........"
}
foreach ($mood in $visor.Keys) {
    $rows = [string[]]($sprites['bigjoe6'].Clone())
    $rows[6] = $visor[$mood]
    $portraits["bigjoe6_$mood"] = $rows
}

# --- Walking frames (front and back views) ------------------------------------
# For everyone with the standard body layout: two extra frames where one leg lifts
# (its foot one pixel higher) and the arms swing (one up a pixel, one down). The
# game cycles  step A, stand, step B, stand  for a smooth walk.
# Saved as name_walk1 / name_walk2 (and name_back_walk1 / name_back_walk2).

function Shift-Block([string[]]$rows, [int]$x0, [int]$x1, [int]$y0, [int]$y1, [int]$dy) {
    $copy = [string[]]$rows.Clone()
    # Clear the block, then redraw it moved by dy rows.
    for ($y = $y0; $y -le $y1; $y++) {
        $c = $rows[$y].ToCharArray()
        for ($x = $x0; $x -le $x1; $x++) { $c[$x] = '.' }
        $rows[$y] = -join $c
    }
    for ($y = $y0; $y -le $y1; $y++) {
        $ty = $y + $dy
        if ($ty -lt 0 -or $ty -ge $rows.Count) { continue }
        $c = $rows[$ty].ToCharArray()
        for ($x = $x0; $x -le $x1; $x++) {
            $ch = $copy[$y][$x]
            if ($ch -ne '.') { $c[$x] = $ch }
        }
        $rows[$ty] = -join $c
    }
}

function Make-Step([string[]]$rows, [bool]$leftLeg) {
    $p = [string[]]$rows.Clone()
    # Lift one leg (and its shoe) by a pixel.
    if ($leftLeg) { Shift-Block $p 7 11 22 31 -1 } else { Shift-Block $p 13 16 22 31 -1 }
    # Swing the arms: the arm on the lifted leg's side goes back (down), the other forward (up).
    if ($leftLeg) { Shift-Block $p 2 5 15 21 1; Shift-Block $p 18 21 15 21 -1 }
    else { Shift-Block $p 2 5 15 21 -1; Shift-Block $p 18 21 15 21 1 }
    return $p
}

$walkFrames = [ordered]@{}
foreach ($name in @($sprites.Keys)) {
    $rows = $sprites[$name]
    if ($rows[0].Length -ne 24 -or $rows.Count -lt 32) { continue }
    # Only bodies with separated arms (see Add-LimbGaps) and legs.
    if ($rows[15][2] -eq '.' -or $rows[15][21] -eq '.' -or $rows[24][8] -eq '.') { continue }
    $walkFrames["${name}_walk1"] = Make-Step $rows $true
    $walkFrames["${name}_walk2"] = Make-Step $rows $false
}

# --- Battle poses (Elric and Hop) ---------------------------------------------
# In battle, Elric and Hop stand turned sideways toward the enemy (built from their
# side views), each in their own fighting style:
#   Hop    a boxer: upright, fists wrapped in white tape, lead fist out at chin
#          height, rear fist guarding his face, feet staggered.
#   Elric  a scrapper: low and loose, lead hand open and reaching with claws out,
#          rear hand down by the hip, ready to swipe.
# The painted-on arm is removed from the side view, and new arms are drawn for each
# pose. The canvas is 6 pixels wider on each side so outstretched arms fit.
# Poses: stance, windup, strike, guard, raise, hurt, ko.

$PAD = 6
$poseStyle = @{
    'elric' = @{ 'sleeve' = 't'; 'hand' = 'L'; 'claw' = 'W'; 'arm_rows' = 13 }
    'hop'   = @{ 'sleeve' = 'l'; 'hand' = 'W'; 'claw' = ''; 'arm_rows' = 12 }
}

function Put([string[]]$rows, [int]$x, [int]$y, [string]$ch) {
    if ($y -lt 0 -or $y -ge $rows.Count -or $x -lt 0 -or $x -ge $rows[0].Length -or $ch -eq '' -or $ch -eq '.') { return }
    $c = $rows[$y].ToCharArray()
    $c[$x] = $ch
    $rows[$y] = -join $c
}

# A thick line (an arm segment) from (x0, y0) to (x1, y1).
function Draw-Limb([string[]]$rows, [double]$x0, [double]$y0, [double]$x1, [double]$y1, [string]$ch, [int]$thick = 2) {
    $steps = [math]::Max(1, [int]([math]::Max([math]::Abs($x1 - $x0), [math]::Abs($y1 - $y0)) * 2))
    for ($i = 0; $i -le $steps; $i++) {
        $f = $i / $steps
        $px = [int][math]::Round($x0 + ($x1 - $x0) * $f)
        $py = [int][math]::Round($y0 + ($y1 - $y0) * $f)
        for ($dx = 0; $dx -lt $thick; $dx++) { for ($dy = 0; $dy -lt $thick; $dy++) { Put $rows ($px + $dx) ($py + $dy) $ch } }
    }
}

# A square fist (or open hand) at (x, y), `size` pixels.
function Draw-Hand([string[]]$rows, [int]$x, [int]$y, [string]$ch, [int]$size = 3) {
    for ($dx = 0; $dx -lt $size; $dx++) { for ($dy = 0; $dy -lt $size; $dy++) { Put $rows ($x + $dx) ($y + $dy) $ch } }
}

# The side view with no arm, padded, standing with feet apart.
function New-SideBody([string]$who, [bool]$wide) {
    $upper = [string[]]$sideUpper[$who].Clone()
    $first = $poseStyle[$who]['arm_rows']
    for ($y = $first; $y -lt $upper.Count; $y++) {
        $c = $upper[$y].ToCharArray()
        for ($x = 11; $x -le 13; $x++) { $c[$x] = $c[10] }
        $upper[$y] = -join $c
    }
    $legs = $sideLegs[$who]
    $rows = $upper + (Get-Legs $legs[0] $legs[1] $wide)
    $edge = '.' * $PAD
    return [string[]]($rows | ForEach-Object { $edge + $_ + $edge })
}

# The eye, shut tight (hurt) or X'd out (knocked out). The eye is the first dark
# pixel on the face, near the front of the head.
function Mark-Eye([string[]]$rows, [string]$who, [string]$how) {
    $skin = if ($who -eq 'elric') { 'L' } else { 'N' }
    for ($y = 5; $y -le 8; $y++) {
        for ($x = 12 + $PAD; $x -le 16 + $PAD; $x++) {
            if ($rows[$y][$x] -eq 'K') {
                # Clear around it, then draw the mark.
                for ($yy = $y - 1; $yy -le $y + 1; $yy++) { for ($xx = $x - 1; $xx -le $x + 1; $xx++) { if ($rows[$yy][$xx] -ne '.') { Put $rows $xx $yy $skin } } }
                if ($how -eq 'x') {
                    Put $rows ($x - 1) ($y - 1) 'K'; Put $rows ($x + 1) ($y - 1) 'K'; Put $rows $x $y 'K'
                    Put $rows ($x - 1) ($y + 1) 'K'; Put $rows ($x + 1) ($y + 1) 'K'
                } else {
                    Put $rows ($x - 1) ($y - 1) 'K'; Put $rows $x $y 'K'; Put $rows ($x - 1) ($y + 1) 'K'
                }
                return
            }
        }
    }
}

$poses = [ordered]@{}
foreach ($who in $poseStyle.Keys) {
    $s = $poseStyle[$who]
    $sleeve = $s['sleeve']; $hand = $s['hand']; $claw = $s['claw']
    # Shoulders: the back one (behind the body) and the front one, in canvas pixels.
    $backX = 15 + $PAD; $frontX = 17 + $PAD; $sy = 13

    if ($who -eq 'hop') {
        # STANCE: fists up. Rear fist guarding the chin, lead fist out in front.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($backX + 1) 17 $sleeve; Draw-Limb $p ($backX + 1) 17 ($frontX + 1) 11 $sleeve
        Draw-Hand $p ($frontX + 1) 9 $hand
        Draw-Limb $p $frontX $sy ($frontX + 4) 16 $sleeve; Draw-Limb $p ($frontX + 4) 16 ($frontX + 7) 11 $sleeve
        Draw-Hand $p ($frontX + 7) 9 $hand
        $poses["hop_stance"] = $p

        # WINDUP: the rear fist cocked way back behind his head, lead fist still up.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($backX - 4) 15 $sleeve; Draw-Limb $p ($backX - 4) 15 ($backX - 6) 9 $sleeve
        Draw-Hand $p ($backX - 8) 7 $hand 4
        Draw-Limb $p $frontX $sy ($frontX + 4) 16 $sleeve; Draw-Limb $p ($frontX + 4) 16 ($frontX + 6) 11 $sleeve
        Draw-Hand $p ($frontX + 6) 9 $hand
        $poses["hop_windup"] = $p

        # STRIKE: a straight punch, arm locked out, big wrapped fist.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($backX + 1) 17 $sleeve; Draw-Limb $p ($backX + 1) 17 ($frontX + 1) 11 $sleeve
        Draw-Hand $p ($frontX + 1) 9 $hand
        Draw-Limb $p $frontX $sy ($frontX + 11) 12 $sleeve
        Draw-Hand $p ($frontX + 11) 10 $hand 4
        Put $p ($frontX + 14) 11 'K'; Put $p ($frontX + 14) 13 'K'
        $poses["hop_strike"] = $p

        # GUARD: both forearms up in front of his face, fists high.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($frontX + 2) 16 $sleeve; Draw-Limb $p ($frontX + 2) 16 ($frontX + 3) 7 $sleeve
        Draw-Limb $p $frontX $sy ($frontX + 4) 15 $sleeve; Draw-Limb $p ($frontX + 4) 15 ($frontX + 5) 8 $sleeve
        Draw-Hand $p ($frontX + 2) 5 $hand; Draw-Hand $p ($frontX + 4) 6 $hand
        $poses["hop_guard"] = $p
    } else {
        # STANCE: low and loose. Lead hand open, reaching forward with claws out;
        # rear hand down by the hip.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($backX - 1) 17 $sleeve; Draw-Limb $p ($backX - 1) 17 ($backX - 3) 20 $sleeve
        Draw-Hand $p ($backX - 4) 20 $hand 2
        Put $p ($backX - 5) 22 $claw
        Draw-Limb $p $frontX $sy ($frontX + 4) 16 $sleeve; Draw-Limb $p ($frontX + 4) 16 ($frontX + 8) 14 $sleeve
        Draw-Hand $p ($frontX + 8) 13 $hand 2
        Put $p ($frontX + 10) 12 $claw; Put $p ($frontX + 10) 14 $claw; Put $p ($frontX + 10) 16 $claw
        $poses["elric_stance"] = $p

        # WINDUP: the lead arm pulled up and back over the head, claws high.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($backX - 1) 17 $sleeve; Draw-Limb $p ($backX - 1) 17 ($backX - 3) 20 $sleeve
        Draw-Hand $p ($backX - 4) 20 $hand 2
        Draw-Limb $p $frontX $sy ($frontX - 1) 8 $sleeve; Draw-Limb $p ($frontX - 1) 8 ($frontX - 4) 4 $sleeve
        Draw-Hand $p ($frontX - 5) 2 $hand 2
        Put $p ($frontX - 6) 0 $claw; Put $p ($frontX - 4) 0 $claw; Put $p ($frontX - 2) 1 $claw
        $poses["elric_windup"] = $p

        # STRIKE: a big downward swipe, arm swung all the way through, claws raking.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($backX - 2) 16 $sleeve; Draw-Limb $p ($backX - 2) 16 ($backX - 5) 14 $sleeve
        Draw-Hand $p ($backX - 6) 13 $hand 2
        Draw-Limb $p $frontX $sy ($frontX + 10) 18 $sleeve
        Draw-Hand $p ($frontX + 10) 18 $hand 2
        Put $p ($frontX + 12) 17 $claw; Put $p ($frontX + 13) 18 $claw; Put $p ($frontX + 12) 20 $claw; Put $p ($frontX + 13) 21 $claw
        $poses["elric_strike"] = $p

        # GUARD: forearms crossed in front of the face.
        $p = [string[]](New-SideBody $who $true)
        Draw-Limb $p $backX $sy ($frontX + 4) 8 $sleeve
        Draw-Limb $p $frontX $sy ($frontX + 1) 17 $sleeve; Draw-Limb $p ($frontX + 1) 17 ($frontX + 5) 9 $sleeve
        Draw-Hand $p ($frontX + 4) 6 $hand 2; Draw-Hand $p ($frontX + 5) 8 $hand 2
        $poses["elric_guard"] = $p
    }

    # RAISE (ACT / ITEM / MERCY): the lead arm straight up, the other relaxed.
    $p = [string[]](New-SideBody $who $false)
    Draw-Limb $p $backX $sy $backX 20 $sleeve
    Draw-Hand $p $backX 20 $hand 2
    Draw-Limb $p $frontX $sy ($frontX + 2) 3 $sleeve
    Draw-Hand $p ($frontX + 1) 1 $hand 3
    $poses["${who}_raise"] = $p

    # HURT: knocked back, arms flung behind, eye squeezed shut.
    $p = [string[]](New-SideBody $who $true)
    Draw-Limb $p $backX $sy ($backX - 5) 10 $sleeve
    Draw-Hand $p ($backX - 7) 8 $hand 2
    Draw-Limb $p $frontX $sy ($frontX - 4) 8 $sleeve
    Draw-Hand $p ($frontX - 6) 6 $hand 2
    Mark-Eye $p $who 'shut'
    $poses["${who}_hurt"] = $p

    # KO: arms hanging limp, eye X'd out (the game tips this one over).
    $p = [string[]](New-SideBody $who $false)
    Draw-Limb $p $backX $sy ($backX + 1) 21 $sleeve
    Draw-Limb $p $frontX $sy ($frontX + 1) 21 $sleeve
    Mark-Eye $p $who 'x'
    $poses["${who}_ko"] = $p
}

# --- Saving -------------------------------------------------------------------

function Save-Sprite([string]$name, [string[]]$rows, [string]$dir) {
    $w = $rows[0].Length
    $h = $rows.Count
    foreach ($row in $rows) {
        if ($row.Length -ne $w) { throw "$name has a row that isn't $w wide: '$row'" }
    }

    # One pixel of padding on every side leaves room for the outline.
    $bmp = New-Object System.Drawing.Bitmap ($w + 2), ($h + 2), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $filled = New-Object 'bool[,]' ($w + 2), ($h + 2)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $ch = [string]$rows[$y][$x]
            if ($ch -eq '.') { continue }
            if (-not $palette.ContainsKey($ch)) { throw "$name uses '$ch', which isn't in the palette" }
            $c = $palette[$ch]
            # Shading, lit from the top-left: pixels on a bottom or right edge are
            # darker, pixels on a top or left edge are lighter, and where two colors
            # meet (a sleeve and a hand, say) there's a soft crease.
            $isEmpty = { param($xx, $yy) $xx -lt 0 -or $yy -lt 0 -or $xx -ge $w -or $yy -ge $h -or [string]$rows[$yy][$xx] -eq '.' }
            $shade = 1.0
            if ((& $isEmpty ($x + 1) $y) -or (& $isEmpty $x ($y + 1))) { $shade = 0.76 }
            elseif ((& $isEmpty ($x - 1) $y) -or (& $isEmpty $x ($y - 1))) { $shade = 1.16 }
            elseif ([string]$rows[$y][$x + 1] -ne $ch -or [string]$rows[$y + 1][$x] -ne $ch) { $shade = 0.9 }
            $c = @([math]::Min(255, [int]($c[0] * $shade)), [math]::Min(255, [int]($c[1] * $shade)), [math]::Min(255, [int]($c[2] * $shade)))
            $bmp.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb(255, $c[0], $c[1], $c[2]))
            $filled[($x + 1), ($y + 1)] = $true
        }
    }

    # Outline: every empty pixel touching a filled one (up, down, left or right).
    for ($y = 0; $y -lt $h + 2; $y++) {
        for ($x = 0; $x -lt $w + 2; $x++) {
            if ($filled[$x, $y]) { continue }
            $touching = ($x -gt 0 -and $filled[($x - 1), $y]) -or ($x -lt $w + 1 -and $filled[($x + 1), $y]) -or
                        ($y -gt 0 -and $filled[$x, ($y - 1)]) -or ($y -lt $h + 1 -and $filled[$x, ($y + 1)])
            if ($touching) {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $outline[0], $outline[1], $outline[2]))
            }
        }
    }

    $path = Join-Path $dir "$name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved $path"
}

$spriteDir = Join-Path $PSScriptRoot "..\art\sprites"
$portraitDir = Join-Path $PSScriptRoot "..\art\portraits"
New-Item -ItemType Directory -Force $spriteDir | Out-Null
New-Item -ItemType Directory -Force $portraitDir | Out-Null

foreach ($name in $sprites.Keys) { Save-Sprite $name $sprites[$name] $spriteDir }
foreach ($name in $portraits.Keys) { Save-Sprite $name $portraits[$name] $portraitDir }
$battleDir = Join-Path $spriteDir "battle"
New-Item -ItemType Directory -Force $battleDir | Out-Null
foreach ($name in $poses.Keys) { Save-Sprite $name $poses[$name] $battleDir }
foreach ($name in $walkFrames.Keys) { Save-Sprite $name $walkFrames[$name] $spriteDir }
