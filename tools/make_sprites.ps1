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
        "........................",
        ".........bbbbbb.........",
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
        "...YYYYVVVSSSSVVVYYYY...",
        "...YYYHVVVSSSSVVVHYYY...",
        "...YYYYVVVVSSVVVVYYYY...",
        "...YYYYVVVVSSVVVVYYYY...",
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
        "........................",
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
        ".......HHVVYYYVV........",
        ".........VVYYYVS........",
        ".........VVYYYVS........",
        ".........VVYYYVS........",
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

$outDir = Join-Path $PSScriptRoot "..\art\sprites"
New-Item -ItemType Directory -Force $outDir | Out-Null

foreach ($name in $sprites.Keys) {
    $rows = $sprites[$name]
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

    $path = Join-Path $outDir "$name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved $path"
}
