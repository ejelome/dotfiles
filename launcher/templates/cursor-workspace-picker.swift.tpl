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
        static let popupFontSize: CGFloat = 13
    }

    private let popup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let workspacePaths = [__WORKSPACE_PATHS__]
    private let defaultSelectionIndex = __DEFAULT_SELECTION_INDEX__
    private let outputPath: String?
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

        let subtitle = NSTextField(labelWithString: "Choose a workspace to open in Cursor:")
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

        popup.addItems(withTitles: [__PICKER_ITEMS__])
        if popup.numberOfItems > 0 {
            let clampedDefaultIndex = min(max(defaultSelectionIndex, 0), popup.numberOfItems - 1)
            popup.selectItem(at: clampedDefaultIndex)
        }
        fputs("picker: popup items=\(popup.numberOfItems), workspace paths=\(workspacePaths.count)\n", stderr)
        popup.bezelStyle = .rounded
        popup.controlSize = .regular
        popup.font = NSFont.systemFont(ofSize: UI.popupFontSize, weight: .medium)
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        popup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAndClose))
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.bezelStyle = .rounded
        cancelButton.controlSize = .regular
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let appendButton = NSButton(title: "Append", target: self, action: #selector(appendSelected))
        appendButton.bezelStyle = .rounded
        appendButton.controlSize = .regular
        appendButton.translatesAutoresizingMaskIntoConstraints = false

        let openButton = NSButton(title: "Open", target: self, action: #selector(openSelected))
        openButton.bezelStyle = .rounded
        openButton.controlSize = .regular
        openButton.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        appendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        openButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // HIG: Return activates the primary action; Escape cancels.
        // HIG: Append should not have a default key binding unless explicitly assigned.
        openButton.keyEquivalent = "\r"
        appendButton.keyEquivalent = ""
        // Cancel keyEquivalent is already set above.

        // HIG: Keep all buttons the same height.
        let buttonHeight: CGFloat = 22 // AppKit standard control height (pt)
        NSLayoutConstraint.activate([
            cancelButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            appendButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            openButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])

        // HIG: Non-primary buttons should have equal width (sized to the longest label).
        cancelButton.sizeToFit()
        appendButton.sizeToFit()
        let nonPrimaryButtonWidth = max(cancelButton.intrinsicContentSize.width, appendButton.intrinsicContentSize.width)
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: nonPrimaryButtonWidth),
            appendButton.widthAnchor.constraint(equalToConstant: nonPrimaryButtonWidth)
        ])

        // HIG: Use a flexible spacer so the visual gap between "Cancel" and "Append"
        // grows, while "Append" + "Open" remain tightly grouped.
        let spacerView = NSView(frame: .zero)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let actionsStack = NSStackView(views: [appendButton, openButton])
        actionsStack.orientation = .horizontal
        actionsStack.alignment = .centerY
        actionsStack.spacing = UI.buttonSpacing
        actionsStack.distribution = .fill
        // Ensure the pair remains tightly grouped; let the spacer absorb extra width.
        actionsStack.setContentHuggingPriority(.required, for: .horizontal)
        actionsStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let buttonsStack = NSStackView(views: [cancelButton, spacerView, actionsStack])
        buttonsStack.orientation = .horizontal
        buttonsStack.alignment = .centerY
        buttonsStack.spacing = 0
        buttonsStack.distribution = .fill
        buttonsStack.setContentHuggingPriority(.required, for: .horizontal)

        // Ensure the "button row" itself doesn't force extra height.
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        spacerView.translatesAutoresizingMaskIntoConstraints = false

        let rootStack = NSStackView(views: [iconRow, subtitle, popup, buttonsStack])
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = UI.stackSpacing
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: UI.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: UI.iconSize),
            popup.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            buttonsStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor),

            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UI.verticalPadding),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UI.horizontalPadding),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UI.horizontalPadding),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UI.verticalPadding)
        ])

        contentView.layoutSubtreeIfNeeded()
        let contentSize = rootStack.fittingSize
        let fittedWidth = max(UI.minWidth, min(UI.maxWidth, contentSize.width + (UI.horizontalPadding * 2)))
        let fittedHeight = contentSize.height + (UI.verticalPadding * 2)
        window.setContentSize(NSSize(width: fittedWidth, height: fittedHeight))

        window.initialFirstResponder = popup
        // HIG: Return should activate "Open" (primary action).
        window.defaultButtonCell = openButton.cell as? NSButtonCell

        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        app.run()
        if didCancel {
            return nil
        }
        return outputChoice
    }

    func currentSelectionPath() -> String? {
        let selectedIndex = popup.indexOfSelectedItem
        if selectedIndex >= 0 && selectedIndex < workspacePaths.count {
            return workspacePaths[selectedIndex]
        }
        return nil
    }

    @objc private func openSelected() {
        fputs("picker: open clicked, selected index=\(popup.indexOfSelectedItem)\n", stderr)
        submitSelection(action: "open")
    }

    @objc private func appendSelected() {
        fputs("picker: append clicked, selected index=\(popup.indexOfSelectedItem)\n", stderr)
        submitSelection(action: "append")
    }

    private func submitSelection(action: String) {
        guard let selectedPath = currentSelectionPath() else {
            fputs("picker: no valid selected path\n", stderr)
            let alert = NSAlert()
            alert.messageText = "Select a workspace first."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        fputs("picker: selected path=\(selectedPath)\n", stderr)

        let outputValue = "\(action)\t\(selectedPath)"

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
        // Preserve explicit Open selections; only treat manual close as cancel.
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
        print(choice)
    }
}
