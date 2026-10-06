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
# Genocide (Elric getting worse)
$palette['+'] = @(182, 160, 212)   # paler skin
$palette['?'] = @(158, 146, 172)   # grayer skin
$palette['&'] = @(124, 116, 134)   # dead-gray skin
$palette['='] = @(92, 72, 108)     # dark circles
$palette['!'] = @(108, 18, 26)     # blood stains
$palette['<'] = @(24, 8, 12)       # black tears
$palette[';'] = @(86, 62, 40)      # darkened tunic
$palette[','] = @(58, 58, 40)      # darkened pants
$palette['/'] = @(70, 44, 26)      # dark, greasy hair
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
    ".........KKyyKK.........",
    "........KKKyyKKK........",
    ".......KKKKyyKKKK.......",
    ".......DKKKKKKKKD.......",
    ".......KKKKKKKKKK.......",
    ".....AAAAAAAAAAAAAA.....",
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

# A training dummy for the Corps' bunker: a straw body on a post, with a target
# painted on its chest and button eyes.
$sprites['training_dummy'] = @(
    "........................",
    "..........eeee..........",
    ".........eeeeee.........",
    ".........eKeeKe.........",
    ".........eeeeee.........",
    ".........eeKKee.........",
    "..........eeee..........",
    "...........hh...........",
    "....eeeeeeeeeeeeeeee....",
    "....eeeeeeeeeeeeeeee....",
    "......eeeeeeeeeeee......",
    "......eeeWWWWWWeee......",
    "......eeWRRRRRRWee......",
    "......eeWRWWWWRWee......",
    "......eeWRWRRWRWee......",
    "......eeWRWRRWRWee......",
    "......eeWRWWWWRWee......",
    "......eeWRRRRRRWee......",
    "......eeeWWWWWWeee......",
    "......eeeeeeeeeeee......",
    ".......rrrrrrrrrr.......",
    "...........hh...........",
    "...........hh...........",
    "...........hh...........",
    "...........hh...........",
    "...........hh...........",
    "...........hh...........",
    "...........hh...........",
    "...........hh...........",
    ".........hhhhhh.........",
    "........DDDDDDDD........",
    "........DDDDDDDD........"
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

# --- Westview students (Chapter 2: the school by day) ----------------------------
# Made from Elric's body (front and back), recolored: skin, hair, shirt, pants,
# and a beanie on some. They get walking frames like everyone else.
# skin, hair, shirt, shirt detail, pants, pants line, beanie (or '')
$studentLooks = @(
    @('Q', 'K', 'S', 'u', 'J', 'j', ''),
    @('4', 'K', 'E', 'D', 'P', 'k', ''),
    @('2', 'H', '5', 'D', 'B', 'n', ''),
    @('Y', 'h', '#', 'D', 'J', 'j', 'b'),
    @('Q', 'w', 'R', 'D', 'x', 'k', ''),
    @('4', '8', '1', 'D', 'J', 'j', 'u'),
    @('2', 'K', 'W', 'a', 'P', 'k', ''),
    @('Q', 'H', 'E', 'D', 'B', 'n', 'R')
)

function Recolor-Student([string[]]$rows, $look) {
    $out = @()
    for ($y = 0; $y -lt $rows.Count; $y++) {
        $c = $rows[$y].ToCharArray()
        for ($x = 0; $x -lt $c.Length; $x++) {
            switch -CaseSensitive ([string]$c[$x]) {
                'L' { $c[$x] = $look[0] }
                'h' { $c[$x] = if ($look[6] -ne '' -and $y -le 4) { $look[6] } else { $look[1] } }
                'T' { $c[$x] = $look[2] }
                # Elric's patches and dirt just become plain shirt (or pants).
                't' { $c[$x] = if ($y -ge 22) { $look[4] } else { $look[2] } }
                'd' { $c[$x] = if ($y -ge 22) { $look[4] } else { $look[2] } }
                'r' { $c[$x] = $look[3] }
                'O' { $c[$x] = $look[4] }
                'o' { $c[$x] = $look[5] }
            }
        }
        $out += -join $c
    }
    return [string[]]$out
}

for ($s = 0; $s -lt $studentLooks.Count; $s++) {
    $n = $s + 1
    $sprites["student$n"] = Recolor-Student $sprites['elric'] $studentLooks[$s]
    $sprites["student${n}_back"] = Recolor-Student $sprites['elric_back'] $studentLooks[$s]
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
# Built from each character's front view by moving the arm pixels around. The
# canvas is 6 pixels wider on each side, so an outstretched arm fits. Poses:
#   windup  the right arm drawn back and up, ready to strike
#   strike  the right arm thrown straight out toward the enemy
#   guard   both arms crossed over the chest
#   raise   the right arm held straight up (ACT, ITEM, MERCY)
#   hurt    a shocked face, arms flung out
#   ko      X'd-out eyes (the game tips this one over)

$poseSkin = @{ 'elric' = 'L'; 'hop' = 'N' }
$PAD = 6

function Pad-Rows([string[]]$rows) {
    $edge = '.' * $PAD
    return [string[]]($rows | ForEach-Object { $edge + $_ + $edge })
}

# A character's right arm (below the shoulder), top to bottom: 7 rows of 4 pixels.
function Get-Arm([string[]]$rows, [bool]$right) {
    $x = if ($right) { 18 + $PAD } else { 2 + $PAD }
    $arm = @()
    for ($y = 15; $y -le 21; $y++) { $arm += $rows[$y].Substring($x, 4) }
    return $arm
}

function Clear-Arm([string[]]$rows, [bool]$right) {
    $x = if ($right) { 18 + $PAD } else { 2 + $PAD }
    for ($y = 15; $y -le 21; $y++) {
        $c = $rows[$y].ToCharArray()
        for ($i = 0; $i -lt 4; $i++) { $c[$x + $i] = '.' }
        $rows[$y] = -join $c
    }
}

function Put([string[]]$rows, [int]$x, [int]$y, [string]$ch) {
    if ($y -lt 0 -or $y -ge $rows.Count -or $x -lt 0 -or $x -ge $rows[0].Length -or $ch -eq '.') { return }
    $c = $rows[$y].ToCharArray()
    $c[$x] = $ch
    $rows[$y] = -join $c
}

# Draws an arm (7 x 4, shoulder end first) from (x, y), stepping (dx, dy) per pixel
# of length; the arm's width runs along (wx, wy).
function Draw-Arm([string[]]$rows, [string[]]$arm, [int]$x, [int]$y, [double]$dx, [double]$dy, [int]$wx, [int]$wy) {
    for ($k = 0; $k -lt $arm.Count; $k++) {
        for ($w = 0; $w -lt 4; $w++) {
            $px = [int][math]::Round($x + $k * $dx + $w * $wx)
            $py = [int][math]::Round($y + $k * $dy + $w * $wy)
            Put $rows $px $py ([string]$arm[$k][$w])
        }
    }
}

function Stamp-Face([string[]]$rows, [string[]]$stamp, [string]$skin, [string]$feature) {
    for ($r = 0; $r -lt $stamp.Count; $r++) {
        $c = $rows[6 + $r].ToCharArray()
        for ($k = 0; $k -lt 8; $k++) {
            $s = $stamp[$r][$k]
            if ($s -eq '.') { continue }
            $c[$PAD + 8 + $k] = switch ($s) { 's' { $skin } 'K' { $feature } default { $s } }
        }
        $rows[6 + $r] = -join $c
    }
}

$koFace = @(
    "........",
    ".KsKKsK.",
    "..Kss.K.",
    ".KsKKsK.",
    "........",
    ".sKKKKs."
)

$poses = [ordered]@{}
foreach ($who in $poseSkin.Keys) {
    $base = Pad-Rows $sprites[$who]
    $skin = $poseSkin[$who]
    $arm = Get-Arm $base $true
    $leftArm = Get-Arm $base $false
    $shoulderX = 18 + $PAD

    # Windup: the arm swings up and back over the shoulder, hand high.
    $p = [string[]]$base.Clone()
    Clear-Arm $p $true
    Draw-Arm $p $arm ($shoulderX) 14 0.7 -1.0 1 0
    if ($who -eq 'elric') {
        # Nails catching the light.
        Put $p ($shoulderX + 5) 6 'W'; Put $p ($shoulderX + 7) 6 'W'; Put $p ($shoulderX + 8) 7 'W'
    }
    $poses["${who}_windup"] = $p

    # Strike: the arm thrown straight out to the right.
    $p = [string[]]$base.Clone()
    Clear-Arm $p $true
    Draw-Arm $p $arm ($shoulderX) 14 1 0 0 1
    $tip = $shoulderX + $arm.Count
    if ($who -eq 'elric') {
        # Three claws.
        Put $p $tip 14 'W'; Put $p ($tip + 1) 14 'W'
        Put $p $tip 16 'W'; Put $p ($tip + 1) 16 'W'
        Put $p $tip 18 'W'
    } else {
        # A big fist with knuckles.
        for ($yy = 13; $yy -le 18; $yy++) { Put $p $tip $yy 'l'; Put $p ($tip + 1) $yy 'l' }
        Put $p ($tip + 1) 14 'K'; Put $p ($tip + 1) 16 'K'
    }
    $poses["${who}_strike"] = $p

    # Guard: both arms folded across the chest.
    $p = [string[]]$base.Clone()
    Clear-Arm $p $true
    Clear-Arm $p $false
    Draw-Arm $p $leftArm (2 + $PAD) 15 1.3 0.35 0 1
    Draw-Arm $p $arm ($shoulderX + 3) 17 -1.3 0.35 0 1
    $poses["${who}_guard"] = $p

    # Raise: the arm straight up, hand above the head.
    $p = [string[]]$base.Clone()
    Clear-Arm $p $true
    Draw-Arm $p $arm ($shoulderX) 14 0 -1.4 1 0
    $poses["${who}_raise"] = $p

    # Hurt: a shocked face, and both arms flung outward.
    $p = [string[]]$base.Clone()
    Clear-Arm $p $true
    Clear-Arm $p $false
    Draw-Arm $p $arm ($shoulderX) 14 0.75 0.7 1 0
    Draw-Arm $p $leftArm (5 + $PAD) 14 -0.75 0.7 -1 0
    Stamp-Face $p $moods['shocked'] $skin 'K'
    $poses["${who}_hurt"] = $p

    # Knocked out: X'd-out eyes.
    $p = [string[]]$base.Clone()
    Stamp-Face $p $koFace $skin 'K'
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

# --- Running frames (Elric and Hop, for sprinting) -----------------------------
# Front/back: a bigger step than walking (the foot lifts two pixels, the arms pump
# two). Side: the body leans forward a pixel, with a long stride (front leg reaching,
# back leg kicked up behind) on two frames and a knee-up "passing" frame between.
# Saved as name_run1/2, name_back_run1/2 and name_side_run1/2/3.

function Make-Run([string[]]$rows, [bool]$leftLeg) {
    $p = [string[]]$rows.Clone()
    if ($leftLeg) { Shift-Block $p 7 11 22 31 -2 } else { Shift-Block $p 13 16 22 31 -2 }
    if ($leftLeg) { Shift-Block $p 2 5 15 21 2; Shift-Block $p 18 21 15 21 -2 }
    else { Shift-Block $p 2 5 15 21 -2; Shift-Block $p 18 21 15 21 2 }
    return $p
}

# 1 = trousers, 2 = shoes.
$runStride = @(
    "..........11111.........",
    ".........1111.111.......",
    "........1111...111......",
    "...221111.......111.....",
    "...2211..........111....",
    "..................111...",
    "..................111...",
    "...................111..",
    "..................22222.",
    "..................22222."
)
$runPass = @(
    "..........11111.........",
    "..........11111111......",
    "..........111..111......",
    "..........111..111......",
    "..........111..222......",
    "..........111...........",
    "..........111...........",
    "..........111...........",
    "..........2222..........",
    "..........2222.........."
)

function Get-RunLegs([string[]]$template, [string]$c, [string]$shoe) {
    $out = @()
    foreach ($row in $template) { $out += $row.Replace('1', $c).Replace('2', $shoe) }
    return $out
}

# Leans the upper body (everything above the legs) one pixel forward.
function Lean([string[]]$rows, [int]$upperCount) {
    $out = [string[]]$rows.Clone()
    for ($y = 0; $y -lt $upperCount; $y++) { $out[$y] = "." + $out[$y].Substring(0, $out[$y].Length - 1) }
    return $out
}

$runFrames = [ordered]@{}
foreach ($name in @('elric', 'elric_back', 'hop', 'hop_back')) {
    if (-not $sprites.Contains($name)) { continue }
    $runFrames["${name}_run1"] = Make-Run $sprites[$name] $true
    $runFrames["${name}_run2"] = Make-Run $sprites[$name] $false
}
foreach ($who in $sideUpper.Keys) {
    $legs = $sideLegs[$who]
    $upper = [string[]]$sideUpper[$who]
    $stride = [string[]]($upper + (Get-RunLegs $runStride $legs[0] $legs[1]))
    $pass = [string[]]($upper + (Get-RunLegs $runPass $legs[0] $legs[1]))
    $runFrames["${who}_side_run1"] = Lean ([string[]](Swing-Arm $stride -1)) $upper.Count
    $runFrames["${who}_side_run2"] = Lean ([string[]](Swing-Arm $stride 1)) $upper.Count
    $runFrames["${who}_side_run3"] = Lean $pass $upper.Count
}

# --- Genocide: Elric, getting worse -------------------------------------------
# The more Elric kills, the more horrid they look (see Game.dread()). Every Elric
# picture (overworld, walking, running, battle poses, portraits) gets three
# worse versions, saved with "elric" changed to "elric_dread1/2/3":
#   1  paler skin, dark circles under the eyes
#   2  grayer skin, glowing red eyes, blood stains on the clothes
#   3  dead-gray skin, black tears, a wide toothy grin, more blood, darker
#      clothes and hair
$dreadSkin = @{ 1 = '+'; 2 = '?'; 3 = '&' }
$stains2 = @(@(13, 9), @(16, 14), @(19, 7), @(24, 9))
$stains3 = $stains2 + @(@(12, 15), @(14, 5), @(17, 11), @(18, 16), @(21, 13), @(26, 14), @(27, 8), @(15, 18), @(23, 12))
$clothes = 'Tdtro;,'

function Set-Pixel([string[]]$rows, [int]$y, [int]$x, [string]$ch) {
    if ($y -lt 0 -or $y -ge $rows.Count -or $x -lt 0 -or $x -ge $rows[$y].Length) { return }
    $c = $rows[$y].ToCharArray(); $c[$x] = $ch; $rows[$y] = -join $c
}
function Get-Pixel([string[]]$rows, [int]$y, [int]$x) {
    if ($y -lt 0 -or $y -ge $rows.Count -or $x -lt 0 -or $x -ge $rows[$y].Length) { return '.' }
    return [string]$rows[$y][$x]
}

function Dread-Rows([string[]]$rows, [int]$stage) {
    $p = [string[]]$rows.Clone()
    $xoff = [int](($p[0].Length - 24) / 2)
    $skin = $dreadSkin[$stage]
    # Find the eyes (black pixels in the face) before the skin changes.
    $eyes = @()
    for ($y = 6; $y -le 8; $y++) {
        for ($x = 8 + $xoff; $x -le 15 + $xoff; $x++) {
            if ((Get-Pixel $p $y $x) -eq 'K' -and ((Get-Pixel $p $y ($x - 1)) -eq 'L' -or (Get-Pixel $p $y ($x + 1)) -eq 'L')) { $eyes += , @($y, $x) }
        }
    }
    # A wide black mouth with teeth (front views only, where the mouth is two black pixels).
    $grin = $stage -ge 3 -and (Get-Pixel $p 9 (11 + $xoff)) -eq 'K' -and (Get-Pixel $p 9 (12 + $xoff)) -eq 'K'
    for ($y = 0; $y -lt $p.Count; $y++) {
        $c = $p[$y].ToCharArray()
        for ($x = 0; $x -lt $c.Length; $x++) {
            switch -CaseSensitive ([string]$c[$x]) {
                'L' { $c[$x] = $skin }
                'T' { if ($stage -ge 3) { $c[$x] = ';' } }
                'O' { if ($stage -ge 3) { $c[$x] = ',' } }
                'h' { if ($stage -ge 3) { $c[$x] = '/' } }
            }
        }
        $p[$y] = -join $c
    }
    foreach ($eye in $eyes) {
        $y = $eye[0]; $x = $eye[1]
        if ($stage -ge 2) { Set-Pixel $p $y $x 'I' }
        if ((Get-Pixel $p ($y + 1) $x) -eq $skin) { Set-Pixel $p ($y + 1) $x '=' }
        if ($stage -ge 3) {
            for ($k = 1; $k -le 3; $k++) { if ((Get-Pixel $p ($y + $k) $x) -in @($skin, '=')) { Set-Pixel $p ($y + $k) $x '<' } }
        }
    }
    if ($grin) {
        Set-Pixel $p 9 (10 + $xoff) 'K'; Set-Pixel $p 9 (13 + $xoff) 'K'
        Set-Pixel $p 9 (11 + $xoff) 'W'; Set-Pixel $p 9 (12 + $xoff) 'W'
        Set-Pixel $p 10 (11 + $xoff) 'K'; Set-Pixel $p 10 (12 + $xoff) 'K'
    }
    $stains = if ($stage -ge 3) { $stains3 } elseif ($stage -ge 2) { $stains2 } else { @() }
    foreach ($s in $stains) {
        if ($clothes.Contains((Get-Pixel $p $s[0] ($s[1] + $xoff)))) { Set-Pixel $p $s[0] ($s[1] + $xoff) '!' }
    }
    return $p
}

$dreadSprites = [ordered]@{}
$dreadPortraits = [ordered]@{}
$dreadPoses = [ordered]@{}
foreach ($stage in 1..3) {
    foreach ($set in @(@($sprites, $dreadSprites), @($walkFrames, $dreadSprites), @($runFrames, $dreadSprites), @($portraits, $dreadPortraits), @($poses, $dreadPoses))) {
        $from = $set[0]; $to = $set[1]
        foreach ($name in @($from.Keys)) {
            if (-not $name.StartsWith('elric')) { continue }
            $to["elric_dread$stage" + $name.Substring(5)] = Dread-Rows $from[$name] $stage
        }
    }
}

# --- Ronin's electric guitar and amp ------------------------------------------
# Based on Ronin's real guitar: a black superstrat with a quilted top, white
# binding, a black fretboard with white shark-fin inlays, two black humbuckers,
# and a pointy black headstock with a white logo stripe. Drawn lying sideways,
# headstock on the left. Plus a little black combo amp.

function New-Canvas([int]$w, [int]$h) {
    $rows = @()
    for ($y = 0; $y -lt $h; $y++) { $rows += ('.' * $w) }
    return [string[]]$rows
}

$g = [string[]](New-Canvas 42 15)
# The body: a rounded slab with two horns reaching toward the neck.
for ($y = 0; $y -lt 15; $y++) {
    for ($x = 22; $x -lt 42; $x++) {
        $dx = ($x - 32.5) / 8.2; $dy = ($y - 7.0) / 7.2
        if ($dx * $dx + $dy * $dy -le 1.0) { Set-Pixel $g $y $x 'K' }
    }
}
foreach ($y in 1..3) { foreach ($x in (24 - $y)..26) { Set-Pixel $g $y $x 'K' } }
foreach ($y in 11..13) { foreach ($x in (22 + ($y - 11))..26) { Set-Pixel $g $y $x 'K' } }
# The quilted top: dark gray swirls in the black.
foreach ($spot in @(@(3, 28), @(4, 33), @(5, 30), @(9, 29), @(10, 34), @(11, 31), @(4, 37), @(10, 38), @(7, 39), @(12, 35))) {
    Set-Pixel $g $spot[0] $spot[1] '7'; Set-Pixel $g $spot[0] ($spot[1] + 1) '7'
}
# The neck: white binding top and bottom, a dark fretboard, white shark fins.
foreach ($x in 6..25) { Set-Pixel $g 5 $x 'W'; Set-Pixel $g 6 $x 'C'; Set-Pixel $g 7 $x 'C'; Set-Pixel $g 8 $x 'C'; Set-Pixel $g 9 $x 'W' }
foreach ($x in @(9, 13, 17, 21)) { Set-Pixel $g 8 $x 'W'; Set-Pixel $g 8 ($x + 1) 'W'; Set-Pixel $g 7 ($x + 1) 'W' }
# The pointy headstock, with tuners along the top and the white logo stripe.
foreach ($x in 0..5) { Set-Pixel $g 7 $x 'K' }
foreach ($x in 1..5) { Set-Pixel $g 6 $x 'K'; Set-Pixel $g 8 $x 'K' }
foreach ($x in 3..5) { Set-Pixel $g 5 $x 'K'; Set-Pixel $g 9 $x 'K' }
foreach ($x in 2..5) { Set-Pixel $g 7 $x 'W' }
foreach ($x in @(1, 3, 5)) { Set-Pixel $g 4 $x 'K' }
# Two humbuckers with silver pole pieces, the bridge, and the knobs.
foreach ($px in @(28, 32)) { foreach ($y in 5..9) { Set-Pixel $g $y $px 'K'; Set-Pixel $g $y ($px + 1) 'K' }; foreach ($y in @(6, 8)) { Set-Pixel $g $y $px 'G' } }
foreach ($y in 5..9) { Set-Pixel $g $y 35 'G' }
Set-Pixel $g 11 37 'G'; Set-Pixel $g 12 39 'G'
$sprites['ronin_guitar'] = $g

$a = [string[]](New-Canvas 20 18)
foreach ($y in 0..17) { foreach ($x in 0..19) { Set-Pixel $a $y $x 'K' } }
# Control panel with knobs, and a little red power light.
foreach ($x in 1..18) { Set-Pixel $a 1 $x 'D'; Set-Pixel $a 2 $x 'D' }
foreach ($x in @(3, 6, 9, 12, 15)) { Set-Pixel $a 1 $x 'G'; Set-Pixel $a 2 $x 'G' }
Set-Pixel $a 2 17 'R'
# The grille: crosshatched cloth, with a logo plate.
foreach ($y in 4..16) { foreach ($x in 1..18) { Set-Pixel $a $y $x $(if ((($x + $y) % 2) -eq 0) { 'C' } else { '7' }) } }
foreach ($x in 3..8) { Set-Pixel $a 5 $x 'W' }
$sprites['amp'] = $a

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
foreach ($name in $runFrames.Keys) { Save-Sprite $name $runFrames[$name] $spriteDir }
foreach ($name in $dreadSprites.Keys) { Save-Sprite $name $dreadSprites[$name] $spriteDir }
foreach ($name in $dreadPortraits.Keys) { Save-Sprite $name $dreadPortraits[$name] $portraitDir }
foreach ($name in $dreadPoses.Keys) { Save-Sprite $name $dreadPoses[$name] $battleDir }
