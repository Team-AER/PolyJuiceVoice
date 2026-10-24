//
//  SynthesisView.swift
//  PolyJuiceVoice
//
//  Speak tab. iOS 26 / macOS 26 Liquid Glass throughout: toolbar adopts
//  the system glass pill, primary CTA uses `.glassProminent`, the voice
//  picker and waveform sit on glass capsules / cards, and inputs use
//  `GlassTextEditor` / `GlassTextField` so the whole tab morphs together.
//

import SwiftUI

struct SynthesisView: View {

    @StateObject private var viewModel = SynthesisViewModel()
    @EnvironmentObject var container: DIContainer
    @EnvironmentObject var downloadManager: ModelDownloadManager
    @EnvironmentObject var selectionStore: ModelSelectionStore

    @Namespace private var voiceSelection
    @State private var auditionReveal: CGFloat = 0
    @State private var motionEpoch = 0
    @State private var scrubPosition = 0.0
    @State private var isScrubbing = false
    @State private var showingModelManager = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            Group {
                if let needs = viewModel.unconfiguredCapability {
                    centeredMissingPrompt(needs)
                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            GlassEffectContainer(spacing: 18) {
                                let wide = geometry.size.width >= 720
                                Group {
                                    if wide {
                                        HStack(alignment: .top, spacing: 24) {
                                            authoringSurface.frame(maxWidth: .infinity)
                                            playbackCard.frame(width: 300)
                                        }
                                    } else {
                                        VStack(alignment: .leading, spacing: 24) {
                                            authoringSurface
                                            playbackCard
                                        }
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 18)
                                .padding(.bottom, 110)
                            }
                        }
                    .accessibilityIdentifier("feature-scroll")
                    .scrollContentBackground(.hidden)
                    .scrollEdgeEffectStyle(.soft, for: .top)
                    .scrollDismissesKeyboard(.immediately)
                    .safeAreaInset(edge: .bottom) {
                        synthesizeButton
                            .padding(.horizontal, 18)
                            .padding(.bottom, 14)
                        }
                    }
                }
            }
            .navigationTitle("Speak")
            .toolbar { toolbarContent }
            .task {
                guard !UILayoutAudit.isEnabled else { return }
                await viewModel.setup(
                    ttsService: container.ttsService,
                    audioEngine: container.audioEngine,
                    voiceStorage: container.voiceStorage,
                    downloadManager: downloadManager,
                    selectionStore: selectionStore
                )
            }
            .onAppear {
                auditionReveal = viewModel.hasAudio ? 1 : 0
                Task { await viewModel.reloadVoiceOptions() }
            }
            .onChange(of: viewModel.hasAudio) { _, ready in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.48)) { auditionReveal = ready ? 1 : 0 }
            }
            .onChange(of: reduceMotion) { _, _ in
                // Recreate only the drawing host so an active reveal settles,
                // while text-entry and playback controls retain their identity.
                motionEpoch += 1
                auditionReveal = viewModel.hasAudio ? 1 : 0
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
            .sheet(isPresented: $showingModelManager, onDismiss: { Task { @MainActor in viewModel.retrySetup() } }) {
                ModelManagerView(focusCapability: viewModel.unconfiguredCapability)
                    .environmentObject(downloadManager)
                    .environmentObject(selectionStore)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarSpacer(.flexible, placement: .primaryAction)
        ToolbarItemGroup(placement: .primaryAction) {
            DebugLogToolbarButton()
            Button {
                showingModelManager = true
            } label: {
                Image(systemName: "internaldrive")
            }
            .accessibilityLabel("Models")
            .help("Manage downloaded models")
        }
    }

    // MARK: - Sections

    private func centeredMissingPrompt(_ capability: TTSCapability) -> some View {
        ScrollView {
            MissingCapabilityPrompt(capability: capability) {
                showingModelManager = true
            }
            .frame(maxWidth: 460)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
    }

    private var authoringSurface: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR WORDS, GIVEN A VOICE")
                    .font(.caption2.weight(.semibold)).tracking(1.2).foregroundStyle(.secondary)
                Text("\(viewModel.selectedOption.name)’s voice.")
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .foregroundStyle(.tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            voiceSelector
            textEditor
            instructionField
            languageSelector
        }
    }

    private func selectVoice(_ voice: VoiceOption) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.82)) {
            viewModel.selectedOption = voice
        }
    }

    private var voiceSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            FieldLabel(title: "Voice")

            VoicePillSection(
                title: "Presets",
                tint: .accentColor,
                options: presetOptions,
                selected: viewModel.selectedOption,
                namespace: voiceSelection,
                onSelect: selectVoice
            )

            if !savedOptions.isEmpty {
                VoicePillSection(
                    title: "Your Voices",
                    tint: .purple,
                    options: savedOptions,
                    selected: viewModel.selectedOption,
                    namespace: voiceSelection,
                onSelect: selectVoice
                )
            }
        }
    }

    /// Stock preset speakers — shipped with the app.
    private var presetOptions: [VoiceOption] {
        viewModel.voiceOptions.filter { if case .preset = $0 { return true } else { return false } }
    }

    /// User-saved cloned / designed voices.
    private var savedOptions: [VoiceOption] {
        viewModel.voiceOptions.filter { if case .saved = $0 { return true } else { return false } }
    }

    private var textEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: "Text to speak")
            GlassTextEditor(text: $viewModel.text,
                            minHeight: 140,
                            prompt: "Type or paste what this voice should say…")
        }
    }

    private var instructionField: some View {
        let isPreset: Bool = {
            if case .preset = viewModel.selectedOption { return true } else { return false }
        }()
        return Group {
            if isPreset {
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(title: "Style instruction (optional)")
                    GlassTextField(text: $viewModel.instruction,
                                   prompt: "e.g. Calm and warm")
                }
            }
        }
    }

    private var languageSelector: some View {
        HStack {
            FieldLabel(title: "Language")
            Picker("Language", selection: $viewModel.language) {
                ForEach(Language.allCases, id: \.self) { language in
                    Text(language.rawValue).tag(language)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            Spacer()
        }
    }

    private var playbackCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LISTENING STAGE").font(.caption2.weight(.semibold)).tracking(1.1).foregroundStyle(.white.opacity(0.65))
                    Text("Preview").font(.title2.weight(.semibold))
                }
                Spacer()
                Image(systemName: "waveform").font(.title2)
                    .foregroundStyle(.white.opacity(0.75))
                    .symbolEffect(.variableColor.iterative, options: .repeating,
                                  isActive: viewModel.isSynthesizing && !reduceMotion)
            }
            Text(viewModel.selectedOption.name).font(.callout.weight(.medium)).foregroundStyle(.white.opacity(0.8))
            ZStack {
                if viewModel.hasAudio {
                    WaveformView(samples: viewModel.waveformSamples,
                                 progress: isScrubbing ? scrubPosition : viewModel.playbackProgress,
                                 tint: .white, showsPlayhead: true)
                        .mask(alignment: .leading) {
                            Rectangle().scaleEffect(x: reduceMotion ? 1 : auditionReveal, y: 1, anchor: .leading)
                        }
                        .id(motionEpoch)
                        .accessibilityLabel("Waveform of synthesized audio")
                } else {
                    VStack(spacing: 12) {
                        if viewModel.isSynthesizing { ProgressView().tint(.white) }
                        Text(viewModel.isSynthesizing ? "Creating your audio…" : "Preview appears after Speak")
                            .font(.callout).foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity)
                }
            }
            .frame(height: 126)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
            if viewModel.hasAudio {
                VStack(spacing: 7) {
                    Slider(value: Binding(get: { isScrubbing ? scrubPosition : viewModel.playbackProgress },
                                          set: { scrubPosition = $0 }), in: 0...1) { editing in
                        if editing { scrubPosition = viewModel.playbackProgress }
                        isScrubbing = editing
                        if !editing { viewModel.seek(toProgress: scrubPosition) }
                    }
                    .tint(.white)
                    .accessibilityLabel("Playback position")
                    HStack {
                        Label(UILayoutAudit.showsSyntheticPreview ? "Synthetic preview" : "Audio ready", systemImage: "checkmark.circle")
                        Spacer()
                        if !UILayoutAudit.showsSyntheticPreview { Text(viewModel.playbackTimecode).monospacedDigit() }
                    }.font(.caption2).foregroundStyle(.white.opacity(0.75))
                }
            }
            #if DEBUG
            if UILayoutAudit.showsSyntheticPreview {
                Button(viewModel.hasAudio ? "Reset synthetic preview" : "Show synthetic preview") { viewModel.toggleSyntheticPreview() }
                    .font(.caption)
                Text("Visual fixture only · no audio generated").font(.caption2).foregroundStyle(.white.opacity(0.65))
            }
            #endif
                AdaptiveControlRow {
                    HStack(spacing: 18) {
                        Button {
                            viewModel.seekBackward()
                        } label: {
                            Image(systemName: "gobackward.10").font(.title2)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .accessibilityLabel("Skip back 10 seconds")
                        .disabled(!viewModel.hasAudio)
                        .keyboardShortcut(.leftArrow, modifiers: [.command])

                        Button {
                            viewModel.togglePlayback()
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
                        .disabled(!viewModel.hasAudio)
                        .keyboardShortcut(.space, modifiers: [])

                        Button {
                            viewModel.seekForward()
                        } label: {
                            Image(systemName: "goforward.10").font(.title2)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .accessibilityLabel("Skip forward 10 seconds")
                        .disabled(!viewModel.hasAudio)
                        .keyboardShortcut(.rightArrow, modifiers: [.command])

                    }
                } trailing: {

                    if let url = viewModel.exportURL {
                        ShareLink(item: url) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .keyboardShortcut("e", modifiers: [.command])
                    } else {
                        Button {
                            viewModel.export()
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .accessibilityLabel("Export audio")
                        .disabled(!viewModel.hasAudio)
                        .keyboardShortcut("e", modifiers: [.command])
                    }
                }
        }
        .padding(22)
        .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.08, green: 0.24, blue: 0.44), Color(red: 0.035, green: 0.10, blue: 0.22)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.16), lineWidth: 0.5))
        .shadow(color: .blue.opacity(0.12), radius: 22, y: 10)
        .environment(\.colorScheme, .dark)
    }

    private var synthesizeButton: some View {
        PrimaryActionButton(
            title: "Speak",
            isWorking: viewModel.isSynthesizing,
            isEnabled: viewModel.canSynthesize
        ) {
            Task { await viewModel.synthesize() }
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .accessibilityLabel("Synthesize speech")
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { newValue in if !newValue { viewModel.clearError() } }
        )
    }
}

