import QtQuick
import QtQuick.Controls


AppPage {
    
    anchors.fill: parent

    title : "Guard"
    subtitle : "Guard your vote"

    property alias demeUUID : status.demeUUID
    property alias proposalIndex : status.proposalIndex
    
    property alias pseudonym : status.pseudonym
    property alias timestamp : status.timestamp
    property alias castIndex : status.castIndex

    property alias commitIndex : status.commitIndex
    property alias commitRoot : status.commitRoot
        

    VScrollBar {
        
        contentY : view.contentItem.contentY
        contentHeight : view.contentHeight

    }
    
    ScrollView {
        
        id : view

        anchors.fill : parent
        contentWidth : parent.width

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        Column {

            width : parent.width
            spacing : 21

            GuardStatus {
                id : status
            }
            
            Text {

                anchors.horizontalCenter : parent.horizontalCenter
                width : parent.width * 0.75

                wrapMode : Text.WordWrap

                font.weight : Font.Light
                
                lineHeight : 1.5

                color : Style.textPrimary

                text : "Perhaps the guardian or collector acted with malicious intent, or an adversary compromised their credentials. This breach might have falsely confirmed that your vote was recorded when, in fact, it disappeared into a black hole.

To keep the authority accountable, you can use your device. After a while, press a refresh button to retrieve the current ledger commit. Behind the scenes, this uses History Tree consistency proofs, ensuring your cast vote is consistent with the current ledger commit. This may be enough, but as the last line of defence, check the officially announced tally and the root commit from a different channel, such as a web browser, newspaper, etc., and compare them to what is shown on your screen. 

If your device is infected by malware, it could deceive you that your vote is correctly counted. To counter this threat, you have two options. Within 15 minutes of casting your vote, you can use the code displayed on your screen, XXXX-XXXX, to verify in your browser that your vote has been recorded as intended.

Alternatively, once the election authority has published the votes on the bulletin board, you can verify your vote there. Once published, locate your vote using your cast index to ensure it was recorded as intended, included in the final tally, not overshadowed by other votes with the same pseudonym, and accurately reflects the time you cast it. The latter part is essential to prevent misdirections by malware in checking another person's vote."

            }

            Item { 
                height : 150
                width : parent.width 
            }

        }
    }
}
