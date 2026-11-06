# Boomlets: Google Play store listing

**App name** (30 max): Boomlets

**Short description** (80 max, 78 used):

Drop fizzy pods, blast crates and outsmart critters across 25 floating worlds.

**Full description** (4000 max):

Pop pods. Blast crates. Outsmart the critters!

Help Pip, a little sprout with a big fizz, clear twenty-five floating worlds. Drop a fizzy pod, step back, and watch it pop in a plus-shaped blast that breaks crates, sets off other pods and sends critters packing. Pop every critter to open the exit, then hop on it before the clock runs out.

EASY TO PICK UP
• Tap a tile and Pip walks there.
• Double-tap anywhere to drop a pod.
• Finish quickly for three stars.

25 WORLDS, EACH WITH ITS OWN TWIST
Every world brings a new idea to play with: conveyor belts and warp pads, tides that flood and drain, slippery ice, light gates, turnstiles, mirrors and prisms that bend blasts, wind gusts, lava vents, bramble hedges that grow back, spooky lanterns, springboards, stepping stones that swap on the beat, magnets, folding paper panels, book stacks to push, paint crates, toppling dominoes, splitting slimes, arcade wrap-around edges, echoing shell stones, orbiting asteroids, changing seasons, a mirrored shadow twin and starlight bridges in the sky.

150 LEVELS AND 25 BOSSES
Six levels per world, each ending in a boss fight against characters like Captain Clawdia, Sir Cuckoo, the Geode Golem, King Slime and the Star Owl. Beat a boss to open the next world. There are 450 stars to collect.

POWER-UPS
Break crates to find extra pods, longer blasts, speed boots, a kick to send pods sliding, a shield and extra hearts.

COZY AND CRISP
Soft clay-and-glass 3D worlds, cheerful music for every world, and short levels that fit a coffee break. No account needed. Your progress stays on your phone.

Boomlets is free to play with optional ads: watch a short ad for an extra life when you run out, plus an occasional ad between levels.

**Category:** Game > Arcade (or Puzzle)
**Tags:** Arcade, Casual, Puzzle
**Contact website:** https://manpreetgugga.github.io/boomlets/
**Privacy policy:** https://manpreetgugga.github.io/boomlets/privacy.html

## Graphics (store/graphics)

- App icon: `icon_512.png` (512×512, 32-bit PNG)
- Feature graphic: `feature_1024x500.png` (made by `tools/make_feature_graphic.py` from `source/board_w7.png`)
- Phone screenshots, in order: `screen_1.png` … `screen_8.png` (1080×1920), made by
  `tools/make_store_screens.py` from character close-ups rendered into `shots/`:
  - `f_<world>.png` (1080×1500): `--world=W --level=6 --size=1080x1500 "--do=0.1:nohud;5:stage:3,9,7[,pod|,blast];5.3:shot:f_W"`
    for worlds 1 (pod), 9 (blast), 5, 11 (pod), 22 (stage at 4, shot at 4.2), 17, 25 (pod).
  - `p_<world>.png` (540×540) boss portraits for the collage: `--size=540x540 "--do=0.1:nohud;5:stage:3,6,8,solo;5.08:shot:p_W"`
    for worlds 2, 3, 4, 7, 15, 23.
