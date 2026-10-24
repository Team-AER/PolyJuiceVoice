# UI verification · 24 October 2026

Speak's existing glass player now explains the empty and generating states and labels confirmed audio as ready. The helper crossfades into the waveform inside the same fixed-height slot (160ms); the system Reduce Motion preference disables that custom fade. Voice capsules, field order, glass styling and the Speak action stay in place.

Screenshots show the actual macOS app and iPhone simulator in `--ui-layout-audit` mode. This existing debug-only audit mode now also works on Mac, allowing UI inspection without model download/loading. Empty/player controls were inspected and scrolled in the Mac app. The existing iPhone UI test passed, scrolling the full Preview helper and controls above the floating Speak action. A debug-only --ui-synthetic-preview toggle drove the real Mac card empty→synthetic waveform→empty; both transitions completed and kept the fixed slot. The fixture is labeled and generates no audio. No speech synthesis or recording was performed.

Validation: macOS and iOS-simulator Xcode builds passed. These screenshots verify the empty UI and a synthetic ready-state transition, not successful synthesis, audio quality, exact 160ms frame timing or physical iPhone playback. The Reduce Motion guard is source-verified; changing the OS preference and exercising that runtime branch remain unverified.
