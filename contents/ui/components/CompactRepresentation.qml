import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    required property var applet

    readonly property bool verticalPanel: applet.verticalFormFactor
    readonly property var multiProviderItems: applet.compactProviders()
    readonly property bool hasProviderEntries: multiProviderItems.length > 0
    readonly property var incidentProvider: applet.primaryIncidentProvider()
    // Vertical panels collapse to a bare icon. Horizontal multi-provider panels
    // render one icon + text entry per provider, so the leading identity icon
    // only reappears there while a refresh is running to keep the spinner.
    readonly property bool showIdentityIcon: compactRoot.verticalPanel
        || (compactRoot.applet.loading && compactRoot.hasProviderEntries)
    readonly property bool showPrimaryEntry: !compactRoot.verticalPanel && !compactRoot.hasProviderEntries
    readonly property int compactExtent: Kirigami.Units.iconSizes.smallMedium
        + Kirigami.Units.smallSpacing * 2
    readonly property int compactMinimumWidth: Kirigami.Units.gridUnit * 4.8
    // Safety cap so a four-provider text row cannot push unrelated panel
    // applets offscreen; entries elide below this width.
    readonly property int compactMaximumWidth: Kirigami.Units.gridUnit * 40
    readonly property int desiredWidth: compactRoot.verticalPanel
        ? compactExtent
        : Math.min(
            compactRoot.compactMaximumWidth,
            Math.max(compactRoot.compactMinimumWidth,
                compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2))

    Layout.minimumWidth: compactRoot.verticalPanel
        ? compactExtent
        : compactRoot.compactMinimumWidth
    Layout.preferredWidth: compactRoot.desiredWidth
    Layout.maximumWidth: compactRoot.verticalPanel
        ? compactExtent
        : compactRoot.compactMaximumWidth
    Layout.maximumHeight: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 2

    implicitWidth: compactRoot.desiredWidth
    implicitHeight: Layout.maximumHeight
    clip: true

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: compactRoot.applet.expanded = !compactRoot.applet.expanded
    }

    RowLayout {
        id: compactRow

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            id: compactIdentityIcon

            readonly property string compactProvider: compactRoot.applet.selectedCompactProvider() ? compactRoot.applet.selectedCompactProvider().provider : "codex"

            visible: compactRoot.showIdentityIcon
            source: compactRoot.applet.loading ? "view-refresh" : compactRoot.applet.providerIconSource(compactProvider)
            fallback: "view-statistics"
            isMask: !compactRoot.applet.loading && compactRoot.applet.providerIconIsMask(compactProvider)
            color: compactRoot.applet.loading
                ? Kirigami.Theme.textColor
                : compactRoot.applet.providerReadableColor(compactProvider, Kirigami.Theme.backgroundColor)
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            Layout.alignment: Qt.AlignCenter

            RotationAnimator {
                target: compactIdentityIcon
                running: compactRoot.applet.loading
                from: 0
                to: 360
                duration: 1250
                loops: Animation.Infinite
                onStopped: compactIdentityIcon.rotation = 0
            }

            // The inline badge below needs horizontal room the vertical strip does
            // not have, so overlay the incident marker on the identity icon instead
            // of dropping the only at-a-glance status signal. Hidden while the icon
            // spins so the marker does not orbit the refresh indicator.
            Rectangle {
                id: compactVerticalStatusBadge

                visible: compactRoot.verticalPanel
                    && !compactRoot.applet.loading
                    && compactRoot.incidentProvider !== null
                    && compactRoot.incidentProvider.hasIncident
                anchors.top: parent.top
                anchors.right: parent.right
                width: Math.round(Kirigami.Units.iconSizes.smallMedium / 3)
                height: width
                radius: width / 2
                color: compactRoot.incidentProvider
                    ? compactRoot.applet.statusBadgeColor(compactRoot.incidentProvider.statusSeverity)
                    : "transparent"
                border.width: 1
                border.color: Kirigami.Theme.backgroundColor
            }
        }

        Rectangle {
            id: compactStatusBadge

            visible: !compactRoot.verticalPanel
                && compactRoot.incidentProvider !== null
                && compactRoot.incidentProvider.hasIncident
            Layout.preferredWidth: Kirigami.Units.smallSpacing * 1.5
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            radius: width / 2
            color: compactRoot.incidentProvider
                ? compactRoot.applet.statusBadgeColor(compactRoot.incidentProvider.statusSeverity)
                : "transparent"

            Controls.ToolTip.visible: compactStatusMouse.containsMouse
            Controls.ToolTip.text: compactRoot.incidentProvider
                ? i18n("%1: %2", compactRoot.incidentProvider.title, compactRoot.incidentProvider.status)
                : ""

            MouseArea {
                id: compactStatusMouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        CompactProviderEntry {
            id: compactPrimaryEntry

            visible: compactRoot.showPrimaryEntry
            applet: compactRoot.applet
            modelData: compactRoot.applet.selectedCompactProvider()
            showSpinner: true
            Layout.fillWidth: true
        }

        Repeater {
            model: compactRoot.verticalPanel ? [] : compactRoot.multiProviderItems

            delegate: CompactProviderEntry {
                applet: compactRoot.applet
                Layout.fillWidth: true
            }
        }
    }
}
