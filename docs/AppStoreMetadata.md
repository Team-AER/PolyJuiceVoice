# PolyJuiceVoice — App Store Connect Metadata

Draft submission copy. Recheck the target release, supported devices, timings and store configuration before submission; this document does not confirm App Store availability.

---

## App Name (max 30 chars)

```
PolyJuiceVoice
```

## Subtitle (max 30 chars)

```
On-device AI voice synthesis
```

## Promotional Text (max 170 chars — updatable without re-submission)

```
Clone any voice, design new ones from a description, or speak with built-in styles — 100% on-device. Optional iCloud sync shares saved voices across your devices.
```

---

## Description (max 4000 chars)

```
PolyJuiceVoice is on-device text-to-speech with three powerful capabilities -- powered by Apple's MLX framework so every word is synthesized locally on your Mac or iPhone. Saved voices stay local by default; optional iCloud sync transfers them through your private iCloud storage.

--- SPEAK ---
Pick a built-in voice and read any text aloud, with optional style guidance like "calm and warm" or "energetic and confident." Long passages stream as they're generated, with latency depending on your device and selected model.

--- DESIGN ---
Describe the voice you want -- "a wise narrator with a slight British lilt" -- and PolyJuiceVoice generates a brand-new speaker that matches. Save it to your library and reuse it for any future text.

--- CLONE ---
Record a few seconds of any voice (your own, or with the speaker's consent), then synthesize new sentences in that style. Perfect for personal voice messages, accessibility tools, audiobook drafts, and character voices.

NOTE: Use voice cloning only with the explicit consent of the person whose voice you record.

--- PRIVACY-FIRST ---
* On-device synthesis. Optional iCloud sync includes saved reference audio and voice metadata.
* No accounts, no analytics, no tracking.
* Download compatible model snapshots in Model Manager; size varies by family and precision. Installed models are cached locally until deleted.

--- BUILT FOR APPLE SILICON ---
Metal-accelerated inference via Apple's MLX framework for fast, energy-efficient synthesis. Designed for macOS 26 and iOS 26.

--- LANGUAGES ---
Built-in voices speak English, Chinese, Japanese, Korean, Spanish, French, and German. Export synthesized audio as WAV and share it anywhere.

Built on the open-source Qwen3-TTS model (Apache 2.0). Requires Apple Silicon.
```

---

## Keywords (max 100 chars, comma-separated)

```
tts,voice clone,ai voice,speech,narration,audiobook,on-device,offline,private,mlx,accessibility
```

*(99 characters — within limit)*

---

## URLs

| Field | Value |
|---|---|
| **Support URL** | `https://github.com/Team-AER/PolyJuiceVoice/issues` |
| **Marketing source** | `https://github.com/Team-AER/aer-landing/tree/main/polyjuicevoice` (use the confirmed hosted page for submission) |
| **Privacy Policy URL** | `https://github.com/Team-AER/PolyJuiceVoice/blob/main/docs/PRIVACY_POLICY.md` |

> The privacy policy file lives at `docs/PRIVACY_POLICY.md` in this repo. Push to GitHub and the raw URL above will work.

---

## Example release notes (adapt for the submitted version)

```
PolyJuiceVoice voice studio:

• Speak with built-in voices (Vivian, Ryan, and more) in 7 languages
• Design new voices from a free-text description
• Clone a voice from a short reference recording
• Save cloned and designed voices to your personal library
• Export synthesized audio as WAV
• On-device synthesis, with optional private iCloud voice-library sync
• Optimized for Apple Silicon via Apple's MLX framework
• Built for macOS 26 and iOS 26
```

---

## Notes for Apple Reviewer

> Review and adapt this draft for the exact submitted build.

```
PolyJuiceVoice downloads selected Qwen3-TTS model snapshots from
huggingface.co. Inference runs locally. Use Model Manager to download a
compatible snapshot for the capability being reviewed; the app displays
download progress.

A network connection is required for model downloads. Synthesis can run
locally after installation. Optional iCloud sync and sharing exported audio
can use the network.

The Voice Cloning feature requires microphone access to record a reference
audio sample, or accepts an imported audio file. Enter a matching reference
transcript manually. Inference is local; optional iCloud sync includes saved
reference recordings, embeddings and voice metadata.

There is no login or account required to test the app.
```

---

## Privacy Nutrition Label

Answer these questions in App Store Connect under **App Privacy**:

| Question | Answer |
|---|---|
| Does this app collect data linked to the user's identity? | **No** |
| Does this app collect data not linked to identity? | **No** |
| Does this app track users across apps/websites? | **No** |

These answers describe the intended developer data-collection behavior. Review them against the exact submitted build and Apple's current definitions, including optional iCloud behavior, before submitting.

---

## Age Rating

Answer **None** to every question in the questionnaire. Resulting rating: **4+**.

> One note: voice cloning can be misused. The description already includes the consent line — Apple does not currently require a higher age rating for this, but keep it in the description to demonstrate responsible disclosure.

---

## Categories

| | Category |
|---|---|
| **Primary** | Productivity |
| **Secondary** | Utilities |

---

## Pricing & Availability

- **Price**: Free (recommended for 1.0 to maximize adoption)
- **Availability**: All territories, or start with US/UK/CA/AU
- **Distribution**: App Store (not for Business or Education only)

---

## Screenshot Plan

Take screenshots in **dark mode** — the Liquid Glass effect reads best on a dark background. Required sizes:

**macOS** (at least one of): 1280×800 or 1440×900 px  
**iOS** (required): 6.9" — iPhone 16 Pro Max (1320×2868 px)

| # | Screen | What to show |
|---|---|---|
| 1 | **Speak** | Voice picker open, text filled in, waveform visible |
| 2 | **Design** | Voice description typed, Generate button prominent |
| 3 | **Clone** | Recording in progress, level meter active |
| 4 | **Library** | List of saved voices with names and types |
| 5 | **Export / Share** | Share sheet open after export |

---

## Pre-Submission Checklist

- [ ] GitHub repo is public (for support/privacy policy URLs to resolve)
- [ ] Privacy policy URL returns HTTP 200
- [ ] Support URL returns HTTP 200
- [ ] macOS archive builds cleanly with Release signing
- [ ] First-launch model download tested end-to-end on a physical device
- [ ] Microphone permission prompt tested: grant and deny flows both work
- [ ] Voice library round-trip: save a voice, force-quit, relaunch, verify it persists
- [ ] Reviewer Notes pasted into App Review Information in App Store Connect
- [ ] Age rating questionnaire completed (4+)
- [ ] Pricing set
- [ ] At least one screenshot uploaded per required device size
