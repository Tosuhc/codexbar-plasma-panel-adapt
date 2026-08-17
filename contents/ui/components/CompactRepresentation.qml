import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: compactRoot

    required property var applet

    readonly property bool verticalPanel: applet.verticalFormFactor
    readonly property bool hasProviderEntries: applet.compactProviders().length > 0
    readonly property var incidentProvider: applet.primaryIncidentProvider()
    readonly property string primaryText: applet.compactText()
    // Every multi-provider entry carries its own provider icon, so the leading
    // identity icon stays for vertical panels, the loading spinner, and the
    // single-provider layout; it would otherwise duplicate the first entry.
    readonly property bool showIdentityElement: compactRoot.verticalPanel
        || !compactRoot.hasProviderEntries
        || (compactRoot.applet.loading && compactRoot.hasProviderEntries)
    readonly property bool showTextElement: !compactRoot.verticalPanel
        && !compactRoot.hasProviderEntries
        && compactRoot.primaryText.length > 0
    readonly property bool showProviderEntries: !compactRoot.verticalPanel
        && compactRoot.hasProviderEntries
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

    // Measure outside the Loader so its layout-assigned width cannot feed back
    // into the label's preferred width and collapse the compact representation.
    PlasmaComponents.Label {
        id: compactTextMeasurer

        visible: false
        text: compactRoot.primaryText
        font.bold: true
    }

    RowLayout {
        id: compactRow

        // The applet keeps a minimum panel width, so a short content set (text
        // or entries without a status incident) leaves spare room. Centre the
        // row instead of letting all of it pile up on the right of the content.
        anchors.centerIn: parent
        width: Math.max(0, Math.min(compactRoot.width - Kirigami.Units.smallSpacing * 2,
            implicitWidth))
        height: Math.max(0, compactRoot.height - Kirigami.Units.smallSpacing * 2)
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: compactRoot.applet.panelElementOrder()

            delegate: Loader {
                id: elementLoader

                required property var modelData

                readonly property bool isTextElement: modelData === "text"
                readonly property bool isMetersElement: modelData === "meters"
                readonly property bool elementVisible: modelData === "identity"
                    ? compactRoot.showIdentityElement
                    : (modelData === "status"
                    ? (!compactRoot.verticalPanel
                        && compactRoot.incidentProvider !== null
                        && compactRoot.incidentProvider.hasIncident)
                    : (modelData === "text"
                    ? compactRoot.showTextElement
                    : compactRoot.showProviderEntries))

                sourceComponent: modelData === "identity"
                    ? identityElement
                    : (modelData === "status"
                    ? statusElement
                    : (modelData === "text" ? textElement : metersElement))
                visible: elementVisible
                Layout.fillWidth: elementVisible && (isTextElement || isMetersElement)
                Layout.preferredWidth: !elementVisible
                    ? 0
                    : (modelData === "identity"
                    ? Kirigami.Units.iconSizes.smallMedium
                    : (modelData === "status"
                    ? Kirigami.Units.smallSpacing * 1.5
                    : (modelData === "meters"
                    ? implicitWidth
                    : Math.max(Kirigami.Units.gridUnit * 2,
                        Math.ceil(compactTextMeasurer.implicitWidth)))))
                Layout.preferredHeight: compactRow.height
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Component {
        id: identityElement

        Item {
            readonly property string compactProvider: compactRoot.applet.selectedCompactProvider()
                ? compactRoot.applet.selectedCompactProvider().provider
                : "codex"

            visible: compactRoot.showIdentityElement
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium

            Kirigami.Icon {
                id: compactIdentityIcon

                anchors.fill: parent
                source: compactRoot.applet.loading ? "view-refresh" : compactRoot.applet.providerIconSource(parent.compactProvider)
                fallback: "view-statistics"
                isMask: !compactRoot.applet.loading && compactRoot.applet.providerIconIsMask(parent.compactProvider)
                color: compactRoot.applet.loading
                    ? Kirigami.Theme.textColor
                    : compactRoot.applet.providerReadableColor(parent.compactProvider, Kirigami.Theme.backgroundColor)

                RotationAnimator {
                    target: compactIdentityIcon
                    running: compactRoot.applet.loading
                    from: 0
                    to: 360
                    duration: 1250
                    loops: Animation.Infinite
                    onStopped: compactIdentityIcon.rotation = 0
                }

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
        }
    }

    Component {
        id: statusElement

        Rectangle {
            id: compactStatusBadge

            visible: !compactRoot.verticalPanel
                && compactRoot.incidentProvider !== null
                && compactRoot.incidentProvider.hasIncident
            implicitWidth: Kirigami.Units.smallSpacing * 1.5
            implicitHeight: implicitWidth
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
    }

    Component {
        id: textElement

        PlasmaComponents.Label {
            visible: compactRoot.showTextElement
            text: compactRoot.primaryText
            elide: Text.ElideRight
            font.bold: true
            // The loader stretches this label to the full row height, so the
            // default top alignment would sit the text above the centred
            // provider icon beside it.
            verticalAlignment: Text.AlignVCenter
        }
    }

    // The multi-provider "meters" element renders one icon + usage-text entry
    // per provider instead of the old thumbnail meters; the element keeps its
    // persisted identifier so existing element-order configuration still works.
    Component {
        id: metersElement

        RowLayout {
            visible: compactRoot.showProviderEntries
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: compactRoot.applet.compactProviders()

                delegate: CompactProviderEntry {
                    applet: compactRoot.applet
                    Layout.fillWidth: true
                }
            }
        }
    }
}
