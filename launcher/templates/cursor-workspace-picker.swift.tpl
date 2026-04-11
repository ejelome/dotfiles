import AppKit

final class PickerDelegate: NSObject, NSWindowDelegate {
    private enum UI {
        static let minWidth: CGFloat = 280
        static let maxWidth: CGFloat = 480
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 20
        static let stackSpacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 8
        static let iconSize: CGFloat = 64
        static let subtitleFontSize: CGFloat = 13
        static let checkboxFontSize: CGFloat = 13
        /// Floor only for empty list; otherwise viewport grows with content (no forced empty band).
        static let scrollEmptyMinHeight: CGFloat = 48
        /// Same inset on all sides inside the list bezel (tighter than window padding so the list does not feel padded twice).
        static let scrollContentInset: CGFloat = 10
        /// Small slack so content height rounding / bezel does not trigger a vertical scroller.
        static let scrollHeightSlack: CGFloat = 4
    }

    private let pickerTitles: [String] = [__PICKER_ITEMS__]
    private let workspacePaths: [String] = [__WORKSPACE_PATHS__]
    private let defaultSelectionIndex: Int = __DEFAULT_SELECTION_INDEX__
    private let outputPath: String?
    private var checkboxes: [NSButton] = []
    private var openModeRadio: NSButton?
    private var appendModeRadio: NSButton?
    private var outputChoice: String?
    private var didCancel = false

    init(outputPath: String?) {
        self.outputPath = outputPath
        super.init()
    }

