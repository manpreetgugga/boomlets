# Boomlets

Pop pods. Blast crates. Outsmart the critters!

Boomlets is a cozy 3D arena game for Android. Help Pip clear five floating worlds: drop fizzy pods, break crates, grab power-ups and pop every critter to open the exit.

**[Download the latest APK](https://github.com/manpreetgugga/boomlets/releases/latest)** (Android 7+, arm64)

<p>
  <img src="shots/menu.png" width="160" alt="Main menu">
  <img src="shots/map.png" width="160" alt="World map">
  <img src="shots/world_1.png" width="160" alt="Meadow Isles">
  <img src="shots/world_2.png" width="160" alt="Candy Coast">
</p>
<p>
  <img src="shots/world_3.png" width="160" alt="Cocoa Canyon">
  <img src="shots/world_4.png" width="160" alt="Frost Peaks">
  <img src="shots/world_5.png" width="160" alt="Neon Nightway">
</p>

## How to play

- **Walk:** tap a tile and Pip walks there.
- **Drop a pod:** double-tap anywhere.
- Pods pop after 2.5 seconds and blast in a plus shape. Blasts set off other pods.
- Pop every critter to open the exit pad, then walk onto it.
- Finish quickly for 3 stars.

### Power-ups (from broken crates)

| Power-up | Effect |
|---|---|
| Pod | Carry one more pod |
| Fire | Longer blasts |
| Speed | Move faster |
| Kick | Walk into a pod to send it sliding |
| Shield | Blocks one hit |
| Heart | Extra life |

## Worlds

Each world has its own look, music, twist, critter and boss, across six levels. Beat a world's boss to open the next one. There are 90 stars in all.

| # | World | Twist | New critter | Boss |
|---|---|---|---|---|
| 1 | Meadow Isles | Conveyor belts, fizz barrels, warp pads | Buzzers and Wisps | Thornback |
| 2 | Candy Coast | Tide pools that flood and drain | Crabs that walk sideways | Captain Clawdia |
| 3 | Cocoa Canyon | Sticky mud and tiles that crumble into pits | Moles that tunnel | Baron Burrow |
| 4 | Frost Peaks | Slippery ice and frozen crates that take two blasts | Rolling Snowpuffs | Big Brrr |
| 5 | Neon Nightway | Light gates opened by matching switches | Dashing Zappers | Gigabolt |

## Building from source

1. Install [Godot 4.7](https://godotengine.org/) and open this folder as a project.
2. Press **Play** to run it on your computer. Arrow keys or WASD move, Space drops a pod and Esc pauses.
3. To build an APK, install the Android export templates and set the Android SDK path in Godot's editor settings, then use **Project > Export > Android**.

The signed release build uses `tools/build_release.ps1`. It asks for the keystore password and never stores it. The keystore itself is not in this repo.

### Project layout

| Folder | Contents |
|---|---|
| `game/` | Arena rules: movement, pods, blasts, critters, boss |
| `core/` | World registry, save file, sound |
| `worlds/` | One script per world: its levels, look, rules, critters and boss (`WorldKit.gd` lists the hooks) |
| `render/` | Clay models built in code |
| `ui/` | Menu, level map, HUD and buttons |
| `shaders/` | Clay, glass, sky and shadow shaders |
| `tools/` | Screenshot, music, icon and release build scripts |

## Credits

Made by Manpreet Gugga. Nunito font by Vernon Adams and others, under the SIL Open Font License (`fonts/OFL.txt`).
