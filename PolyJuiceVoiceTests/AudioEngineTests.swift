//
//  AudioEngineTests.swift
//  PolyJuiceVoiceTests
//

import XCTest
import AVFAudio
@testable import PolyJuiceVoice

@MainActor
final class AudioEngineTests: XCTestCase {

    var audioEngine: AudioEngine!

    override func setUp() {
        audioEngine = AudioEngine()
    }

    override func tearDown() {
        audioEngine.stop()
        audioEngine = nil
    }

    // MARK: - Initialization Tests

    func testAudioEngineInitializes() {
        XCTAssertNotNil(audioEngine)
        XCTAssertFalse(audioEngine.isPlaying)
        XCTAssertEqual(audioEngine.currentTime, 0)
    }

    // MARK: - Stream Playback Tests

    func testPlayStreamWithAudioChunks() async throws {
        // Create a simple audio stream
        let stream = createTestAudioStream(chunkCount: 5, samplesPerChunk: 4800)

        // Play the stream (should complete without errors)
        try await audioEngine.playStream(stream)

        // After playback, should not be playing
        XCTAssertFalse(audioEngine.isPlaying)
    }

    func testPlayStreamMultipleTimes() async throws {
        for _ in 0..<3 {
            let stream = createTestAudioStream(chunkCount: 2, samplesPerChunk: 2400)
            try await audioEngine.playStream(stream)
            XCTAssertFalse(audioEngine.isPlaying)
        }
    }

    func testStopPlayback() async throws {
        let stream = createTestAudioStream(chunkCount: 10, samplesPerChunk: 24000)

        Task {
            try? await audioEngine.playStream(stream)
        }

        // Give it time to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Stop playback
        audioEngine.stop()

        XCTAssertFalse(audioEngine.isPlaying)
    }

    // MARK: - Audio Format Tests

    func testAudioChunkConversion() async throws {
        let chunk = AudioChunk(
            samples: Array(repeating: 0.5, count: 4800),
            sampleRate: 24000,
            timestamp: 0
        )

        // Create stream with this chunk
        let stream = AsyncThrowingStream<AudioChunk, Error> { continuation in
            continuation.yield(chunk)
            continuation.finish()
        }

        // Should not throw when playing
        try await audioEngine.playStream(stream)
    }

    func testHandlesInvalidAudioChunk() async throws {
        // Chunk with out-of-range samples
        let chunk = AudioChunk(
            samples: [2.0, -2.0, 10.0], // Out of [-1, 1] range
            sampleRate: 24000,
            timestamp: 0
        )

        let stream = AsyncThrowingStream<AudioChunk, Error> { continuation in
            continuation.yield(chunk)
            continuation.finish()
        }

        // Should still handle gracefully (clipping internally)
        try await audioEngine.playStream(stream)
    }

    // MARK: - State Tests

    func testIsPlayingState() async throws {
        let stream = createTestAudioStream(chunkCount: 2, samplesPerChunk: 4800)

        XCTAssertFalse(audioEngine.isPlaying, "Should not be playing initially")

        // Play stream and verify state after completion
        try await audioEngine.playStream(stream)

        XCTAssertFalse(audioEngine.isPlaying, "Should not be playing after completion")
    }

    func testSeekingKeepsTheNewSegmentPlayingWhenOldCompletionReturns() async throws {
        let url = try silentFile(seconds: 5)
        defer { try? FileManager.default.removeItem(at: url) }
        let first = Task { try await audioEngine.playFile(url) }
        try await Task.sleep(for: .milliseconds(100))
        let replacement = Task { try await audioEngine.playFile(url, from: 2) }
        try await Task.sleep(for: .milliseconds(150))
        try await first.value
        XCTAssertTrue(audioEngine.isPlaying)
        XCTAssertGreaterThanOrEqual(audioEngine.currentTime, 2)
        audioEngine.stop()
        try await replacement.value
    }

    func testSeekingToTheEndStopsAndKeepsTheActualEndpoint() async throws {
        let url = try silentFile(seconds: 2)
        defer { try? FileManager.default.removeItem(at: url) }
        let playing = Task { try await audioEngine.playFile(url) }
        try await Task.sleep(for: .milliseconds(100))
        try await audioEngine.playFile(url, from: 99)
        try await playing.value
        XCTAssertFalse(audioEngine.isPlaying)
        XCTAssertEqual(audioEngine.currentTime, 2, accuracy: 0.001)
        XCTAssertEqual(audioEngine.duration, 2, accuracy: 0.001)
    }

    private func silentFile(seconds: Double) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1))
        let frames = AVAudioFrameCount(seconds * 24000)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }

    // MARK: - Helper Methods

    private func createTestAudioStream(chunkCount: Int, samplesPerChunk: Int) -> AsyncThrowingStream<AudioChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for i in 0..<chunkCount {
                    // Generate simple sine wave for testing
                    var samples: [Float] = []
                    for j in 0..<samplesPerChunk {
                        let t = Double(i * samplesPerChunk + j) / 24000.0
                        let sample = Float(sin(2 * Double.pi * 440 * t)) * 0.3
                        samples.append(sample)
                    }

                    let chunk = AudioChunk(
                        samples: samples,
                        sampleRate: 24000,
                        timestamp: Date().timeIntervalSince1970
                    )

                    continuation.yield(chunk)

                    // Small delay between chunks
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                continuation.finish()
            }
        }
    }

    private func createSilentAudioChunk(sampleCount: Int) -> AudioChunk {
        AudioChunk(
            samples: Array(repeating: 0.0, count: sampleCount),
            sampleRate: 24000,
            timestamp: Date().timeIntervalSince1970
        )
    }
}
