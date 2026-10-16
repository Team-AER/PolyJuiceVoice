# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PolyJuiceVoice is a **macOS-first** (also iOS) app for on-device text-to-speech synthesis with voice cloning and voice design capabilities. It uses MLX (Apple's machine learning framework) to run Qwen3-TTS models locally via Metal acceleration.

**Platform**: macOS 26+ (primary), iOS 26+ (secondary — maintained via `#if os(...)` conditionals)
**Language**: Swift 6.0 (strict concurrency enabled)
**ML Framework**: MLX via mlx-swift package
**Architecture**: MVVM with SwiftUI

## Build Commands

### Building the Project

```bash
# Build for macOS (primary target — runs directly, no device needed)
xcodebuild build \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'platform=macOS,arch=arm64'

# Build for physical iOS device (MLX needs Metal hardware)
xcodebuild build \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'generic/platform=iOS'
```

**IMPORTANT**: iOS Simulator does NOT work — MLX requires Metal hardware. macOS builds run directly on your Mac (no device needed).

### Model Setup

Use the app's Model Manager to download and select a capability-specific snapshot. Current loading uses `ModelDownloadManager.directory(for:)`; the legacy `POLYJUICEVOICE_MODELS_DIR` override is not read. See `docs/BUILD_AND_RUN.md` and `ModelSnapshot.swift` for storage roots and manifests.

### Running Tests

```bash
# Run tests on macOS (preferred — no device needed)
xcodebuild test \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:PolyJuiceVoiceTests

# Run tests on physical iOS device
xcodebuild test \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'platform=iOS,name=Your Device Name'
```

### Model Verification

```bash
# Verify model files are NOT bundled in app (should be empty output)
./verify_bundle_size.sh
```

## Architecture

### Core Components

1. **MLX Integration** (`PolyJuiceVoice/Core/ML/`)
   - `MLX/MLXTTSService.swift`: main synthesis service
   - `MLX/Qwen3TTS/`: vendored model, speech tokenizer and speaker encoder
   - `MLXRuntime.swift`: runtime configuration
   - `ModelSnapshot.swift`, `ModelDownloadManager.swift`, `ModelSelectionStore.swift`: snapshot manifests, downloads and selection

2. **Audio Pipeline** (`PolyJuiceVoice/Core/Audio/`)
   - `AudioEngine.swift`: AVAudioEngine wrapper for playback
   - `AudioRecorder.swift`: Recording for voice cloning
   - `AudioExporter.swift`: Export the generated WAV

3. **Storage** (`PolyJuiceVoice/Core/Storage/`)
   - `CoreDataStack.swift`: Core Data setup
   - `VoiceStorage.swift`: Voice library persistence
   - `VoiceEntity.swift`: Core Data entity

4. **Features** (`PolyJuiceVoice/Features/`)
   - `Synthesis/`: Text-to-speech synthesis UI
   - `VoiceDesign/`: Create voices from text descriptions
   - `VoiceCloning/`: Clone voices from audio samples
   - `VoiceLibrary/`: Manage saved voices

### Model Loading Architecture

`ModelSnapshot.swift` defines the supported capability/family/precision matrix and Hugging Face manifests. `ModelDownloadManager` downloads and validates the snapshot files in managed Application Support storage on macOS and Documents storage on iOS. `ModelSelectionStore` chooses snapshots per capability; `MLXTTSService` loads the selected folder through the vendored `Qwen3TTSModel.fromPretrained` implementation.

Base supplies cloning, CustomVoice supplies presets, and 1.7B VoiceDesign supplies description-based voices. Current runtime files are safetensors and accompanying configuration/tokenizer files. No ODR or Python conversion is used. The old separate `MLXQwen3TTSModel`, `MLXSpeechDecoder` and `WeightKeyMap` architecture no longer describes the source tree.

## Swift 6 Concurrency Patterns

This codebase uses Swift 6 strict concurrency. Key patterns:

### Actor Isolation
- `MLXTTSService`: `@MainActor` for UI updates
- Vendored `Qwen3TTSModel` and the MLX runtime supply the current inference implementation; check their isolation before changing cross-thread access
- Use `nonisolated` for initializers that don't access mutable state

