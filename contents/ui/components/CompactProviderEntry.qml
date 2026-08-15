import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Reusable "icon + usage text" entry used by both the single-provider compact
// representation and each multi-provider panel entry.
RowLayout {
    id: compactProviderEntry

    required property var applet
    // Repeater delegates inject the row data through this context property;
    // declaring it lets the delegate bindings see the provider object.
    required property var modelData
    property int iconSize: Kirigami.Units.iconSizes.smallMedium
    property bool showSpinner: false

    readonly property string providerKey: compactProviderEntry.modelData
        ? compactProviderEntry.modelData.provider
        : "codex"
    readonly property string entryText: compactProviderEntry.modelData
        ? compactProviderEntry.applet.compactProviderText(compactProviderEntry.modelData)
        // modelData is null only while the first snapshot is loading; keep
        // the same placeholder identity as the compact text contract.
        : compactProviderEntry.applet.compactText()
    readonly property color accent: compactProviderEntry.applet.providerReadableColor(
        compactProviderEntry.providerKey,
        Kirigami.Theme.backgroundColor)

    spacing: Kirigami.Units.smallSpacing

    Kirigami.Icon {
        id: compactProviderEntryIcon

        source: compactProviderEntry.applet.loading
            ? "view-refresh"
            : compactProviderEntry.applet.providerIconSource(compactProviderEntry.providerKey)
        fallback: "view-statistics"
        isMask: !compactProviderEntry.applet.loading
            && compactProviderEntry.applet.providerIconIsMask(compactProviderEntry.providerKey)
        color: compactProviderEntry.applet.loading
            ? Kirigami.Theme.textColor
            : compactProviderEntry.accent
        Layout.preferredWidth: compactProviderEntry.iconSize
        Layout.preferredHeight: compactProviderEntry.iconSize
        Layout.alignment: Qt.AlignVCenter

        RotationAnimator {
            target: compactProviderEntryIcon
            running: compactProviderEntry.showSpinner && compactProviderEntry.applet.loading
            from: 0
            to: 360
            duration: 1250
            loops: Animation.Infinite
            onStopped: compactProviderEntryIcon.rotation = 0
        }
    }

    PlasmaComponents.Label {
        visible: compactProviderEntry.entryText.length > 0
        text: compactProviderEntry.entryText
        elide: Text.ElideRight
        font.bold: true
        Layout.fillWidth: true
    }
}
