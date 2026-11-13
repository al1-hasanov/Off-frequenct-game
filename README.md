# Off Frequency — v0.6.2: The Futures

A 2D sci-fi point-and-click mystery for Android (iOS later), built in **Godot 4.6.3** with GDScript.
The full story is in the *Off Frequency — Story Bible* doc; this build covers the prologue and Acts 1 to 3.

![Preview](docs/preview.png)

## New in v0.6.2: what Dad was listening to

Dark energy is now the science under the story. Dad's Air Force study, code name LAMBDA, was measuring the energy of empty space twenty years before anyone called it dark energy, and every year Mara visits hints at it with something that existed then: his *Gravitation* and LAMBDA notes on Sollen's shelf (Einstein's Λ, the Einstein–Rosen bridge, Everett's branches, Gödel's loop), a Λ that won't rub off the control-room chalkboard, Λ.L. on his diagram, Einstein's equation on the 2031 museum wall with a timeline from 1917 to DESI in 2025, the Big Rip on Tomas's door in 2009, and the 1988 wormhole time-machine paper in his 1991 workshop. Four new notebook theories (twelve in all). The ? button points to each optional clue while it's unread. Red's turnings now show each sound's name in its rings, and the ? button knows which turning you're at. See [UPDATE_v0.6.2.md](UPDATE_v0.6.2.md).

## Previous update, v0.6.1: true to scale

Act 3's places are drawn to the people's scale (about 110 px to the metre): full-size cars, doors taller than the people going through them, buildings whose storeys run up out of the picture, and the dish standing well back across the summit. Main Street in 1991 is rebuilt at full scale, with his sedan and their minivan parked at the kerb in front of you; the shop's desks and benches are at real heights. See [UPDATE_v0.6.1.md](UPDATE_v0.6.1.md).

## New in v0.6.0

**Act 3 is playable**, about 40 minutes after the mine tunnel: Dad's 2.14 chain, three futures through the dish's feed cabin, Tomas's notebook and the experiment, Red's chapter in the dark, and Eighty-One. Two new choices (LETGO and EIGHTY), and it ends on three knocks at the front door.

Every year the story visits looks like that year:

- **1983 (tonight):** the summit outside, the 26-metre dish swung to the horizon, the ladder to the feed cabin, a late-'70s sedan snowed in; the control room's patch bay, chart recorder, dish drive and a chalkboard that writes the next year by itself.
- **2031:** the Halvard Signal Visitor Center on an autumn afternoon: a glass-and-timber entrance, solar panels, an electric car charging, a driverless shuttle, wind turbines, the dish painted white behind a fence; inside, a museum of the night (the recordings wall, Sollen's desk, Dad's photograph, the plaque) and a screen that says NO SIGNAL.
- **2009:** a roofless ruin full of snow, THEY CAME OUT OF THE DARK, the stone wing lit in every window behind the lamp line, two abandoned 2000s cars, the dish rusted fast, Tomas's hut, a white wall on the ridge that comes nearer; the basement 26 years on, seen only by lamplight.
- **1991:** Main Street half erased like a torn photograph, with PIKE & LIND RADIO, HALVARD VIDEO, a payphone, a 1991 sedan and a woodgrain minivan; the shop's back room with CRT televisions, a beige PC, VHS tapes, a hot plate, the ham rig and eighty strips of tape on the wall.
- **People at their ages:** Cal at 83, June at 78, Tomas at 21, 24 and 40, Lise expecting, the Lunds in their late eighties, 2031's visitors; older faces carry their years (lines, jowls, age spots).

See [UPDATE_v0.6.0.md](UPDATE_v0.6.0.md) for everything new, chapter by chapter.

### Install this test build

Open `OffFrequency-v0.6.2-debug.apk`. It is **Off Frequency 0.5** (`com.alihasanov.offfrequency.v05`, version code 14), signed with the same key as the v0.5.x test APKs, so it **updates them in place**. A save from v0.5.x that reached the end of Act 2 continues into Act 3 from **Chapters (debug)** → Act 3 → 3.1.

Your v0.4 install is still separate, because it was signed with the key on your own computer. To update that one in place, export from this project on your computer (see *Building the APK yourself*): the preset targets `com.alihasanov.offfrequency.ambience`, version code 14, signed with your local `build-support/` key.

### Previous update, v0.5.2: every station is its own world

- Tuning changes the world, not just the house: each station's Halvard has its own season, hour, weather and fate, on Ash Street, Main Street, the garage's road doors and the Lantern's window.
- Ash Street's windows fixed; Mara in 1980 redrawn; a sharper opening film.
- Much less work for the phone: each room's still picture and each character are kept as one image (Ash Street went from about 1,663 draw calls a frame to 66).

### Previous update, v0.5.1: a new opening

- The opening from your script: the Lantern at 12:24 AM, the drive up the mountain, the clearing (holding the light on Tomas's radio, their song in the shared headphones, the goodbye, the lock that sticks), the aftermath as a short film with **Skip**, and October 14, 1983 at the locker. Their song plays in two versions in step: the radio's speaker and the headphones.
- Nothing on the walls overlaps (checked by `--autotest=layout`). The still parts of every room are drawn once; 60 fps cap; **Settings → Display** (battery saver, smooth edges, frame counter).

### Previous update, v0.5.0: The Long Night

- **The story pass.** The goodbye Mara and Tomas always said (`SIGNOFF`) comes back all night. Choice 1 has teeth: answering makes Mara prove who she is on an open band, and cutting the power leaves her own boot prints and a twist of burn gauze in the lobby. **Mara's notebook** (top bar) keeps what she's seen apart from what she thinks (connect two notes to form a theory). There's a response to the switch (story `SWITCH`), Tomas has a goal (rescuing "the lady on 2.14"), and Eighty-One has a cost (she took a Tomas home once; he lasted eleven days). Halvard has people to protect, and every sound clue has a caption. The rules are fairer: `FRACTURE` only rises on a repeated crossing or a slip in the mine; `CROSSINGS` counts everything.
- **Art and sound.** Characters drawn as people on a posed skeleton, with their own builds, faces and hairstyles; a rebuilt town and observatory; the snowcat, Mara's pickup and the county plow; a three-minute dark ambient score; new vehicle sounds.

### Previous update, v0.4.0: After Hours

More detailed rooms and characters, layered ambience, the **Sound & atmosphere** menu (music on/off and four volumes, saved separately from the story), ambience that eases under dialogue and the Tuner, and fades between rooms.

## Story content inherited from v0.3

About 70–80 minutes of play. Both branches of Choice 1 and both of Choice 2, from the 1980 snowfield to the mine under the mountain.

### Previous update, v0.3.2: no more fake voices

- **Main Street** now sounds like a street full of people at 2 AM instead of a murmur: boots crunching past at different distances, doors, a snow shovel, someone stamping off snow, a cough, keys, a car door, a car crawling by on packed snow, a dog blocks away, somebody whistling. Louder than before, with a little echo off the house fronts.
- **Radios are radio**, with no speech-like sound anywhere. The police scanner (Pike Radio, the sheriff's office, station 05) opens its squelch on weak, fluttering carriers, with roger beeps and a data burst. June's shop adds a shortwave loop: Morse code, a tuning whistle, fading static. Under the 2:14 voice's lines, the squelch opens on a fading, warbling carrier.
- That update retained the other sound effects; v0.4.0 adds the layers listed above.

### Previous update, v0.3.1: chapter select (debug)

The title screen has a **Chapters (debug)** button (debug builds only, which includes this APK). Pick a tab (Prologue, Act 1, Act 2), set how **Choice 1** and **Choice 2** went, and tap a chapter. You start there with the story set exactly as a full playthrough reached it: inventory, flags, frequency, `FRACTURE`, clock, emergency lighting. Jumping replaces your save, so **Continue** resumes from the chapter.

| | Starts in | | | Starts in |
| --- | --- | --- | --- | --- |
| P1 The Lantern, 1980 | the diner (new game) | | 2.1 Main Street | Main Street, arriving |
| P1b The clearing | the snowfield, after two | | 2.2 Pike Radio | June's shop |
| P2 Night shift | main corridor: the locker, then 1:40 | | | |
| P3 2:14 AM | receiver room, fuse in hand | | 2.3 Cal's crystal | Main Street, after June's diagnosis |
| 1.2 The body | control room | | 2.4 Eighty-One | Ash Street, radio repaired |
| 1.3 The phone | lobby | | 2.5 The Lantern | the diner |
| 1.4 The first crossing | corridor, calls made | | 2.6 Snowfield, 1980 | frequency 12, with Ma's truck keys |
| 1.5 Light keeps you home | corridor, back from 01 | | 2.7 The mine tunnel | the tunnel mouth |
| 1.6 Tomas's box | basement | | | |
| 1.7 The garage | garage | | | |
| 1.8 The road down | the snowcat, on 03 | | | |

Choice 1 matters from 1.2 on; Choice 2 only for 2.7. The starting states are recorded from the automated playthroughs (see Testing), so they stay correct as the game changes: rerun and regenerate.

### New in v0.3: Act 2, "The overlap"

| Part | Scene | What happens |
| --- | --- | --- |
| **Act 2.1** | Main Street | The hub. Every light in town on at 2 AM, people outside in pajamas, Mr. Lund beside his wife and also at their kitchen window. |
| **Act 2.4a** | Ash Street | Mom's house is lit. Under the broken streetlight, the Tuner shows each station's version of the house behind it, but none is dark: the dial stops at 09. |
| **Act 2.2** | Pike Radio & Repair | June Pike finds the cracked crystal. The only match is in the sheriff's base radio. |
| **Act 2.3** | Sheriff's office, frequency 05 | Through the dark alley to 05, where it's already Oct 17: Cal asleep beside his board for Mara's murder. Doormat under the filing cabinet, pull the plug, take the crystal. June fits it: the dial reaches 99 (bands of ten: −10 / +10). |
| **Act 2.4** | Ash Street 14, the kitchen | Tune to 14: the house is dark and for sale. Eighty-One, by match light; ask your questions in any order. Then a third Mara at the back door, the match goes out, and the player is someone else. Nothing says so. |
| **Act 2.5** | The Lantern diner | Ma. Ask for pie to send her to the front, unscrew the pantry bulb, shut the door, tune to 12. |
| **Act 2.6** | 1980, frequency 12 | A younger Ma ("Did you cut your hair?"), her truck keys, the snowfield seen from the treeline. **Choice 2:** take Tomas, or send him back to his sister. Sets `TOMAS`. |
| **Act 2.7** | The mine tunnel | The dish is turning by itself; June calls on the radio. The flashlight dies in the cold, and in total darkness you keep the drifting needle on home while Mara walks. Halfway, every sound stops. |

Everything Act 2 adds works with the **?** hint button from the start.

### The prologue and Act 1 (from v0.2)

| Part | Scene | What happens |
| --- | --- | --- |
| Prologue P1 | The Lantern, the road up, the clearing, Oct 14, 1980 | Henrik calls Mara back; Tomas comes too. Hold the light on his radio, share his headphones, lock the gate: he's gone. Then the aftermath, to 1983. |
| Prologue P2 | Main corridor, 1:40 AM | Sollen's note, Mara's locker (red tape), the fuse puzzle (spares cabinet → vending machine). |
| Prologue P3 | Receiver room, 2:13 → 2:14 | The transmission, the knock, every clock stops. |
| Act 1.1 | Receiver room | **Choice 1:** answer the voice, or cut the power. Sets `ANSWERED`. |
| Act 1.2 | Control room | Mara's body: blue tape, a watch stopped at 2:14, the "81" note. |
| Act 1.3 | Lobby | Splice the phone with red tape, three calls into three frequencies. The last one rings in Sollen's office. |
| **Act 1.4** | East wing, frequency 01 | Walking into the dark wing slips Mara into **01**: lights on, Sollen asleep, fire doors chained. Take his keys and scarf, unscrew the hot bulb, shut his door, and cross home in the dark. |
| **Act 1.4** | Home again | Booth flashlight (dead) + the frozen clock's batteries. Sollen's office: receiver off the hook and still warm, the 1980 station log, Tomas's tape, the garage key. |
| **Act 1.5–1.6** | Basement | Tomas's crate: his radio (the Tuner), the Day 41 tape, a notebook-shaped gap in the dust. Then the knock at the delivery door, in Mara's own voice. |
| **Act 1.7** | Garage, frequency 03 | Empty tank, a pine across the road. Red tape on the wrist, flashlight off, tune to 03: road plowed, tank full. |
| **Act 1.7** | The road down | Halvard's windows breathing, the underpass, the engine dies in total darkness. Find home on the dial. |

### New in v0.2.1: hints

- **The ? button now tells you exactly what to do next**, wherever you are, on either branch: which room to go to, what to tap, and which item to use on what. Then it lights up everything you can interact with, as before.
- Objectives are more specific at the steps that were easy to miss: the vending-machine fuse, the four things to check on the body, the junction box, the clock batteries and the caged lamp.
- Small hotspots (the watch, the fuse holder, the note) also catch taps that land just outside them.
- The Tuner panel says how to use it, and Mara tells you where home is on the dial at the underpass.

### The rules the player learns

- **Darkness is a door.** In the dark you slip into another version of the building; any light holds you where you are. Mara carries a flashlight so she can walk dark rooms safely.
- **Frequencies look and sound different.** Each one has its own colour cast and its building hum sits at its own pitch. Home has no mark on the Tuner's dial: it sits between 06 and 07.
- Every crossing is counted in `CROSSINGS` (4 by the end of Act 1). Since v0.5, `FRACTURE` only rises when Mara crosses back over her own tracks or slips in the mine tunnel.

Branch differences: cutting the power switches home to red emergency light, leaves footprints in the lobby, makes Sollen's desk lamp dead (flashlight only), and changes what the woman at the basement door says.

## Play it

**On Android:** install the v0.5.2 APK as described above. This development build supports ARM64 and ARMv7 phones; it is not a Play Store release.

**On your computer:** download Godot 4.6.3 (the standard build, not .NET), choose *Import*, pick this folder's `project.godot`, then press **F5**.

**Controls:** tap to walk; tap anything to look at or use it. Tap an inventory item to select it, then:
tap something in the room to use it there, tap **another item** to combine the two, or tap the **same item** again to examine it (examining Tomas's radio is how you use it). **?** tells you what to do next, then flashes everything you can interact with, even in the dark. **II** (or Android's back button) pauses and saves.

**The Tuner:** drag along the dial (or nudge with ◀ ▶). When a station locks, the green lamp lights and *Step into the dark* goes through. After June's repair, **−10 / +10** switch between bands (00–09, 10–19 ... 90–99). While a station is locked, the scene behind the panel shows a glimpse of that frequency.

## Project layout

```
project.godot              Settings: 1280x720 landscape, GL Compatibility renderer
scenes/main.tscn           Entry point (just runs scripts/main.gd)
scripts/
  game_state.gd            Autoload: story variables, flags, inventory, frequencies, recipes, save/load
  audio_manager.gd         Autoload: effects, ambience, streamed score, persisted audio mix
  audio_settings.gd        Settings: sound on the left, display on the right
  display_settings.gd      Battery saver, smooth edges, the frame counter (user://display_settings.cfg)
  radio_fix.gd             The opening's close-up: hold the light on the back of Tomas's radio
  intro_art.gd             The opening's shared art: the clearing, the service road, footprints
  environment_art.gd       Shared authored vector materials and scene props
  main.gd                  Camera, HUD, room changes, crossings, input blocking during scenes
  hud.gd                   Clock, objective, inventory (combine/examine), dialogue, choices,
                           document reader, glitch effect, fades, menus
  tuner_ui.gd              Tomas's radio: the dial, bands, station sounds, lock lamp, hold mode
  story.gd                 Works out the objective and the ? button's hint from the flags
  chapters.gd              Debug chapter select: the chapter list and lookups
  chapter_states.gd        GENERATED: each chapter's starting state (tools/gen_chapters.py)
  room.gd                  Base class for every screen: hotspots, walking, frequency, darkness,
                           flashlight, glow layer, hint layer
  station_room.gd          Shared look and ambience for the observatory interior
  actor.gd                 Every character in a room: walks, sits, idles, and the special poses
                           (the body, Sollen and Cal asleep); poses a skeleton for Figure
  figure.gd                Draws a person over that skeleton: body, face, hair, clothes, props
  looks.gd                 Who looks like what: build, face, hairstyle and clothes per character
  notebook.gd              Mara's notebook: what she's seen and heard, and the theories
  townscape.gd             Façades, windows, cornices, snow ledges, streetlamps, the church
  vehicles.gd              Sollen's snowcat, Mara's 1980 pickup, the county plow, the cruiser and sedan
  era_vehicles.gd          Cars of other years: 1991 sedan and woodgrain minivan, abandoned 2000s
                           SUV and sedan, a 2031 electric crossover, its charger, the shuttle
  act3.gd                  Act 3: which future the dish hears, trips through the feed cabin, the
                           Silence, the chalkboard's years, playing as Red, the wrist close-up
  env.gd                   Each station's world (season, hour, weather) and the futures (F2031...)
  kit.gd, snow.gd          Drawing helpers and falling snow
  rooms/*.gd               One file per room: menu, intro_diner, intro_road, snowfield_1980,
                           intro_after (the opening's film), corridor, receiver_room,
                           control_room, lobby, east_corridor, sollen_office, basement,
                           garage, road_down, main_street, pike_radio, sheriff_office,
                           ash_street, ash_kitchen, diner, mine_tunnel, end_card;
                           Act 3: dish (1983, 2031, 2009), visitor_center (2031),
                           basement_2009, main_street_1991, shop_1991, red_dark, pike_dark (44);
                           lineup..lineup6 (debug: characters at every age, cars of every year)
  autotest.gd              Automated playthroughs (see Testing)
audio/*.wav                Original effects, generated by tools/gen_audio.py; vehicle sounds
                           (engine, tracks, starter, truck_idle, plow...) by tools/gen_vehicles.py
audio/*.ogg                The dark ambient score and layered ambience, tools/gen_atmosphere.py;
                           their song (song_clear, song_radio), tools/gen_song.py
textures/*.png             Flashlight cone and glow, generated by tools/gen_textures.py
export_presets.cfg         Android export preset
```

## How the story code works

Every room extends `Room` and overrides a few functions. Scenes are coroutines, so a cutscene reads top to bottom:

```gdscript
func on_hotspot(id: String) -> void:
    match id:
        "locker":
            await mara("Tomas. Thirteen forever, taped inside a locker door.")
            GameState.add_item("red_tape")
            hud.toast("Got: Red tape")
        "receiver_door":
            main.change_room("receiver_room", "from_corridor")   # always the last line, never awaited
```

- **Story variables** live in `GameState.story`: `ANSWERED`, `TOMAS`, `EIGHTY`, `FINALE`, `FRACTURE`, plus `CROSSINGS`, `SIGNOFF` and `SWITCH` since v0.5 (matching the story bible). Smaller facts are flags: `GameState.set_flag("read_note")`, `GameState.has("read_note")`.
- **Frequencies**: every room has a `freq` ("H" for home, "01", "03"...) and draws its own version. `main.cross("01", "east_corridor", "first")` plays the glitch, counts the crossing in `CROSSINGS` (and in `FRACTURE` if Mara has made that exact crossing before) and loads that room on that frequency. `GameState.FREQS` holds each frequency's tint and hum pitch.
- **Darkness**: a room returns `true` from `is_dark()` and the world drops to near-black. With the flashlight, Mara gets a real 2D light cone (`PointLight2D`). `add_lamp()` puts other lights in a room; anything drawn in `draw_glow()` is never darkened.
- **Hotspots**: `add_hotspot(id, rect, label, walk_x, face, condition)`. The smallest hotspot under a tap wins.
- **Items**: `use_item(hotspot, item)` for using an item on something, `GameState.RECIPES` for combining two items, `examine_item(item)` to override what examining does in a room.
- **Choices and documents**: `await hud.choose([...])`, `await hud.read_doc(title, pages)`.
- **The Tuner**: `var station := await tuner_session(refuse, start, band)`, where `refuse(station)` returns `""` to let Mara through or a line she says instead. While a station is locked, the room's `tuning` holds it, so `draw_back()` can show that frequency's version (Ash Street does this).
- **People behind counters and desks**: `add_layer(1, fn)` draws a prop in front of other characters but behind Mara.
- **Adding a room**: create `scripts/rooms/my_room.gd` extending `Room` (or `StationRoom`), then register it in `ROOMS` in `scripts/main.gd`.
- **Saving** happens automatically on every room change (including the frequency) and when the app is paused.

## Testing

The automated playthrough taps through the real game and checks the story state after each beat (931 checks across eight runs, and every step must have a hint):

```
godot --headless --path . -- --autotest=answer        # answer the voice, take Tomas: to the end of Act 3
godot --headless --path . -- --autotest=cut           # cut the power, then leave Tomas
godot --headless --path . -- --autotest=answer_leave  # answer the voice, then leave Tomas
godot --headless --path . -- --autotest=cut_take      # cut the power, then take Tomas
godot --headless --path . -- --autotest=atmosphere    # audio independence, persistence, pause, assets
godot --headless --path . -- --autotest=continue      # save, quit, Continue (also inside 01 and 05)
godot --headless --path . -- --autotest=chapters      # chapter select: every chapter, every choice combination
godot --headless --path . -- --autotest=layout        # no wall decoration sits on anything you can tap
godot --headless --path . -- --autotest=perf          # drawing time per frame in every room (frame cap off)
godot --headless --path . -- --autotest=act3_cut      # just Act 3, from chapter 3.1 (act3_answer, act3_cut_take...)
godot --path . -- --autotest=eras --shots=/tmp/e      # every Act 3 place in its year, screenshotted
godot --path . -- --autotest=opening --shots=/tmp/o   # just the opening, 1980 to 1983, with screenshots
godot --headless --path . -- --check               # compile every room script and quit
godot --path . -- --autotest=tuner --shots=/tmp/t   # opens the Tuner in the dark garage and screenshots it
godot --path . -- --autotest=rooms --shots=/tmp/r   # screenshots every Act 2 room
godot --path . -- --autotest=lineup --shots=/tmp/l  # every character and pose, and the vehicles, side by side
godot --path . -- --autotest=vehicles --shots=/tmp/v  # the snowcat in the garage and on the road down
```

Each exits with code 0 on pass, 1 on failure, so they can run in GitLab CI.

**Regenerating the chapter states** after changing the story: add `--chapters=FILE` to the four playthroughs, then build `scripts/chapter_states.gd` from them:

```
godot --headless --path . -- --autotest=answer       --chapters=ch_answer.json
godot --headless --path . -- --autotest=answer_leave --chapters=ch_answer_leave.json
godot --headless --path . -- --autotest=cut_take     --chapters=ch_cut_take.json
godot --headless --path . -- --autotest=cut          --chapters=ch_cut.json
python3 tools/gen_chapters.py ch_*.json
```

The playthrough marks where each chapter starts (`_mark("2.4", "ash_street")` in `autotest.gd`) and saves the state as that room loads. To add a chapter, add a `_mark` there and an entry in `Chapters.LIST`. Add `--shots=/some/folder` (and drop `--headless`) to also save screenshots of key moments, the Tuner and the documents.

## Building the APK yourself

1. Install Android Studio (for the Android SDK) and a JDK 17+.
2. In Godot: **Editor → Editor Settings → Export → Android**, set *Java SDK Path* and *Android SDK Path*. The export preset signs with the development key at `build-support/offfrequency-debug.keystore` (alias `androiddebugkey`, password `android`), which `.gitignore` keeps out of the repository. Keep your local copy: the builds you sign with it update each other in place.
3. **Editor → Manage Export Templates → Download** for 4.6.3.
4. **Project → Export → Android → Export Project**.

For a production release, use your own private release key and review the current Android and store requirements. The bundled test key is intentionally a development credential, not a production identity.

Command line (after SDK configuration):

```sh
godot --headless --path . --editor --import
godot --headless --path . --export-debug Android build/OffFrequency-v0.5.2-debug.apk
```


## Voice acting

There are no recordings yet: lines show as subtitles, and under the 2:14 voice the squelch opens on a fading radio carrier (no fake speech). The hook for real actors is in place. If `voice/<key>.ogg` exists, where key is the first 16 hex digits of md5(`SPEAKER|exact line text`), `hud.say()` plays it and ducks the ambience under it. Nothing in the room scripts needs to change.

## Known limitations

- Art remains stylized, code-drawn 2D artwork. New sound textures and music are original synthesized assets, not field recordings or recorded voice acting. The new Ogg version of a sound takes priority over its WAV fallback.
- Tested here with automated runs and rendered screenshots, but not yet on a physical phone. If a phone still struggles, try *Settings → Display → Battery saver*; the frame counter shows the frame rate and the slowest frame. The 2D lights are the most demanding thing on the GPU side: if dark rooms are slow, lower `texture_scale` on the flashlight in `room.gd`.
- iOS export needs a Mac with Xcode and an Apple Developer account; nothing in the code is Android-only.

## Later story expansion

Act 4 opens on the three knocks at the front door, with the transmit key in Mara's pocket and whatever she chose in 1991 and with Eighty-One (see the story bible's *Threads for Act 4*).
