# Off Frequency — v0.2

A 2D sci-fi point-and-click mystery for Android (iOS later), built in **Godot 4.7** with GDScript.
The full story is in the *Off Frequency — Story Bible* doc; this build covers the prologue and all of Act 1.

![Preview](docs/preview.png)

## What's in v0.2

About 35–40 minutes of play, both branches of Choice 1, from the 1980 snowfield to the underpass on the road down:

| Part | Scene | What happens |
| --- | --- | --- |
| Prologue P1 | Snowfield, Oct 14, 1980 | Tomas: "It's talking back." Lock the gate, turn back: he's gone. |
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

### The rules the player learns

- **Darkness is a door.** In the dark you slip into another version of the building; any light holds you where you are. Mara carries a flashlight so she can walk dark rooms safely.
- **Frequencies look and sound different.** Each one has its own colour cast and its building hum sits at its own pitch. Home has no mark on the Tuner's dial: it sits between 06 and 07.
- Every crossing adds 1 to `FRACTURE` (4 by the end of Act 1).

Branch differences: cutting the power switches home to red emergency light, leaves footprints in the lobby, makes Sollen's desk lamp dead (flashlight only), and changes what the woman at the basement door says.

## Play it

**On Android:** copy `OffFrequency-v0.2-debug.apk` to the phone, open it, and allow "Install unknown apps" when asked. It installs over v0.1. Needs Android 7.0 or newer. It's a debug build, so it's for testing, not the Play Store.

**On your computer:** download Godot 4.7 (the standard build, not .NET), choose *Import*, pick this folder's `project.godot`, then press **F5**.

**Controls:** tap to walk; tap anything to look at or use it. Tap an inventory item to select it, then:
tap something in the room to use it there, tap **another item** to combine the two, or tap the **same item** again to examine it (examining Tomas's radio is how you use it). **?** flashes everything you can interact with, even in the dark. **II** (or Android's back button) pauses and saves.

**The Tuner:** drag along the dial (or nudge with ◀ ▶). When a station locks, the green lamp lights and *Step into the dark* goes through.

## Project layout

```
project.godot              Settings: 1280x720 landscape, GL Compatibility renderer
scenes/main.tscn           Entry point (just runs scripts/main.gd)
scripts/
  game_state.gd            Autoload: story variables, flags, inventory, frequencies, recipes, save/load
  audio_manager.gd         Autoload: sound effects, ambience loops, the voice-acting hook
  main.gd                  Camera, HUD, room changes, crossings, input blocking during scenes
  hud.gd                   Clock, objective, inventory (combine/examine), dialogue, choices,
                           document reader, glitch effect, fades, menus
  tuner_ui.gd              Tomas's radio: the dial, station sounds, lock lamp
  story.gd                 Works out the Act 1 objective line from the flags
  room.gd                  Base class for every screen: hotspots, walking, frequency, darkness,
                           flashlight, glow layer, hint layer
  station_room.gd          Shared look and ambience for the observatory interior
  actor.gd                 Mara, Tomas, Sollen asleep, the body, the silhouette (drawn from shapes)
  kit.gd, snow.gd          Drawing helpers (including the snowcat) and falling snow
  rooms/*.gd               One file per room: menu, snowfield_1980, corridor, receiver_room,
                           control_room, lobby, east_corridor, sollen_office, basement,
                           garage, road_down, end_card
  autotest.gd              Automated playthroughs (see Testing)
audio/*.wav                Placeholder sounds, generated by tools/gen_audio.py
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

- **Story variables** live in `GameState.story`: `ANSWERED`, `TOMAS`, `EIGHTY`, `FINALE`, `FRACTURE` (matching the story bible). Smaller facts are flags: `GameState.set_flag("read_note")`, `GameState.has("read_note")`.
- **Frequencies**: every room has a `freq` ("H" for home, "01", "03"...) and draws its own version. `main.cross("01", "east_corridor", "first")` plays the glitch, adds 1 to `FRACTURE` and loads that room on that frequency. `GameState.FREQS` holds each frequency's tint and hum pitch.
- **Darkness**: a room returns `true` from `is_dark()` and the world drops to near-black. With the flashlight, Mara gets a real 2D light cone (`PointLight2D`). `add_lamp()` puts other lights in a room; anything drawn in `draw_glow()` is never darkened.
- **Hotspots**: `add_hotspot(id, rect, label, walk_x, face, condition)`. The smallest hotspot under a tap wins.
- **Items**: `use_item(hotspot, item)` for using an item on something, `GameState.RECIPES` for combining two items, `examine_item(item)` to override what examining does in a room.
- **Choices and documents**: `await hud.choose([...])`, `await hud.read_doc(title, pages)`.
- **The Tuner**: `var station := await tuner_session(refuse)`, where `refuse(station)` returns `""` to let Mara through or a line she says instead.
- **Adding a room**: create `scripts/rooms/my_room.gd` extending `Room` (or `StationRoom`), then register it in `ROOMS` in `scripts/main.gd`.
- **Saving** happens automatically on every room change (including the frequency) and when the app is paused.

## Testing

The automated playthrough taps through the real game and checks the story state after each beat (150 checks across three runs):

```
godot --headless --path . -- --autotest=answer     # Choice 1: answer the voice, all of Act 1
godot --headless --path . -- --autotest=cut        # Choice 1: cut the power, all of Act 1
godot --headless --path . -- --autotest=continue   # save, quit, Continue (also inside frequency 01)
godot --headless --path . -- --check               # compile every room script and quit
godot --path . -- --autotest=tuner --shots=/tmp/t   # opens the Tuner in the dark garage and screenshots it
```

Each exits with code 0 on pass, 1 on failure, so they can run in GitLab CI. Add `--shots=/some/folder` (and drop `--headless`) to also save screenshots of key moments, the Tuner and the documents.

## Building the APK yourself

1. Install Android Studio (for the Android SDK) and a JDK 17+.
2. In Godot: **Editor → Editor Settings → Export → Android**, set *Java SDK Path* and *Android SDK Path*. Godot creates a debug keystore itself.
3. **Editor → Manage Export Templates → Download** for 4.7.
4. **Project → Export → Android → Export Project**.

For Google Play you'll need a release keystore, an `.aab` (turn on *Use Gradle Build* and install the Android build template from the Project menu), target SDK 36 (Godot 4.7's default), and, for a new personal developer account, a 14-day closed test with 12 testers.

> This APK is signed with a debug key. A future build signed with a different key won't install over it; uninstall first.

## Voice acting

There are no recordings yet: lines show as subtitles, and the 2:14 voice falls back to a garbled radio murmur. The hook for real actors is in place. If `voice/<key>.ogg` exists, where key is the first 16 hex digits of md5(`SPEAKER|exact line text`), `hud.say()` plays it and ducks the ambience under it. Nothing in the room scripts needs to change.

## Known limitations

- Art is drawn in code and the sound effects are synthesized placeholders, meant to be swapped for real assets: sounds by replacing files in `audio/` with the same names, art by giving `Actor` and the rooms sprite textures.
- Tested here with automated runs and rendered screenshots, but not yet on a physical phone. The 2D lights are the most demanding thing in the game; if a low-end phone struggles in dark rooms, lower `texture_scale` on the flashlight in `room.gd`.
- iOS export needs a Mac with Xcode and an Apple Developer account; nothing in the code is Android-only.

## Next: v0.3

Act 2: Ash Street and the house with the lights off, Eighty-One face to face, and Choice 2.
