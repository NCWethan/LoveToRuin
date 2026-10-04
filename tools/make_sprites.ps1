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

foreach ($who in $sideUpper.Keys) {
    $legs = $sideLegs[$who]
    $sprites["${who}_side"] = $sideUpper[$who] + (Get-Legs $legs[0] $legs[1] $false)
    $sprites["${who}_side2"] = $sideUpper[$who] + (Get-Legs $legs[0] $legs[1] $true)
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
