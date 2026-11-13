# Off Frequency v0.5.1 — The Long Night, revised

Three things you asked for: a new opening from your script, wall decorations that no longer sit on top of each other, and a fix for the low frame rate.

## Files

- **Full source:** the complete Godot 4.6.3 project. Import `project.godot`.
- **Changed files:** paths relative to the project root, listed in `CHANGED_FILES_v0.5.1.txt`. Overlay them on your v0.5.0 source. Nothing was removed. Godot regenerates `.godot` on import.
- **APK:** a signed ARM64 + ARMv7 Android test build, minimum Android 7.0, version 0.5.1 (code 10).
- **Story bible:** the doc's prologue is rewritten to match (P1 now covers the Lantern, the road up, the clearing, the aftermath and 1983), with a fresh PDF.

## Android installation

The APK is **Off Frequency 0.5** (`com.alihasanov.offfrequency.v05`), signed with the same development key as the v0.5.0 test APK, so it installs **over v0.5.0** and keeps its save. Your v0.4 stays a separate app. Exporting from this project on your own computer still targets `com.alihasanov.offfrequency.ambience` with your local key, now as version code 10.

Saves from v0.5.0 load. A save made during the old opening resumes at the start of the clearing.

## Quick phone check

1. **New Game.** The Lantern, 12:24 AM. Watch the frame counter in the bottom-left corner (Settings → Display → Show frame rate; on by default in this test build).
2. **The phone rings.** Tap it on the wall between the booths and the counter. Then take Tomas out of the front door.
3. **The drive** plays by itself: the sign in the headlights, the gate, the workbench, the windscreen.
4. **The clearing.** Drag the light onto the back of the radio, then onto the batteries, then hold it on the spring where Tomas points. Take the headphone ("Listen"). Pick the goodbye. Tap the padlock until the key turns, then walk to the flashlight in the snow.
5. **The aftermath.** Tap through the lines; press **Skip** once to check it lands in 1983.
6. **1983.** The locker, the song down the corridor, the title, then "Twenty to two". The objective should read *Read Sollen's note on the control-room door*.
7. **Walls.** Corridor (clock and notice), control room (window frame, chalkboard, TX-1), lobby, east wing, sheriff's office: nothing overlaps.
8. **Speed.** Main Street and the snowfield were the slowest rooms. Compare the counter with v0.5.0, then try *Battery saver* if the phone still runs warm.
9. **Frequency 12** (Chapters → 2.6): the song on Tomas's radio when Mara arrives; she notices his top button.

## What changed

**The opening** (`intro_diner.gd`, `intro_road.gd`, `snowfield_1980.gd`, `intro_after.gd`, `radio_fix.gd`, `intro_art.gd`)

- The Lantern scene from the script: the banter, the paper bag, the spoon, Henrik's call (answered by the player), the screw, "Straight back", the top button.
- The drive as a short film, with Mara's truck climbing the service road, the sign and the parked truck. Tomas waits in the cab.
- The clearing: the radio held over his head, the hands-on close-up of the radio's open back, their song through the speaker and then the shared headphones, the goodbye (`SIGNOFF`), the sticking lock, the vanishing, the walk to the flashlight.
- The aftermath as a film of 18 shots, with dialogue to tap through and captions for everything only seen or heard, plus **Skip**. New in it: the sheriff's 1980 cruiser with its light bar, Ruth's sedan, the search dog, two neighbours, the school photograph, the posters.
- 1983: the faded poster replaced; the locker beat in the corridor with the song on the radio, then the title.
- **Their song** (`tools/gen_song.py`): `song_clear.ogg` and `song_radio.ogg`, 59 s each and sample-aligned, so the game crossfades from the speaker to the headphones in time.
- **Consistency:** the tell in 12 is now Tomas's coat buttoned to the top (it was black tape on his cord). Eighty-One's shared memory is "Mostly" / "That means yes" (it was the polka hour). Sollen's 1980 log, the 1980 Ruth in the diner and the locker lines match the new night. The diner has a front window; in 1983 the poster hangs in it. Chapters: P1 *The Lantern, 1980*, P1b *The clearing*.
- Fixed on the way: in v0.5.0 the night shift began with the wrong objective (Act 1's "See who picked up…"); the prologue's hand-set objectives now stay until the lobby phone call.

**Walls** (`environment_art.gd`, `kit.gd`, `control_room.gd`)

- Corridor clock and notice, radiator and vending machine; the control room window frame (tight to the glass now), chalkboard and transmitter; vents behind windows; the lobby, east-wing and sheriff's notices; the diner's frame label.
- `--autotest=layout` checks every wall decoration against every hotspot.

**Speed** (`room.gd`, `station_room.gd`, `actor.gd`, every room, `display_settings.gd`, `hud.gd`, `audio_settings.gd`)

- Rooms keep their picture and redraw it only when something changes. What moves draws on its own layer each frame. Idle characters redraw at 12 Hz.
- `application/run/max_fps = 60`.
- **Settings → Display:** Battery saver (30 fps, 720p), Smooth edges (2× MSAA; off by default on phones), Show frame rate. Saved in `user://display_settings.cfg`.

**Tools and tests**

- New runs: `opening` (just the opening, for screenshots), `layout`, `perf`. The four story runs play the whole opening; two watch the film and two press Skip.

## Validation

See `docs/VALIDATION_v0.5.1.md`. Not yet played on a physical phone.
