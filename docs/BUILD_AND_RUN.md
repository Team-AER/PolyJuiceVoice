# Build and run PolyJuiceVoice

## Requirements

- Apple silicon Mac, macOS 26+ and Xcode 26+ with the macOS/iOS 26 SDKs.
- Swift 6; dependencies resolve through Xcode's Swift Package Manager integration. Keep the committed `Package.resolved` versions when reproducing a build.
- Internet for initial package/model downloads and enough disk and memory for the chosen snapshot. The download manager checks available disk space; model sizes differ by capability, family and precision.
- For iOS inference, a physical iOS 26+ device, Developer Mode and your own signing team. The iOS Simulator is not a supported inference target.

## Clone, resolve and build

```bash
git clone https://github.com/Team-AER/PolyJuiceVoice.git
cd PolyJuiceVoice
open PolyJuiceVoice.xcodeproj
```

Select the **PolyJuiceVoice** scheme and **My Mac**. Let Xcode resolve packages, or choose **File → Packages → Resolve Package Versions**. Build and launch with ⌘R.

The command-line build checks compilation; it does not launch the app:

```bash
xcodebuild build \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'platform=macOS,arch=arm64'
```

For iOS, select a connected physical device and configure signing in Xcode. A generic device build is:

```bash
xcodebuild build \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'generic/platform=iOS'
```

## Install models and try a workflow

1. Launch the app and use the model setup prompt or **Settings → Model Storage** to open Model Manager.
2. Download a snapshot for the capability: **CustomVoice** for presets, **Base** for cloning, or **VoiceDesign** for description-based voices. Base also advertises preset support in the app's registry. VoiceDesign is 1.7B only.
3. Select the installed snapshot. A mode may request another download if it has no compatible installed selection.
4. In **Speak**, enter a short sentence, choose a preset and generate. In **Design**, provide a voice description and sample text. In **Clone**, record at least three seconds or import a reference file, type the matching transcript and the target text.
5. Play the generated audio and export/share its WAV. Save a designed/cloned voice to reuse it in Speak.

Model manifests are defined in [`ModelSnapshot.swift`](../PolyJuiceVoice/Core/ML/ModelSnapshot.swift), not by the old two-file FP16 conversion pipeline. The downloader fetches configuration, tokenizer, speech-tokenizer and safetensors files from Hugging Face. No Python conversion is required to run the app.

Managed storage roots are:

| Platform | Root |
|---|---|
| macOS | The app's Application Support directory, under `PolyJuiceVoice/MLXModels/` (sandboxed builds may resolve this inside the container) |
| iOS | The app's Documents directory, under `MLXModels/` |

Each snapshot has its own folder, such as `Qwen3TTS-0.6B-CustomVoice-4bit`, with the paths from its manifest. Use Model Manager as the supported setup route. The runtime no longer reads `POLYJUICEVOICE_MODELS_DIR`, and copying legacy `weights.npz` or `talker_weights.safetensors` folders will not satisfy installation validation. Models are not delivered with ODR.

Once compatible models are installed, synthesis runs locally. Optional iCloud library sync and explicitly sharing exports can use the network; see [Privacy](PRIVACY_POLICY.md).

## Tests and verification

```bash
xcodebuild test \
  -project PolyJuiceVoice.xcodeproj \
  -scheme PolyJuiceVoice \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:PolyJuiceVoiceTests
```

Hardware/model integration tests require their model prerequisites; a compilation or test pass alone does not establish speech quality on every supported device. For release profiling, choose **Release** in the scheme and use Instruments to inspect memory and Metal activity with the snapshots you intend to ship.

## Troubleshooting

| Symptom | Next action |
|---|---|
| Missing MLX module | Resolve the committed package versions in Xcode, then rebuild. |
| Unsupported SDK/deployment target | Check `xcodebuild -version` and select an Xcode installation with the 26 SDKs. |
| Missing or invalid snapshot | Use Model Manager to download/retry the required capability; check disk space and the app's debug log. |
| Memory pressure on iOS | Try a smaller compatible snapshot/precision and test on the physical target device. |
| Microphone denied | Grant microphone access in system settings or import an existing reference clip. |
| Voice cannot clone | Use a Base snapshot, usable reference audio and a matching transcript. The transcript is entered by the user, not automatically transcribed. |
| iCloud toggle has no immediate effect | Restart the app after changing sync; sign in to iCloud and configure entitlements for your own signed build. |

See [architecture](PRD.md), [script utilities](../scripts/README.md) and [vendored source attribution](../PolyJuiceVoice/Core/ML/MLX/Qwen3TTS/ATTRIBUTION.md).
