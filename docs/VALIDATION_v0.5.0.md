# Validation — Off Frequency v0.5.0

Built and checked on 12 November 2026 (Asia/Baku) with Godot 4.6.3.

| Check | Result |
| --- | --- |
| Compile every room script (19 rooms + 3 debug lineups) and autoloads | Passed |
| Full story: answer / take Tomas | Passed, 127 checks |
| Full story: cut power / leave Tomas | Passed, 131 checks |
| Full story: answer / leave Tomas | Passed, 130 checks |
| Full story: cut power / take Tomas | Passed, 128 checks |
| Save and Continue, including alternate frequencies | Passed, 8 checks |
| Chapter select: every chapter, every choice combination (states regenerated from the four runs above) | Passed, 138 checks |
| Music toggle, volumes, persistence, room ambience, the 180 s score | Passed, 25 checks |
| `FRACTURE` stays 0 on the required route; a repeated crossing frays and says so | Passed (in the story runs) |
| Notebook: right notes present, wrong pairs refused, right pairs become theories | Passed (in the story runs) |
| Rendered playthrough (answer / take Tomas), 148 screenshots inspected | No script errors; screenshots reviewed |
| Character, pose and vehicle sheets (`--autotest=lineup`), snowcat in the garage and on the road (`--autotest=vehicles`) | Rendered and inspected |
| `tools/gen_audio.py` after the change: every one of the other 50 sounds byte-identical to before | Passed |
| Loops seamless (score and the four vehicle loops) | Passed: no step at the wrap larger than an ordinary sample step |
| Android export: package, version, ARM64 + ARMv7 libraries, v2 + v3 signature, zipalign | Passed |

Total: 687 automated checks across seven runs, with every step required to have a working hint.

**Sound files.** `night_score.ogg` is 180 s. The new vehicle sounds, with their peaks after loudness matching, are: `engine` 4.0 s loop (0.48), `tracks` 4.0 s loop (0.23), `truck_idle` 4.0 s loop (0.83), `plow` 6.0 s loop (0.47), `engine_start` 3.6 s (0.77), `engine_stop` 2.2 s (0.93), `starter` 2.4 s (0.55) and `truck_start` 3.0 s (0.66). Levels are matched by A-weighted loudness to the v0.4 sounds they replace.

**APK.** `OffFrequency-v0.5.0-debug.apk`: package `com.alihasanov.offfrequency.v05`, label *Off Frequency 0.5*, version 0.5.0 (code 9), minimum SDK 24 (Android 7.0), target SDK 36. It is signed with a development key, because the key that signed your v0.4 isn't in the repository, so it installs alongside v0.4 rather than over it (see `UPDATE_v0.5.0.md`).

Headless runs with the Dummy audio driver can report an unreleased Vorbis playback at engine shutdown; it happens only on that exit path. Software rendering reports the known unsupported 2D MSAA warning.

No Android emulator or physical phone was used. Installation, touch feel, speaker balance (the engines were given extra mid-range so phone speakers carry them) and performance still need the phone checklist in `UPDATE_v0.5.0.md`.
