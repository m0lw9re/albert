﻿import QtQuick 2.5
import QtQuick.Controls 1.0
import QtGraphicalEffects 1.0
import "themes.js" as Themes

Item {

    id: root

    property bool ctrl: false

    width: frame.width+2*preferences.shadow_size
    height: frame.height+2*preferences.shadow_size

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        verticalOffset: preferences.shadow_size/3
        radius: preferences.shadow_size
        samples: preferences.shadow_size*2
        color: preferences.shadow_color
    }

    Preferences {
        id: preferences
        objectName: "preferences"
    }

    FontLoader {
        source: "fonts/Roboto-Thin.ttf"
        onStatusChanged: if (loader.status === FontLoader.Ready) preferences.font_name = fontname
    }

    Rectangle {

        id: frame
        objectName: "frame" // for C++
        x: preferences.shadow_size;
        y: preferences.shadow_size
        width: preferences.window_width
        height: content.height+2*content.anchors.margins
        radius: preferences.radius
        color: preferences.background_color
        Behavior on color { ColorAnimation { duration: preferences.animation_duration; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: preferences.animation_duration; easing.type: Easing.OutCubic } }
        border.color: preferences.border_color
        border.width: preferences.border_size

        Column {

            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: preferences.border_size+preferences.padding
            }
            spacing: preferences.spacing

            HistoryTextInput {
                id: historyTextInput
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
                clip: true
                color: preferences.input_color
                focus: true
                font.pixelSize: preferences.input_fontsize
                font.family: preferences.font_name
                selectByMouse: true
                selectedTextColor: preferences.background_color
                selectionColor: preferences.selection_color
                Keys.forwardTo: [root, resultsList]
                cursorDelegate : Item {
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: preferences.cursor_color
                    }
                    SequentialAnimation on opacity {
                        id: animation
                        loops: Animation.Infinite;
                        NumberAnimation { to: 0; duration: 750; easing.type: Easing.InOutExpo }
                        NumberAnimation { to: 1; duration: 750; easing.type: Easing.InOutExpo }
                    }
                    Connections {
                        target: historyTextInput
                        onTextChanged: { opacity=1; animation.restart() }
                        onCursorPositionChanged: { opacity=1; animation.restart() }
                    }
                }
                onTextChanged: { root.state="" }
            } // historyTextInput

            DesktopListView {
                id: resultsList
                width: parent.width
                model: resultsModel
                itemCount: preferences.max_items
                delegate: Component {
                    ItemViewDelegate{
                        iconSize: preferences.icon_size
                        spacing: preferences.spacing
                        textSize: preferences.item_title_fontsize
                        descriptionSize: preferences.item_description_fontsize
                        textColor: preferences.foreground_color
                        highlightColor: preferences.highlight_color
                        fontName: preferences.font_name
                        animationDuration: preferences.animation_duration
                    }
                }
                Keys.onEnterPressed: (event.modifiers===Qt.KeypadModifier) ? root.activate(resultsList.currentIndex) : root.activate(resultsList.currentIndex,-event.modifiers)
                Keys.onReturnPressed: (event.modifiers===Qt.NoModifier) ? root.activate(resultsList.currentIndex) : root.activate(resultsList.currentIndex,-event.modifiers)
                onCurrentIndexChanged: if (root.state==="detailsView") root.state=""
            }  // resultsList (ListView)

            DesktopListView {
                id: actionsListView
                width: parent.width
                model: ListModel { id: actionsModel }
                itemCount: actionsModel.count
                spacing: preferences.spacing
                Behavior on visible {
                    SequentialAnimation {
                        PropertyAction  { }
                        NumberAnimation { target: actionsListView; property: "opacity"; from:0; to: 1; duration: preferences.animation_duration }
                    }
                }
                delegate: Text {
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    text: name
                    textFormat: Text.PlainText
                    font.family: preferences.font_name
                    elide: Text.ElideRight
                    font.pixelSize: (preferences.item_description_fontsize+preferences.item_title_fontsize)/2
                    color: ListView.isCurrentItem ? preferences.highlight_color : preferences.foreground_color
                    Behavior on color { ColorAnimation{ duration: preferences.animation_duration } }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: actionsListView.currentIndex = index
                        onDoubleClicked: root.activate(resultsList.currentIndex, actionsListView.currentIndex)
                    }
                }
                visible: false
                Keys.onEnterPressed: root.activate(resultsList.currentIndex, actionsListView.currentIndex)
                Keys.onReturnPressed: root.activate(resultsList.currentIndex, actionsListView.currentIndex)
            }  // actionsListView (ListView)
        }  // content (Column)


        SettingsButton {
            id: settingsButton
            size: preferences.settingsbutton_size
            color: preferences.settingsbutton_color
            hoverColor: preferences.settingsbutton_hover_color
            onLeftClicked: settingsWidgetRequested()
            onRightClicked: menu.popup()
            anchors {
                top: parent.top
                right: parent.right
                topMargin: preferences.padding+preferences.border_size
                rightMargin: preferences.padding+preferences.border_size
            }

            Menu {
                id: menu
                MenuItem {
                    text: "Settings"
                    shortcut: "Alt+,"
                    onTriggered: settingsWidgetRequested()
                }
                MenuItem {
                    text: "Quit"
                    shortcut: "Alt+F4"
                    onTriggered: Qt.quit()

                }
            }
        }
    }  // frame (Rectangle)

    onActiveFocusChanged: state=""

    // Key handling
    Keys.onPressed: {
        event.accepted = true
        if (state === ""
                && ((event.key === Qt.Key_Up && resultsList.currentIndex === 0 && !event.isAutoRepeat)  // top item selected
                        || (event.modifiers === Qt.ControlModifier && (event.key === Qt.Key_P || event.key === Qt.Key_Up)))){ // whatever item, using control modifier
            state == ""
            historyTextInput.forwardSearchHistory()
        }
        else if (event.modifiers === Qt.ControlModifier && (event.key === Qt.Key_Down || event.key === Qt.Key_N)) {
            state == ""
            historyTextInput.backwardSearchHistory()
        }
        else if (event.key === Qt.Key_Meta) {
            if (resultsList.currentIndex === -1)
                resultsList.currentIndex = 0
            state="fallback"
        }
        else if (event.key === Qt.Key_Comma && (event.modifiers === Qt.AltModifier || event.modifiers === Qt.ControlModifier)) {
            settingsWidgetRequested()
        }
        else if (event.key === Qt.Key_Alt && resultsList.count > 0) {
            if (resultsList.currentIndex === -1)
                resultsList.currentIndex = 0
            state = "detailsView"
        }
        else if (48 <= event.key && event.key <= 57 && event.modifiers === Qt.ControlModifier){
            var num = 9
            if (event.key !== Qt.Key_0)
                num = event.key - 49
            if (num < preferences.max_items && num < resultsList.count) {
                var index = resultsList.indexAt(0, resultsList.contentY)
                index += num
                resultsList.currentIndex = index
                root.activate(resultsList.currentIndex)
            }
        }
        else if ( event.key === Qt.Key_Control )
            ctrl = true
        else if ( event.key === Qt.Key_Tab && resultsList.count > 0 ) {
            if ( resultsList.currentIndex === -1 )
                resultsList.currentIndex = 0

            var completion = resultsList.currentItem.attachedModel.itemCompletionStringRole
            if (completion !== '')  // QString.isnull sent as ''
                historyTextInput.text = completion

        } else event.accepted = false
    }
    Keys.onReleased: {
        event.accepted = true
        if ( event.key === Qt.Key_Meta )
            state=""
        else if ( event.key === Qt.Key_Alt )
            state=""
        else if ( event.key === Qt.Key_Control )
            ctrl = false
        else event.accepted = false

    }

    states : [
        State {
            name: ""
            StateChangeScript {
                name: "defaultStateScript"
                script: {
                    actionsModel.clear()
                }
            }
        },
        State {
            name: "fallback"
        },
        State {
            name: "detailsView"
            PropertyChanges { target: actionsListView; visible: true  }
            PropertyChanges { target: historyTextInput; Keys.forwardTo: [root, actionsListView] }
            StateChangeScript {
                name: "detailsViewStateScript"
                script: {
                    var actionTexts = resultsList.currentItem.actionsList();
                    for ( var i = 0; i < actionTexts.length; i++ )
                        actionsModel.append({"name": actionTexts[i]});
                }
            }
        }
    ]

    Connections {
        target: mainWindow
        onVisibleChanged: {
            if (!arg) {

                // Save the text if the text displayed has been entered by the user
                if (historyTextInput.userText === historyTextInput.text)
                    historyTextInput.pushTextToHistory()

                // Reset state
                state=""
                ctrl=false
                historyTextInput.selectAll()
                historyTextInput.userText = null
                historyTextInput.resetHistoryMode()
            }
        }
    }

    Component.onCompleted: setTheme("Bright")


    // ▼ ▼ ▼ ▼ ▼ DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING ▼ ▼ ▼ ▼ ▼

    /*
     * Currently the interface with the program logic comprises the following:
     *
     * These context properties are set:
     *   - mainWindow
     *   - resultsModel
     *   - history
     *
     * These properties must exist in root:
     *   - inputText (string, including the implicitly genreated signal)
     *
     * These functions must extist in root:
     *   - availableThemes()
     *   - setTheme(str)
     *
     * These signals must exist in root:
     *   - settingsWidgetRequested()
     *
     * These object names with must exist somewhere:
     *   - frame (the visual root frame, i.e. withouth shadow)
     *   - preferences (QtObject containing only preference propterties)
     */
    property string interfaceVersion: "1.0-alpha" // Will not change until beta

    property alias inputText: historyTextInput.text
    signal settingsWidgetRequested()

    function activate(index, action) {
        if ( resultsList.count > 0 ) {
            resultsList.currentIndex = index
            if ( resultsList.currentIndex === -1 )
                resultsList.currentIndex = 0
            resultsList.currentItem.activate(action)

            // Order important! (hide triggers root.onVisibleChanged())
            historyTextInput.pushTextToHistory()
            mainWindow.hide()
            historyTextInput.text = ""
        }
    }

    function availableThemes() { return Object.keys(Themes.themes()) }
    function setTheme(themeName) {
        var themeObject = Themes.themes()[themeName]
        for (var property in themeObject)
            if (themeObject.hasOwnProperty(property))
                preferences[property] = themeObject[property]
    }
}
