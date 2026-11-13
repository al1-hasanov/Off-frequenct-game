# Off Frequency v0.5.2 — Other stations, other seasons

What you asked for: the Ash Street window fixed, 1980 Mara drawn like Mara now, the world changing with every station Mara tunes (seasons included), the rough parts of the opening redrawn, and the update itself. The frame rate on your phone (23 fps on Ash Street) got its own fix.

## Files

- **Full source:** the complete Godot 4.6.3 project. Import `project.godot`.
- **Changed files:** paths relative to the project root, listed in `CHANGED_FILES_v0.5.2.txt`. Overlay them on your v0.5.1 source. Nothing was removed. Godot regenerates `.godot` on import (new class names: `Env`, `LindHouse`).
- **APK:** a signed ARM64 + ARMv7 Android test build, minimum Android 7.0, version 0.5.2 (code 11).

## Android installation

The APK is **Off Frequency 0.5** (`com.alihasanov.offfrequency.v05`), signed with the same development key as the v0.5.0 and v0.5.1 test APKs, so it installs **over** them and keeps the save. Exporting from this project on your own computer still targets `com.alihasanov.offfrequency.ambience` with your local key, now as version code 11.

## Quick phone check

1. **Frame rate.** The counter is bottom left (Settings → Display → Show frame rate). Check Ash Street and Main Street, which were the slow ones, and the Lantern with three people in it.
2. **Ash Street windows.** Chapters → 2.4 (or walk up from Main Street). Ma's lamp is in the window left of the porch, the porch light is the lantern by the door, nothing overlaps. In 14, FOR SALE hangs on the porch rail.
3. **Tuning on Ash Street.** Stand under the broken streetlight and use the Tuner. On every station the street behind Mara changes: 02 is rain on an autumn night, 04 a clear night with a moon and a blue house, 06 an autumn dusk with the door banging open, 07 fireflies on a summer night, 08 a wet spring evening, 09 a summer afternoon, 00 boarded up at a grey dawn. After June fixes the crystal, −10 / +10 reach dozens more. The quiet ones are white and empty. 14 and home look as they always did.
4. **Main Street.** From the alley (after June's diagnosis), the whole street changes with the station, and tonight's people aren't in it.
5. **1980 Mara.** New Game: in the Lantern, on the drive, in the clearing and through the aftermath she has Mara's face and ponytail (a little longer), a navy work jacket, and the olive work coat over her arm.
6. **The opening.** The workbench with receiver two coming on, the view from the cab with snow settling on the glass, then in the aftermath: Cal's questions under the map, the photograph on the sideboard, the duplicator at St. Olaf's, the pole by the service road, the night shift, the Lind house one spring night, the living room with the crate.

## What changed

**Every station is its own world** (`env.gd`, `townscape.gd`, `kit.gd`, `snow.gd`, `lind_house.gd`, `room.gd`, `ash_street.gd`, `main_street.gd`, `garage.gd`, `diner.gd`)

- `Env` gives every frequency a world: season (winter, spring, summer, autumn), hour (night, dusk, dawn, day), what's falling (snow, rain, leaves, petals, fireflies, nothing), cloud, who's home, the house's paint, a working streetlight, a moon, a fire over the hill. Band 0 follows its captions (02 is the rain, 06 the open door, 09 the empty room with the phone); every other station takes its season from its number and the rest from what can be heard on it (sirens mean a fire, a plow means winter, rain means rain).
- The stations the story visits (H, 01, 03, 05, 12, 14) keep October 14's snowy night, unchanged.
- The outdoor helpers follow the station: snow on ledges, roofs and banks only in winter (grey remnants in spring), icicles, pines with snow by day, lit windows after dark and daylight in the glass by day, boarded windows on the derelict stations, the church, the hillside houses. New: a maple that is bare, in blossom, full or turning; clouds, the sun and the moon; gardens along the fence.
- While the Tuner holds a station: Ash Street, Main Street (seen from the alley), the garage's road doors and the Lantern's front window show that station. The light on Mara outdoors follows its hour. Main Street's people step out of the picture. Mara's refusal lines describe what she sees.
- `--autotest=glimpses` checks all 100 stations have a world, the story stations keep their night, the dial reaches all four seasons, and every place returns to its own night; with `--shots` it photographs 17 stations in each of the four places.

**Ash Street** (`ash_street.gd`, `lind_house.gd`): the front-room window with Ma's lamp sits on the ground floor left of the porch, clear of the upstairs windows; the porch light is a lantern on the wall by the door; FOR SALE is on the porch rail. The match in 14 burns in the front-room window. The house is now shared with the opening's montage.

**1980 Mara** (`looks.gd`, `figure.gd`): the same face, build and ponytail as Mara in 1983 (the ponytail longer: Ruth still notices the haircut in 12), a navy work jacket over the same red flannel, no tool belt.

**The opening** (`intro_road.gd`, `intro_after.gd`, `diner.gd`)

- Redrawn: receiver two on the workbench (pegboard of tools, the hanging lamp, the valves glowing as it comes on, the meters waking, the soldering iron, the meter and its probes); the windscreen (the observatory and the dish beyond the glass, the mast light, snow falling and landing and piling along the wipers, the dash and its gauges, the heater, Tomas's radio and Ruth's paper bag); the interview (the search map with the clearing ringed, notes, a clock at ten to three, Cal's hat); the photograph on the sideboard (wallpaper, a lamp, two smaller photographs, a lace runner); the duplicator in St. Olaf's office (the hymn board, the notice board, the crank, the stack); the pole by the service road; the night shift (racks of receivers, the scope, the tape machine, the desk lamp, the dish through the window); the Lind house one spring night; the living room (wallpaper, curtains, the sofa, a television, the radiator, his things by the crate).
- "Winter becomes spring": no more snow past the diner window.

**Speed** (`room.gd`, `actor.gd`, `snow.gd`, `road_down.gd`, `environment_art.gd`)

- A room's still picture is rendered once into a texture at the screen's own resolution and shown as one image. Each character is drawn into a small texture of their own, redrawn only when they change (standing still: Mara 12 times a second, everyone else 6; at most two people in any one frame). Snow, rain, leaves and dust go out as one batch.
- Draw calls per frame, everyone standing still, at 60 fps: Ash Street about 66 (was 1,663), Main Street about 170 (was 2,485), the 1980 snowfield about 92 (was 1,268), the Lantern about 120 (was 803). That's the per-frame cost your phone's GPU driver pays one by one; it was what held Ash Street at 23 fps.
- The road down keeps its sky and mountains; only the road, the pines and the snowcat redraw.
- The texture is refitted when the screen changes (rotation, battery saver, smooth edges).

## Validation

See `docs/VALIDATION_v0.5.2.md`. Not yet played on a physical phone.
