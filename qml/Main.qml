import QtQuick.Window

Window {
    id: window

    width: 550
    height: 700

    visible: true

    title: "PeaceFounder"

    Bridge {
    } 

    /* Loader { */
    /*     id: _loader */
    /*     width: parent.width */
    /*     height: parent.height */

    /*     function reload() { */
    /*         var time = new Date().getTime(); */
    /*         source = ""; */
    /*         source = "Bridge.qml?nocache=" + time; */
    /*     } */
    
    /*     //anchors.centerIn: parent */
    /*     source: "Bridge.qml" */
    /* } */

    /* MouseArea { */
    /*     anchors.fill: parent */
    /*     onClicked: { */
    /*         _loader.reload(); */
    /*     } */
    /* } */

}
