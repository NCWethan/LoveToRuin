# LOVE TO RUIN

A Deltarune/Undertale-style RPG made with [Godot](https://godotengine.org/).

*LOVE TO RUIN* is an anagram of *REVOLUTION*.

## Status

**Chapter 1 is playable from start to finish:** Mt. Carmel High School (meet Hop, fragment 1, the tutorial fight), the PQ Mall hub, Westview High School after dark (fragment 2 and Wally Wolverine), and Hilltop Park (fragment 3, Hopkuna, the REVOLUTION Corps, and the route choice: Pacifist, Neutral or Genocide).

See [DESIGN.md](DESIGN.md) for the story, cast and build plan.

## Controls

| Key | Action |
|---|---|
| Arrow keys | Move the SOUL / move through menus |
| Enter | Confirm |
| X or Shift | Go back |
| B | Open your bag (use, check or drop items, and Settings at the bottom) |

## Saving and settings

The game saves at the glowing **SAVE stars**. Choose **Continue** on the title screen to pick up from your last save.

**Settings** (music volume, sound volume, text speed, fullscreen) are on the title screen and at the bottom of the bag.

## Building the .exe

With Godot's export templates installed (Editor > Manage Export Templates), run:

    Godot --headless --export-release "Windows Desktop"

The game is written to `build/LOVE TO RUIN.exe`, a single file you can share.

## Running it

Open the project in [Godot 4](https://godotengine.org/) and press **F5** to play from the title screen.
To test just the battle, open `battle.tscn` and press **F6**.
