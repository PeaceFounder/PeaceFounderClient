import QtQuick.Controls
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

// Overlay Rectangle for dimming the background
Rectangle {
    id: modalBackground
    color: "#80000000" // Semi-transparent black
    anchors.fill: parent
    visible: true

    property bool isRaised: false
    property alias title: error_title.text
    property alias message: error_message.text

    onIsRaisedChanged: {
        if (error.isRaised) {
            error.visible = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {} // Capture clicks on the overlay to prevent them from reaching the main window
    }

    // Actual error dialog
    Rectangle {
        id: errorDialog
        width: 400
        height: 250
        color: "#e1ddda" //Style.cardPrimaryBackground
        radius: 10
        border.color: "black"
        border.width: -1
        anchors.centerIn: parent

        ColumnLayout {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 20

            Text {
                id: error_title
                text: "Error Title"
                font.bold: true
                font.pointSize: 16
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: 10
            }


            Rectangle { 
                radius: 5 
                color: "#eceae6"

                border.color: "#A3AFB2"
                border.width: 1 

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 150  // Adjust based on your UI requirements

                ScrollView {

                    anchors.fill: parent
                    
                    contentWidth: parent.width
                    
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff


                    Text {
                        id: error_message
                        text: "An error has occurred! Please check your connection or try again later. If the problem persists, contact support. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis "
                        wrapMode: Text.WordWrap
                        //anchors.fill: parent
                        padding: 10
                        font.pointSize: 14
                        width: parent.parent.width
                    }
                }
            }


            Rectangle {

                Layout.alignment: Qt.AlignHCenter
                
                layer {
                    enabled: true
                    effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 8.0
                        samples: 16
                        color: "#80000000"
                    }
                }

                radius : 5

                width : 100
                height : 30

                color : "#9C4649"

                Text {

                    anchors.centerIn : parent

                    font.pointSize : 16
                    color : "white"

                    text : "OK"

                }

                MouseArea {
                    anchors.fill : parent
                    onClicked : {
                        modalBackground.visible = false
                    }
                }
            }

        }
    }
}
