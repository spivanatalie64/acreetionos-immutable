import QtQuick 2.0;

Rectangle {
    id: root;
    width: parent.width;
    height: parent.height;
    color: "#2c2c2c";

    Image {
        id: logo;
        source: "logo.png";
        anchors.horizontalCenter: parent.horizontalCenter;
        anchors.top: parent.top;
        anchors.topMargin: 40;
        fillMode: Image.PreserveAspectFit;
        height: Math.min(220, parent.height * 0.35);
    }

    Text {
        id: title;
        anchors.horizontalCenter: parent.horizontalCenter;
        anchors.top: logo.bottom;
        anchors.topMargin: 30;
        text: qsTr("Welcome to AcreetionOS Immutable");
        color: "#ffffff";
        font.pixelSize: 32;
        font.bold: true;
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter;
        anchors.top: title.bottom;
        anchors.topMargin: 24;
        width: parent.width * 0.7;
        wrapMode: Text.WordWrap;
        horizontalAlignment: Text.AlignHCenter;
        color: "#d0d0d0";
        font.pixelSize: 18;
        text: qsTr("AcreetionOS Immutable uses a dual-root (A/B) design. " +
                   "The running system is read-only; updates are applied to the standby slot and activated atomically on reboot. " +
                   "If an update fails to boot, the system automatically falls back to the previous slot. " +
                   "Use 'abroot' from a terminal to update or roll back your system.");
    }
}
