# PolyJuiceVoice development utilities

No Python conversion is required to run the app. Model Manager downloads the capability/family/precision snapshots described by [`ModelSnapshot.swift`](../PolyJuiceVoice/Core/ML/ModelSnapshot.swift). See [Build and run](../docs/BUILD_AND_RUN.md) for current setup; the old two-folder FP16/decoder layout and `POLYJUICEVOICE_MODELS_DIR` override are obsolete.

| Utility | Purpose |
|---|---|
| `export_tokenizer.py` | Developer utility for exporting tokenizer resources; not run by the app or build. Current snapshots also download tokenizer files through their manifest. |
| `update_xcode_settings.py` | Batch-edit Xcode project settings; review its changes before using them. |
| `generate_app_icon.swift` | Generate the established native app icon. The committed AppIcon assets are used by the app and README. |

The old `mlx_models_fp16*` and `model_cache` directories are conversion-era outputs, not the current download path. The committed legacy config files do not constitute installed models.

Run current tests from the repository root, following [the setup guide](../docs/BUILD_AND_RUN.md). There is no `WeightKeyAuditTests` suite or `WeightKeyMap.swift` in the current tree; inference now uses the vendored Qwen3TTS implementation documented in [ATTRIBUTION.md](../PolyJuiceVoice/Core/ML/MLX/Qwen3TTS/ATTRIBUTION.md).
