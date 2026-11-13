# Off Frequency v0.5.0 — The Long Night

This update does three things. It reworks the story using the v0.5 feedback, redraws the people, the town and the vehicles, and replaces the music and the vehicle sounds. It covers the same ground as before: the prologue and Acts 1–2. Act 3 is planned in the story bible, not built.

## Files

- **Full source:** the complete Godot 4.6.3 project. Import `project.godot`.
- **Changed files:** paths relative to the project root, listed in `CHANGED_FILES_v0.5.0.txt`. Overlay them on your v0.4.0 source, then delete the files listed under *Removed*: the street-murmur sound (`audio/people_murmur.ogg` and its `.import`) and the v0.4 screenshots in `docs/screenshots`, which v0.5's set replaces. Godot regenerates `.godot` on import.
- **APK:** a signed ARM64 + ARMv7 Android test build, minimum Android 7.0, version code 9.

## Android installation and saves

Your v0.4.0 APK was signed with the development key on your computer. `.gitignore` keeps `*.keystore` out of the repository, so that key wasn't in the zip, and Android only updates an app from an APK signed with the same key. So that it installs without a conflict, the APK in this delivery uses its own package, `com.alihasanov.offfrequency.v05`, and appears as **Off Frequency 0.5** next to your v0.4. Your v0.4 and its save are untouched.

To update v0.4 **in place** and keep its save, export from this project on your own computer. The preset still targets `com.alihasanov.offfrequency.ambience` with version code 9 and signs with your local `build-support/offfrequency-debug.keystore`. Saves from v0.4 load into v0.5: their crossings are moved to `CROSSINGS`, and `FRACTURE` starts again at 0 under the new, fairer rule.

## Quick phone check

1. **New Game.** At the gate, Tomas's cord is split: tape it, talk about the polka hour, and pick a goodbye. Lock the gate; he's gone.
2. **Choice 1.** *Answer:* the voice asks for proof, and Mara says the goodbye on the air. *Cut:* in the red light, look at the footprints and the gauze where they stop.
3. **The notebook** (top bar, orange dot when there's something new). After Cal's board in 05, connect *the 2:05 warning* with *the 2:14 transmission*. In the kitchen, Mara can then ask Eighty-One about it ("nineteen times").
4. **The kitchen.** Eighty-One's cost and the polka-hour memory. After the match goes out, confront her or say nothing. If you kept quiet, June will listen later.
5. **The Lantern.** Ma asks for the goodbye and corrects it. In 1980 she makes Mara eat. Back in H, Mr. Dahl's booth is empty.
6. **Frequency 12.** Tomas asks his questions before Choice 2; his cord is taped black.
7. **Main Street.** Settle the Lunds' coat argument. After 1980, one Mr. Lund is gone and the church bell swings without a sound.
8. **Vehicles.** In the garage the snowcat is dark and cold on H; turn the key and the starter cranks but nothing catches. On 03 the work lamp's on and the plow's lights move away down the road. On the road down, Mara is at the wheel, the tracks turn, and snow sprays behind. Under the bridge the engine dies and catches again. On the snowfield, Ma's pickup idles with its headlights through the gate.
9. **Music.** The new dark ambient score loops without a seam. *Sound & atmosphere → Background music* still turns it off.

## What changed

**Story**
- `SIGNOFF` (over / light / dial): the goodbye chosen in the prologue. Mara gives it as proof on 2.14 (answer branch), Eighty-One quotes it or asks for it, 12's Tomas answers it wrongly, and Ma corrects it after the switch.
- Choice 1 exclusives: the voice's proof test (answer); Mara's boot prints and the burn gauze in the lobby (cut).
- `Notebook`: 33 observations and 8 theories (2 automatic, 6 found by connecting two notes). Nothing in it is ever overwritten.
- `SWITCH` (confront / conceal / confide): the playable response to the kitchen switch, with June as the confidante.
- Tomas's goal ("the lady on 2.14 … stuck somewhere dark"), on the Day 41 tape and in his questions in 12.
- Eighty-One: the Tomas who lasted eleven days, the polka hour, the "nineteen times" challenge.
- Halvard: Mrs. Halloran's radio, the Lunds' coat, Ma's pie, then the empty booth, the missing husband and the silent bell. Every sound clue has a caption.
- Rules: 12 is another world's past, said in game. `CROSSINGS` counts every crossing. `FRACTURE` rises only on a repeated crossing route or a slip in the mine, with an on-screen explanation. The chapter list gives the right ages.

**Art**
- `figure.gd` / `looks.gd`: every character drawn as a proportioned person on a posed skeleton (walk cycle with bending knees, idle breathing, sitting). Each has a distinct build, face, hairstyle and clothing; Tomas has a 13-year-old's proportions. The body, Sollen and Cal have proper poses.
- `townscape.gd`: brick, clapboard and stone façades, cornices, lit and curtained windows, snow ledges, icicles, streetlamps, the hill houses and St. Olaf's church. Main Street, Ash Street and the 1980 snowfield are redrawn with it.
- `vehicles.gd`:
  - Sollen's snowcat has rubber tracks with steel grousers, a drive sprocket, idler, bogie wheels and return rollers that turn with the distance driven. It has cab glass with reflections and seals, a mirror, a door with handle, hinges and the observatory's emblem, louvres, a headlight, a push bar and a roof rack with work lamps and a beacon. A radio whip sways when moving, an exhaust stack puffs vapour while the engine runs, and there's meltwater under it in the garage and snow spray on the road. Mara is visible at the wheel, lit by the dash.
  - Ma's pickup is an early-'80s two-tone at human scale, with chrome bumpers and mouldings, a West Coast mirror, a CB whip, the dash glow, exhaust vapour, its headlight beam, and tyre ruts back down the access road.
  - The county plow appears far down the road on 03, with tail lamps and a turning amber beacon.
- The road down gains snow stakes, a scrolling plow bank and the tracks' trail behind the snowcat.

**Sound**
- `night_score.ogg`: a new 180-second dark dystopian ambient score, seamless.
- `tools/gen_vehicles.py`: new vehicle sounds.
  - The snowcat: `engine` (four-cylinder diesel, about 1500 rpm under load) and `tracks` (grousers, snow crunch, bogies), plus `starter` (cranks, never catches), `engine_start` (catches, flares, settles) and `engine_stop` (sags, misfires, dies, rocks on its mounts).
  - Ma's pickup: `truck_idle` (V8 idle with the uneven left/right exhaust lope, heater blower) and `truck_start`.
  - The county plow: `plow` (a big diesel, the blade's scrape and chatter and tyre chains, all softened by distance).
  - Levels are matched by A-weighted loudness, so the room volumes still hold.
- `tools/gen_audio.py` no longer writes the old vehicle sounds, and every other sound it makes is byte-for-byte unchanged.
- `people_murmur.ogg` removed.

**Tools and tests**
- `tools/gen_chapters.py` now decides which choices a chapter depends on from the story keys, not from comparing whole states. The four test runs deliberately pick different goodbyes and optional scenes.
- New debug runs: `--autotest=lineup` (characters, poses and vehicles side by side) and `--autotest=vehicles` (the snowcat in the garage and on the road).

## Validation

See `docs/VALIDATION_v0.5.0.md`. Not yet played on a physical phone.