    func run() -> String? {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: UI.minWidth, height: 120),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CursorWorkspaceLauncher"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = contentView

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: UI.minWidth),
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: UI.maxWidth)
        ])

        let subtitle = NSTextField(labelWithString: "Please select a workspace:")
        subtitle.font = NSFont.systemFont(ofSize: UI.subtitleFontSize)
        subtitle.textColor = .secondaryLabelColor

        let iconView = NSImageView(frame: .zero)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyDown
        iconView.image = NSImage(named: NSImage.applicationIconName)

        let iconRow = NSStackView(views: [iconView])
        iconRow.orientation = .horizontal
        iconRow.alignment = .leading
        iconRow.spacing = 0

        let checksStack = NSStackView()
        checksStack.orientation = .vertical
        checksStack.alignment = .leading
        checksStack.spacing = 6
        checksStack.translatesAutoresizingMaskIntoConstraints = false

        let clampedDefault: Int = pickerTitles.isEmpty ? 0 : min(max(defaultSelectionIndex, 0), pickerTitles.count - 1)
        for (index, title) in pickerTitles.enumerated() {
            let btn = NSButton(checkboxWithTitle: title, target: nil, action: nil)
            btn.font = NSFont.systemFont(ofSize: UI.checkboxFontSize)
            btn.state = (index == clampedDefault) ? .on : .off
            checkboxes.append(btn)
            checksStack.addArrangedSubview(btn)
        }

        let scrollDocument = NSView()
        scrollDocument.translatesAutoresizingMaskIntoConstraints = false
        scrollDocument.addSubview(checksStack)

        NSLayoutConstraint.activate([
            checksStack.topAnchor.constraint(equalTo: scrollDocument.topAnchor, constant: UI.scrollContentInset),
            checksStack.leadingAnchor.constraint(equalTo: scrollDocument.leadingAnchor, constant: UI.scrollContentInset),
            checksStack.trailingAnchor.constraint(equalTo: scrollDocument.trailingAnchor, constant: -UI.scrollContentInset),
            checksStack.bottomAnchor.constraint(equalTo: scrollDocument.bottomAnchor, constant: -UI.scrollContentInset)
        ])

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.drawsBackground = true
        scrollView.documentView = scrollDocument
        scrollView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        scrollView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let scrollHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: 1)
        NSLayoutConstraint.activate([
            scrollDocument.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            scrollHeightConstraint
        ])

        let modeLabel = NSTextField(labelWithString: "Mode:")
        modeLabel.font = NSFont.systemFont(ofSize: UI.subtitleFontSize)
        modeLabel.textColor = .secondaryLabelColor

        let openRadio = NSButton(radioButtonWithTitle: "Open", target: self, action: #selector(modeRadioChanged))
        openRadio.state = .on
        openRadio.font = NSFont.systemFont(ofSize: UI.checkboxFontSize)
        let appendRadio = NSButton(radioButtonWithTitle: "Append", target: self, action: #selector(modeRadioChanged))
        appendRadio.font = NSFont.systemFont(ofSize: UI.checkboxFontSize)
        openModeRadio = openRadio
        appendModeRadio = appendRadio

        let modeStack = NSStackView(views: [modeLabel, openRadio, appendRadio])
        modeStack.orientation = .horizontal
        modeStack.alignment = .centerY
        modeStack.spacing = UI.buttonSpacing
        modeStack.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAndClose))
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.bezelStyle = .rounded
        cancelButton.controlSize = .regular
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let okButton = NSButton(title: "OK", target: self, action: #selector(confirmSelection))
        okButton.bezelStyle = .rounded
        okButton.controlSize = .regular
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.keyEquivalent = "\r"

        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        okButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let buttonHeight: CGFloat = 22
        NSLayoutConstraint.activate([
            cancelButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            okButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])

        cancelButton.sizeToFit()
        okButton.sizeToFit()
        let buttonWidth = max(cancelButton.intrinsicContentSize.width, okButton.intrinsicContentSize.width)
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            okButton.widthAnchor.constraint(equalToConstant: buttonWidth)
        ])

        let spacerView = NSView(frame: .zero)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let actionsStack = NSStackView(views: [spacerView, cancelButton, okButton])
        actionsStack.orientation = .horizontal
        actionsStack.alignment = .centerY
        actionsStack.spacing = UI.buttonSpacing
        actionsStack.distribution = .fill
        actionsStack.translatesAutoresizingMaskIntoConstraints = false

        let rootStack = NSStackView(views: [iconRow, subtitle, scrollView, modeStack, actionsStack])
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = UI.stackSpacing
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: UI.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: UI.iconSize),
            scrollView.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            modeStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            actionsStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor),

            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UI.verticalPadding),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UI.horizontalPadding),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UI.horizontalPadding),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UI.verticalPadding)
        ])

        // Size list viewport to full content height (capped by screen) so scrollbars stay off for normal lists.
        window.setContentSize(NSSize(width: UI.minWidth, height: 640))
        contentView.layoutSubtreeIfNeeded()
        scrollDocument.layoutSubtreeIfNeeded()
        let rawDocHeight = max(scrollDocument.fittingSize.height, scrollDocument.bounds.height)
        let docNatural = ceil(rawDocHeight) + UI.scrollHeightSlack
        let screenListCap = min(
            720,
            max(160, (NSScreen.main?.visibleFrame.height ?? 800) * 0.55)
        )
        let scrollViewportHeight: CGFloat
        if pickerTitles.isEmpty {
            scrollViewportHeight = UI.scrollEmptyMinHeight
        } else {
            scrollViewportHeight = min(screenListCap, max(1, docNatural))
        }
        scrollHeightConstraint.constant = scrollViewportHeight

        contentView.layoutSubtreeIfNeeded()
        let contentSize = rootStack.fittingSize
        let fittedWidth = max(UI.minWidth, min(UI.maxWidth, contentSize.width + (UI.horizontalPadding * 2)))
        let fittedHeight = contentSize.height + (UI.verticalPadding * 2)
        window.setContentSize(NSSize(width: fittedWidth, height: fittedHeight))

        window.initialFirstResponder = checkboxes.first
        window.defaultButtonCell = okButton.cell as? NSButtonCell

        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        app.run()
        if didCancel {
            return nil
        }
        return outputChoice
    }

    @objc private func modeRadioChanged(_ sender: NSButton) {
        if sender === openModeRadio {
            appendModeRadio?.state = .off
            openModeRadio?.state = .on
        } else if sender === appendModeRadio {
            openModeRadio?.state = .off
            appendModeRadio?.state = .on
        }
    }

    private func currentAction() -> String {
        if appendModeRadio?.state == .on {
            return "append"
        }
        return "open"
    }

    private func selectedPaths() -> [String] {
        var out: [String] = []
        for (i, btn) in checkboxes.enumerated() {
            if btn.state == .on, i < workspacePaths.count {
                out.append(workspacePaths[i])
            }
        }
        return out
    }

    @objc private func confirmSelection() {
        let paths = selectedPaths()
        if paths.isEmpty {
            fputs("picker: no workspace selected\n", stderr)
            let alert = NSAlert()
            alert.messageText = "Select at least one workspace."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        let action = currentAction()
        fputs("picker: OK action=\(action) paths=\(paths.count)\n", stderr)

        // New protocol: first line is action, second line is paths joined by ASCII unit separator (U+001F).
        // Single-tab format remains supported by the shell launcher for pickers that use it.
        let unitSep = "\u{001F}"
        let joined = paths.joined(separator: unitSep)
        let outputValue = "\(action)\n\(joined)\n"

        if let outputPath {
            do {
                try outputValue.write(toFile: outputPath, atomically: true, encoding: .utf8)
            } catch {
                fputs("picker: failed writing output file: \(error)\n", stderr)
                let alert = NSAlert()
                alert.messageText = "Failed to save selected workspace."
                alert.informativeText = String(describing: error)
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }
        }

        didCancel = false
        outputChoice = outputValue
        NSApp.terminate(nil)
    }

    @objc private func cancelAndClose() {
        fputs("picker: cancel clicked\n", stderr)
        didCancel = true
        outputChoice = nil
        NSApp.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        if outputChoice == nil {
            fputs("picker: window closed without output; treating as cancel\n", stderr)
            didCancel = true
            outputChoice = nil
        }
        NSApp.terminate(nil)
    }
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil
let picker = PickerDelegate(outputPath: outputPath)
if let choice = picker.run() {
    if outputPath == nil {
        print(choice, terminator: "")
    }
}
