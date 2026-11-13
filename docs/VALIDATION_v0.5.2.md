# Validation — Off Frequency v0.5.2

Built and checked on 12 November 2026 with Godot 4.6.3.

| Check | Result |
| --- | --- |
| Compile every room script (22 rooms + 3 debug lineups) and autoloads | Passed |
| Full story: answer / take Tomas (opening played through, film watched) | Passed, 144 checks |
| Full story: cut power / leave Tomas (film skipped) | Passed, 149 checks |
| Full story: answer / leave Tomas (film watched) | Passed, 147 checks |
| Full story: cut power / take Tomas (film skipped) | Passed, 146 checks |
| Save and Continue, including alternate frequencies | Passed, 31 checks |
| Chapter select: every chapter, every choice combination | Passed, 141 checks |
| Sound and display settings | Passed, 30 checks |
| Layout: every room's wall decorations clear of every hotspot | Passed, 143 checks |
| Stations (`--autotest=glimpses`): all 100 stations have a world, the story's six keep the snowy night, the quiet ones are empty, the dial reaches all four seasons, Ash Street, Main Street, the garage and the Lantern each return to their own night after tuning | Passed, 112 checks |
| 17 stations photographed in each of the four places that tune (68 screenshots) | Reviewed |
| The opening rendered (`--autotest=opening --shots`), 91 screenshots: the redrawn workbench, windscreen, interview, photograph, duplicator, pole, night shift, porch and living room | Reviewed |
| Kept pictures against the v0.5.1 drawing, room by room at 2400×1080 | Same pictures (differences only where something moves: snow, dust, idle breathing) |
| 1980 Mara beside Mara in the character lineup | Reviewed |
| Android export: package, version, ARM64 + ARMv7 libraries, v2 + v3 signature, zipalign | See below |

Total: 1,043 automated checks across nine runs, with every playable step required to have a working hint.

## Frame cost

`--autotest=perf` with the GL renderer (Mesa llvmpipe under Xvfb), each room loaded and then sampled frame by frame at real speed. Draw calls are what a phone's GPU driver pays for one by one, every frame: v0.5.1 sent every shape of the room and of every person each time. The v0.5.1 column is the same measurement on the v0.5.1 code.

| Room | v0.5.1, every frame | v0.5.2, frame with nobody redrawn | v0.5.2, average at 60 fps | |
| --- | ---: | ---: | ---: | ---: |
| The Lantern, 1980 (opening, 4 people) | 1,017 | 35 | ~130 | 7.8× |
| Snowfield, 1980 | 1,268 | 31 | ~92 | 13.8× |
| Main corridor | 336 | 24 | ~67 | 5.0× |
| Receiver room | 504 | 30 | ~73 | 6.9× |
| Control room | 506 | 32 | ~75 | 6.8× |
| Lobby | 401 | 22 | ~65 | 6.2× |
| East wing (01) | 320 | 26 | ~69 | 4.7× |
| Sollen's office (01) | 492 | 22 | ~74 | 6.7× |
| Basement | 294 | 21 | ~68 | 4.3× |
| Garage (03) | 608 | 32 | ~72 | 8.4× |
| Road down (03), everything moving | 448 | 329 | 329 | 1.4× |
| Main Street (5 people) | 2,485 | 44 | ~172 | 14.5× |
| Pike Radio | 612 | 58 | ~118 | 5.2× |
| Sheriff's office (05) | 479 | 26 | ~90 | 5.3× |
| Ash Street (14) | 1,663 | 23 | ~66 | 25× |
| Kitchen (14) | 595 | 25 | ~95 | 6.3× |
| The Lantern (12) | 803 | 35 | ~120 | 6.7× |
| Mine tunnel | 295 | 63 | ~110 | 2.7× |

A person standing still is redrawn into their own texture 12 times a second (Mara) or 6 (everyone else), at most two people in any one frame; each redraw costs about 210 draw calls into a small texture. The average column adds those redraws to the frame where nobody is redrawn, for 60 frames a second with everyone standing still. While someone walks they are redrawn every frame (about +210). The road down keeps its sky and mountains and redraws the road, the pines and the snowcat every frame. A station change while tuning redraws the kept picture once (one frame at about the v0.5.1 cost).

The kept picture and the people are rendered at the screen's own resolution and shown one texel per pixel, so edges and text are as sharp as before (compared side by side at 2400×1080).

## APK

`OffFrequency-v0.5.2-debug.apk`: package `com.alihasanov.offfrequency.v05`, label *Off Frequency 0.5*, version 0.5.2 (code 11), minimum SDK 24 (Android 7.0), target SDK 36, ARM64 and ARMv7 libraries. Zipalign verified; signature verified (v2 + v3), certificate SHA-256 `c784acae…de2692`, the same development key as the v0.5.0 and v0.5.1 test APKs, so it updates that install in place. The new classes (`Env`, `LindHouse`) are in its class cache.

Headless runs with the Dummy audio driver can report an unreleased Vorbis playback at engine shutdown; it happens only on that exit path.

No Android emulator or physical phone was used. Real frame rates, and the look of each station on the phone's screen, still need the phone checklist in `UPDATE_v0.5.2.md`.
