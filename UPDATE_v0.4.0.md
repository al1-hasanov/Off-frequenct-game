# Off Frequency v0.4.0 — After Hours

This update improves presentation across the existing prologue and Acts 1–2. It does not add Act 3.

## Files

- **Full source:** complete editable Godot 4.6.3 project. Import `project.godot`.
- **Changed files:** paths relative to the project root. Overlay them on the supplied v0.3.2 source. No source files need deleting. Godot will regenerate `.godot` imports.
- **APK:** signed ARM64 + ARMv7 Android test build, minimum Android 7.0, version code 8.

## Android installation and saves

The APK installs as **Off Frequency 0.4**, package `com.alihasanov.offfrequency.ambience`. It can coexist with v0.3.2. Its saves are separate: installing this build does not import the old app's save. Keep the earlier installation if you want to preserve that progress. The debug chapter selector can recreate a desired chapter/choice combination in the new build.

The original private signing key was not present. Android requires the same package and signer to update an existing app. This build therefore uses a separate package and includes its new test key for repeatable future debug builds. To update the original package later, restore its original package ID and use its original signing key.

## Quick phone check

1. Open Sound & atmosphere in the title menu. Turn Background music OFF and press Done. Environmental wind and radio sounds remain.
2. Close and reopen the app: music should remain off. Turn it on and adjust the music slider.
3. Use Chapters (debug) to visit Main Street, Pike Radio, the diner, the observatory corridor and Ash Street. Look for clothing detail, brick/siding, wall props and layered ambient sound.
4. Pause using II or Android Back. Open Sound & atmosphere, adjust a slider, press Done, then Resume. Closing settings should keep the game paused until Resume.
5. Enter another room: the previous crowd/room layers fade away. Use the Tuner and listen for its cues under the quieter score.
6. In the mine, the score is suspended; the story's brief full silence remains.

## Implementation

- Original procedural music and atmosphere are encoded as 32 kHz stereo Ogg Vorbis. Long tracks are streamed rather than expanded into long PCM loops at runtime.
- Background score uses a separate Music bus/player. Existing radio/scanner cues stay on Ambience. New room beds feed Environment → Ambience.
- Volume settings are stored in `user://audio_settings.cfg`, with a short debounce on slider writes and an explicit save on closing settings/backgrounding.
- Room/frequency-specific ambient profiles prevent people sounds in empty alternate rooms. Score is reduced under dialogue and tuning, and stopped for the mine listening sequence.
- Existing story hotspots and choice logic remain intact. Additional visual work uses vector drawing, so no external model assets or downloaded artwork are required.
- Rebuild sounds with `python tools/gen_atmosphere.py` (numpy, scipy, ffmpeg required). All new recordings are original synthesis; no third-party audio or music samples are bundled.

## Validation

See `docs/VALIDATION_v0.4.0.md`. A physical-device playtest is still needed for phone-specific performance and speaker balance.
