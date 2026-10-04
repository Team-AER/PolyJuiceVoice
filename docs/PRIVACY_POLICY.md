# Privacy Policy

**App:** PolyJuiceVoice  
**Developer:** AER  
**Contact:** prafiles@gmail.com  
**Effective Date:** May 6, 2026

---

## Summary

PolyJuiceVoice processes everything **on your device**. We do not collect, transmit, or sell any personal data. Synthesis runs locally. Network activity includes model downloads from Hugging Face and optional iCloud sync between your own devices, which is off by default and described below. Exporting or sharing generated audio sends it to the destination you choose.

---

## What We Collect

### Microphone Audio
When you use the Voice Cloning feature, the app records short voice samples through your microphone — for example, you reading a passage of text aloud — so that the synthesizer can create a voice that matches the timbre and style of your recording. This audio is:
- Processed entirely on-device using Apple's Metal framework
- Held in a temporary recording buffer during capture and only saved to your Voice Library when you explicitly choose to save the cloned voice
- Not uploaded to a synthesis service; optional iCloud sync transfers saved reference audio to Apple's private iCloud storage under your account
- If — and only if — you turn on iCloud Sync in Settings, included in the items that sync between your own devices via your private iCloud container (see the iCloud Sync section below)

### Reference Transcripts
When cloning a voice, you enter the transcript that matches the reference recording. The current app does not automatically transcribe recordings. The entered transcript is paired with the reference and saved alongside a cloned voice when you save it to the Voice Library. Optional iCloud sync includes this saved metadata.

### Voice Library Data
Voices you create or clone are saved locally using Core Data on your device. This data:
- Remains on your device by default
- Can be deleted at any time from within the app
- Is synced between your own devices via your private iCloud container only if you turn on iCloud Sync in Settings (see the iCloud Sync section below)

### iCloud Sync (Optional, Off by Default)
PolyJuiceVoice can optionally sync your Voice Library across the devices signed in to your Apple ID. This feature:
- Is **off by default** — you must explicitly enable it in Settings, and a restart is required for the change to take effect
- Uses your own **private iCloud container** (`iCloud.app.aer.PolyJuiceVoice`) via Apple's CloudKit and iCloud Documents — your data is stored under your Apple ID, not on any server we operate, and we have no access to it
- Syncs voice profile metadata (name, language, instruction text, creation date) along with the associated reference audio recordings and voice embedding files
- Sync is governed by Apple's [iCloud Privacy](https://www.apple.com/legal/privacy/data/en/icloud/) policies once data is in your iCloud account
- Can be disabled at any time in Settings; turning it off stops further syncing and the data already on your other devices remains under your control via Apple's iCloud management tools

### Model Downloads
Model Manager downloads the model snapshots you select from Hugging Face (`huggingface.co`). Download sizes vary with the selected family, capability and precision and require gigabytes of storage. After the initial download:
- The models are cached locally
- Synthesis uses the installed model locally; downloading another snapshot, optional iCloud sync or sharing an export can use the network
- The model downloader requests model files, not your synthesis text or reference audio; the download service receives normal connection/request metadata

---

## What We Do Not Collect

- No account or registration is required
- No analytics or usage data is collected
- No crash reports are transmitted
- No advertising identifiers are used
- No data is sold or shared with third parties

---

## Data Storage

By default, model snapshots use Application Support on macOS and Documents on iOS. Voice metadata uses Core Data; reference audio and embeddings use the app's Documents/Voices directory. Temporary recordings and generated WAV files use temporary storage before saving/export. Sandboxed builds resolve these locations inside the app container.

If you have enabled iCloud Sync, the same data is also stored in your private iCloud container under your Apple ID and replicated across your devices.

You can delete all app data by uninstalling the app. If iCloud Sync was enabled, you can additionally manage or delete the data stored in your iCloud account via System Settings → Apple ID → iCloud → Manage Account Storage on Apple's platforms.

---

## Permissions

| Permission | Purpose |
|---|---|
| Microphone | Record short reference clips (e.g. you reading a passage aloud) so the app can clone your voice. Recordings stay on-device and are only saved to your Voice Library when you choose to save the voice. |
| Network (outgoing) | Download AI model weights on first launch; iCloud Sync traffic if you enable it |
| File Access (user-selected) | Export synthesized audio to locations you choose via the system save dialog |
| iCloud (CloudKit + iCloud Documents) | Optional sync of your Voice Library between your own devices via your private iCloud container. Off by default. |

---

## Children's Privacy

PolyJuiceVoice does not knowingly collect any information from children under 13. The app requires no account and transmits no personal data.

---

## Changes to This Policy

If we update this policy, we will revise the Effective Date above. Continued use of the app after changes constitutes acceptance of the updated policy.

---

## Contact

Questions about this privacy policy? Email us at **prafiles@gmail.com**.
