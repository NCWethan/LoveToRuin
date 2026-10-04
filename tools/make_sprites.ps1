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
$outline = @(125, 125, 140)

$sprites = @{
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