### Sendability
- Use `@unchecked Sendable` for data-holding structs that are immutable
- Use `nonisolated(unsafe)` for stored properties needing cross-isolation access (use sparingly)
- Use `@preconcurrency import MLX` to suppress Sendable warnings for `MLXArray`

### Example Pattern
```swift
// Config structs: @unchecked Sendable + nonisolated init
struct MyConfig: @unchecked Sendable {
    let value: Int
    nonisolated init(json: [String: Any]) { ... }
}

// Actors with nonisolated init
actor MyModel {
    nonisolated init(modelPath: URL) async throws { ... }
}

// MainActor services
@MainActor
final class MyService: ObservableObject {
    @Published var state: State = .idle
}
```

## MLX API Compatibility

The committed package lockfile records mlx-swift v0.29.1 and mlx-swift-examples v2.29.1. Key API differences from older versions:

- `Conv1d`: Use `inputChannels`/`outputChannels` (not `inChannels`/`outChannels`)
- No `MLXRandom` module available - use `MLX.zeros()` for placeholder tensors
- `MLX.repeated()` signature changed - check current API docs

## File Organization Rules

### Model File Management

- Models are downloaded through Model Manager, not bundled for normal setup.
- Each capability/family/precision snapshot has its own folder; file names come from `ModelSnapshot.manifest`.
- `.gitignore` excludes large weight files. Do not commit downloaded models.
- Safetensors are the runtime weight format; legacy NPZ/PKL conversion outputs are not installed snapshots.

### Core Data
- Schema defined in `VoiceEntity.swift`
- Access via `VoiceStorage` actor wrapper, NOT directly

## Common Development Tasks

### Adding a New MLX Layer
1. Locate the relevant component under `PolyJuiceVoice/Core/ML/MLX/Qwen3TTS/` and preserve its upstream attribution
2. Use `nonisolated` functions for stateless operations
3. Use `nonisolated(unsafe)` for stored properties if needed (e.g., `Conv1d` modules)
4. Ensure all MLXArray operations are thread-safe

### Modifying Audio Pipeline
1. Edit `AudioEngine.swift` for playback changes
2. Use `AVAudioPCMBuffer` with 24kHz mono Float32 format
3. Always configure audio session: `.playback` category, `.spokenAudio` mode

### Adding New Voice Presets
1. Update `PresetVoice` enum in `PolyJuiceVoice/Core/Models/PresetVoice.swift`
2. Add voice metadata to tokenizer prompt templates if needed

## Testing Strategy

### Unit Tests
- Test MLX layers (Snake, RVQ, Conv) independently
- Mock `MLXArray` operations where possible
- Requires physical device (no simulator support)

### Integration Tests
- Test full synthesis pipeline with small test inputs
- Verify model loading from all fallback paths
- Check audio output format (24kHz, Float32, mono)

## Known Limitations

1. iOS Simulator inference is not supported; test on Metal hardware.
2. Snapshot downloads require gigabytes of storage, with size dependent on family and precision.
3. Memory use and speech quality need verification on the actual device/model combination.
4. Voice cloning needs a Base snapshot, a usable reference clip and a matching user-entered transcript.
5. iCloud sync is opt-in and requires a restart after toggling; do not describe all voice data as never leaving the device.

## Dependencies

- **mlx-swift** v0.29.1 (committed lockfile): Apple MLX framework bindings
- **SwiftUI**: UI framework
- **Core Data**: Voice library persistence
- **AVFoundation**: Audio playback and recording

## Model and documentation references

- `PolyJuiceVoice/Core/ML/ModelSnapshot.swift`: supported snapshots and manifests
- `PolyJuiceVoice/Core/ML/MLX/Qwen3TTS/ATTRIBUTION.md`: vendored inference provenance
- `docs/BUILD_AND_RUN.md`: current setup and test commands
- `docs/PRD.md`: current product and architecture
- `docs/PRIVACY_POLICY.md`: local inference, optional iCloud and export boundaries
- `scripts/README.md`: developer utilities
- `docs/ODR_IMPLEMENTATION_PLAN.md`: historical proposal, not implemented