// MARK: - Voice pill section

/// One labelled, color-coded row of voice pills. Presets and saved voices
/// each get their own section so the user can tell them apart at a glance.
private struct VoicePillSection: View {
    let title: LocalizedStringKey
    let tint: Color
    let options: [VoiceOption]
    let selected: VoiceOption
    let namespace: Namespace.ID
    let onSelect: (VoiceOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options) { option in
                        VoicePill(
                            label: option.name,
                            tint: tint,
                            isSelected: option == selected,
                            namespace: namespace,
                            onTap: { onSelect(option) }
                        )
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 1)   // breathing room for the focus ring
            }
        }
    }
}

/// Single voice pill — accent-tinted capsule when selected, thin material
/// otherwise. Cheap to render (no per-pill `.glassEffect`).
private struct VoicePill: View {
    let label: String
    let tint: Color
    let isSelected: Bool
    let namespace: Namespace.ID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(Color.primary))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        if reduceMotion {
                            selectedCapsule
                        } else {
                            selectedCapsule.matchedGeometryEffect(id: "selected-voice", in: namespace)
                        }
                    } else {
                        Capsule(style: .continuous)
                            .fill(.thinMaterial)
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(.separator.opacity(0.35), lineWidth: 0.5)
                            )
                    }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }

    private var selectedCapsule: some View {
        Capsule(style: .continuous).fill(tint.opacity(0.18))
            .overlay(Capsule(style: .continuous).strokeBorder(tint.opacity(0.55), lineWidth: 1))
    }
}

#Preview {
    SynthesisView()
        .environmentObject(DIContainer())
        .environmentObject(ModelDownloadManager())
        .environmentObject(ModelSelectionStore())
}
