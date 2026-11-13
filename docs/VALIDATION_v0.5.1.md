# Validation — Off Frequency v0.5.1

Built and checked on 12 November 2026 with Godot 4.6.3.

| Check | Result |
| --- | --- |
| Compile every room script (22 rooms + 3 debug lineups) and autoloads | Passed |
| Full story: answer / take Tomas (opening played through, film watched) | Passed, 144 checks |
| Full story: cut power / leave Tomas (film skipped) | Passed, 149 checks |
| Full story: answer / leave Tomas (film watched) | Passed, 147 checks |
| Full story: cut power / take Tomas (film skipped) | Passed, 146 checks |
| Save and Continue, including alternate frequencies | Passed, 31 checks |
| Chapter select: every chapter (now with P1b), every choice combination; states regenerated from the four runs | Passed, 141 checks |
| Sound and display settings: music toggle, volumes, persistence; battery saver (30 fps, 720p), smooth edges, frame counter, saved | Passed, 30 checks |
| Layout: every room's wall decorations clear of every hotspot; the control room's window frame clear of the chalkboard and transmitter | Passed, 143 checks |
| The opening rendered (`--autotest=opening --shots`), 91 screenshots inspected: the diner, the drive, the radio close-up at each stage, the clearing, all 18 shots of the aftermath, the locker | No script errors; reviewed |
| Room by room before/after screenshots of the static-drawing change (17 rooms) | Same pictures, apart from the intended wall fixes |
| `song_clear` and `song_radio`: same length (59.24 s), sample-aligned, peak 0.80 / 0.70 | Checked |
| Android export: package, version, ARM64 + ARMv7 libraries, v2 + v3 signature, zipalign | See below |

Total: 931 automated checks across eight runs, with every playable step required to have a working hint.

## Drawing time per frame

`--autotest=perf`, headless, frame cap and the headless frame sleep off, average of 120 frames after each room has loaded, on the build machine's CPU. This is the work the scripts do to draw a frame. The GPU's share isn't measured here, and on a phone both are several times slower.

| Room | v0.5.0 | v0.5.1 | |
| --- | ---: | ---: | ---: |
| Snowfield, 1980 | 2.04 ms | 0.28 ms | 7× |
| Main corridor | 0.72 ms | 0.04 ms | 18× |
| Receiver room | 0.86 ms | 0.12 ms | 7× |
| Control room | 0.94 ms | 0.20 ms | 5× |
| Lobby | 0.80 ms | 0.11 ms | 7× |
| East wing (01) | 0.72 ms | 0.04 ms | 18× |
| Sollen's office (01) | 1.20 ms | 0.04 ms | 30× |
| Basement | 0.72 ms | 0.03 ms | 24× |
| Garage (03) | 1.11 ms | 0.05 ms | 22× |
| Road down (03), all moving | 0.58 ms | 0.59 ms | — |
| Main Street | 4.15 ms | 0.26 ms | 16× |
| Pike Radio | 1.26 ms | 0.06 ms | 21× |
| Sheriff's office (05) | 1.21 ms | 0.04 ms | 30× |
| Ash Street (14) | 1.68 ms | 0.15 ms | 11× |
| Kitchen (14) | 1.41 ms | 0.04 ms | 35× |
| The Lantern (12) | 1.92 ms | 0.07 ms | 27× |
| Mine tunnel | 0.73 ms | 0.06 ms | 12× |
| The Lantern, 1980 (new) | — | 0.07 ms | |

A room's slowest frame is now the one where its kept picture is redrawn (on arrival, or when the story changes something in it). That frame costs about what every frame cost before.

## APK

`OffFrequency-v0.5.1-debug.apk`: package `com.alihasanov.offfrequency.v05`, label *Off Frequency 0.5*, version 0.5.1 (code 10), minimum SDK 24 (Android 7.0), target SDK 36. Signed with the same development key as the v0.5.0 test APK, so it updates that install in place.

Headless runs with the Dummy audio driver can report an unreleased Vorbis playback at engine shutdown; it happens only on that exit path. Software rendering reports the known unsupported 2D MSAA warning.

No Android emulator or physical phone was used. Touch feel of the radio close-up, speaker balance of the song, and real frame rates still need the phone checklist in `UPDATE_v0.5.1.md`. The frame counter (on by default in this build) shows the frame rate and the slowest frame of the last second.
