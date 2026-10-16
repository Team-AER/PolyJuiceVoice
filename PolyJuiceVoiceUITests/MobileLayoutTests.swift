import XCTest

#if targetEnvironment(simulator)
@MainActor
final class MobileLayoutTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testFirstRunAndModelsInPortraitAndLandscape() {
        let app = launch(firstRun: true)
        let chooseModel = app.buttons["Choose a Model"]
        XCTAssertTrue(chooseModel.waitForExistence(timeout: 15))
        capture(app, "setup-portrait")

        XCUIDevice.shared.orientation = .landscapeRight
        reveal(chooseModel, in: app)
        assertOnScreen(chooseModel, in: app)
        capture(app, "setup-landscape-scrolled")
        chooseModel.tap()
        XCTAssertTrue(app.navigationBars["Models"].waitForExistence(timeout: 5))
        capture(app, "models-landscape")

        XCUIDevice.shared.orientation = .portrait
        capture(app, "models-portrait")
        let capability = app.descendants(matching: .any)["model-capability-picker"].firstMatch
        XCTAssertTrue(capability.waitForExistence(timeout: 5))
        assertOnScreen(capability, in: app)
        capability.tap()
        app.buttons["Voice Design"].firstMatch.tap()
        capture(app, "models-design-portrait")
        let precision = app.buttons["4-bit precision"].firstMatch
        reveal(precision, in: app)
        assertOnScreen(precision, in: app)
        capture(app, "models-precision-grid")
        app.buttons["Done"].tap()
        XCTAssertTrue(chooseModel.waitForExistence(timeout: 5))
    }

    func testWorkspaceScreensAndKeyboard() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Speak"].waitForExistence(timeout: 15))
        capture(app, "speak-portrait")
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("A short mobile layout audit.")
        capture(app, "speak-keyboard")
        // The audit launch has no synthesis service. This exercises the real
        // CTA's keyboard dismissal without loading a model or generating audio.
        app.buttons["Synthesize speech"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        mainScroll(in: app).swipeUp()
        reveal(app.buttons["Export audio"], in: app)
        assertOnScreen(app.buttons["Skip back 10 seconds"], in: app)
        assertOnScreen(app.buttons["Export audio"], in: app)
        capture(app, "speak-playback-portrait")

        for tab in ["Design", "Clone"] {
            selectTab(tab, in: app)
            capture(app, "\(tab.lowercased())-portrait")
            reveal(app.buttons["Save Voice"], in: app)
            assertOnScreen(app.buttons["Save Voice"], in: app)
            assertOnScreen(app.buttons["Export"], in: app)
            capture(app, "\(tab.lowercased())-playback-portrait")
        }

        selectTab("Library", in: app)
        capture(app, "library-portrait")
        selectTab("Settings", in: app)
        capture(app, "settings-portrait")
        let debugLog = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Debug log")).firstMatch
        reveal(debugLog, in: app)
        debugLog.tap()
        capture(app, "debug-log-portrait")
    }

    func testLargeTextPlaybackAndModels() {
        let app = launch(largeText: true)
        XCTAssertTrue(app.tabBars.buttons["Speak"].waitForExistence(timeout: 15))
        for tab in ["Speak", "Design", "Clone"] {
            selectTab(tab, in: app)
            mainScroll(in: app).swipeUp()
            mainScroll(in: app).swipeUp()
            let export = app.buttons[tab == "Speak" ? "Export audio" : "Export"]
            reveal(export, in: app)
            assertOnScreen(export, in: app)
            if tab != "Speak" { assertOnScreen(app.buttons["Save Voice"], in: app) }
            capture(app, "\(tab.lowercased())-large-text")
        }
        app.buttons["Models"].tap()
        capture(app, "models-large-text")
        XCTAssertTrue(app.descendants(matching: .any)["model-capability-picker"].firstMatch.exists)
    }

    private func launch(firstRun: Bool = false, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-layout-audit"]
        if firstRun { app.launchArguments.append("--ui-first-run") }
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        }
        app.launch()
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && mainScroll(in: app).frame.contains(element.frame) { return }
            mainScroll(in: app).swipeUp()
        }
    }

    private func mainScroll(in app: XCUIApplication) -> XCUIElement {
        let models = app.scrollViews["model-scroll"]
        if models.exists { return models }
        let feature = app.scrollViews["feature-scroll"]
        return feature.exists ? feature : app.scrollViews.firstMatch
    }

    private func selectTab(_ title: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[title]
        if !tab.isHittable { mainScroll(in: app).swipeDown() }
        tab.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
    }

    private func assertOnScreen(_ element: XCUIElement, in app: XCUIApplication,
                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.exists, file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.frame.minX, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX, file: file, line: line)
        XCTAssertTrue(app.frame.intersects(element.frame), file: file, line: line)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
