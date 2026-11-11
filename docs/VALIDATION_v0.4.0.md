# Validation — Off Frequency v0.4.0

Built and checked on 12 November 2026 (Asia/Baku) with Godot 4.6.3.

| Check | Result |
| --- | --- |
| Compile all 19 room scripts and autoloads | Passed |
| Full story: answer / take Tomas | Passed |
| Full story: cut power / leave Tomas | Passed |
| Full story: answer / leave Tomas | Passed |
| Full story: cut power / take Tomas | Passed |
| Save and Continue, including alternate frequencies | Passed |
| Music toggle, zero volume, persistence, room changes and independent ambience | Passed |
| Paused settings, closing to pause, and Resume | Passed |
| Mine score suppression and re-enable on exit | Passed |
| Extra ambience fades when leaving a room | Passed |
| Six stereo Vorbis tracks decoded with finite samples and no clipped asset peaks | Passed |
| Settings layout at 1280×720 and 1920×800 | Passed; rendered and visually inspected |
| Act 2 rooms and alternate states | Rendered successfully; selected screenshots inspected |
| Android export, package/version, ARM64/ARMv7 libraries, signing and alignment | Passed |

The new decoded audio assets peak between 0.3974 and 0.7228 (normalized amplitude), before in-game attenuation. The music file is 64 seconds; each new ambient/radio file is 32 seconds.

The headless Dummy-audio runs can report unreleased Vorbis playback objects at engine shutdown; the rendered test runs complete with clean audio shutdown. There were no GDScript parse/runtime failures or failed gameplay assertions in the final checks. Software rendering reports an existing unsupported 2D MSAA warning.

No Android emulator or physical phone was used. APK signature/alignment and project behavior were checked here; actual device installation, audio balance and performance still need the phone checklist in `UPDATE_v0.4.0.md`.
