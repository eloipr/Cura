// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: base;

    signal showTooltip(Item item, point location, string text);
    signal hideTooltip();

    property Action configureSettings;
    property variant minimumPrintTime: PrintInformation.minimumPrintTime;
    property variant maximumPrintTime: PrintInformation.maximumPrintTime;
    property bool settingsEnabled: ExtruderManager.activeExtruderStackId || machineExtruderCount.properties.value == 1

    Component.onCompleted: PrintInformation.enabled = true
    Component.onDestruction: PrintInformation.enabled = false
    UM.I18nCatalog { id: catalog; name: "cura" }

    ScrollView
    {
        anchors.fill: parent
        style: UM.Theme.styles.scrollview
        flickableItem.flickableDirection: Flickable.VerticalFlick

        Rectangle
        {
            width: childrenRect.width
            height: childrenRect.height
            color: UM.Theme.getColor("sidebar")

            //
            // Quality profile
            //
            Text
            {
                id: resolutionLabel
                anchors.top: resolutionSlider.top
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width

                text: catalog.i18nc("@label", "Layer Height")
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
            }

            Text
            {
                id: speedLabel
                anchors.bottom: resolutionSlider.bottom
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width

                text: catalog.i18nc("@label", "Print Speed")
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
            }

            Text
            {
                id: speedLabelSlower
                anchors.bottom: speedLabel.bottom
                anchors.left: resolutionSlider.left

                text: catalog.i18nc("@label", "Slower")
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
                horizontalAlignment: Text.AlignLeft
            }

            Text
            {
                id: speedLabelFaster
                anchors.bottom: speedLabel.bottom
                anchors.right: resolutionSlider.right

                text: catalog.i18nc("@label", "Faster")
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
                horizontalAlignment: Text.AlignRight
            }

            Item
            {
                id: resolutionSlider
                anchors.top: parent.top
                anchors.left: infillCellRight.left
                anchors.right: infillCellRight.right

                width: UM.Theme.getSize("sidebar").width * .55
                height: UM.Theme.getSize("quality_slider_bar").height * 25

                property var model: Cura.ProfilesModel

                Connections
                {
                    target: Cura.ProfilesModel
                    onItemsChanged:
                    {
                        resolutionSlider.updateCurrentQualityIndex();
                        resolutionSlider.updateBar();
                    }
                }

                Connections
                {
                    target: Cura.MachineManager
                    onActiveQualityChanged:
                    {
                        resolutionSlider.updateCurrentQualityIndex();
                        resolutionSlider.updateBar();
                    }
                }

                Component.onCompleted:
                {
                    updateCurrentQualityIndex();
                    updateBar();
                }

                function updateCurrentQualityIndex()
                {
                    for (var i = 0; i < resolutionSlider.model.rowCount(); ++i)
                    {
                        if (Cura.MachineManager.activeQualityId == resolutionSlider.model.getItem(i).id)
                        {
                            if (resolutionSlider.currentQualityIndex != i)
                            {
                                resolutionSlider.currentQualityIndex = i;
                            }
                            return;
                        }
                    }
                    resolutionSlider.currentQualityIndex = undefined;
                    backgroundBarUpdateTimer.start();
                }

                function updateBar()
                {
                    fullRangeMax = Cura.ProfilesModel.rowCount();

                    // set avaiableMin
                    var foundAvaiableMin = false;
                    for (var i = 0; i < Cura.ProfilesModel.rowCount(); ++i)
                    {
                        if (Cura.ProfilesModel.getItem(i).available)
                        {
                            avaiableMin = i;
                            foundAvaiableMin = true;
                            break;
                        }
                    }
                    if (!foundAvaiableMin)
                    {
                        avaiableMin = undefined;
                    }

                    var foundAvaiableMax = false;
                    for (var i = Cura.ProfilesModel.rowCount() - 1; i >= 0; --i)
                    {
                        if (Cura.ProfilesModel.getItem(i).available)
                        {
                            avaiableMax = i;
                            foundAvaiableMax = true;
                            break;
                        }
                    }
                    if (!foundAvaiableMax)
                    {
                        avaiableMax = undefined;
                    }

                    currentHover = undefined;
                    backgroundBar.requestPaint();
                }

                property var fullRangeMin: 0
                property var fullRangeMax: model.rowCount()

                property var avaiableMin
                property var avaiableMax
                property var currentQualityIndex
                property var currentHover

                //TODO: get from theme
                property var barLeftRightMargin: 5
                property var tickLeftRightMargin: 2
                property var tickMargin: 15
                property var tickThickness: 1
                property var tickWidth: 1
                property var tickHeight: 5
                property var tickTextHeight: 8
                property var totalTickCount: fullRangeMax - fullRangeMin
                property var selectedCircleDiameter: 10

                property var showQualityText: false

                property var tickStepSize: (width - (barLeftRightMargin + tickLeftRightMargin) * 2) / (totalTickCount > 1 ?  totalTickCount - 1 : 1)
                property var tickAreaList:
                {
                    var area_list = [];
                    if (avaiableMin != undefined && avaiableMax != undefined)
                    {
                        for (var i = avaiableMin; i <= avaiableMax; ++i)
                        {
                            var start_x = (barLeftRightMargin + tickLeftRightMargin) + tickStepSize * (i - fullRangeMin);
                            var diameter = tickStepSize * 0.9;
                            start_x = start_x + tickWidth / 2 - (diameter / 2);
                            var end_x = start_x + diameter;
                            var start_y = height / 2 - diameter / 2;
                            var end_y = start_y + diameter;

                            var area = {"id": i,
                                        "start_x": start_x, "end_x": end_x,
                                        "start_y": start_y, "end_y": end_y,
                                        };
                            area_list.push(area);
                        }
                    }
                    return area_list;
                }

                onCurrentHoverChanged:
                {
                    backgroundBar.requestPaint();
                }
                onCurrentQualityIndex:
                {
                    backgroundBar.requestPaint();
                }

                // background bar
                Canvas
                {
                    id: backgroundBar
                    anchors.fill: parent

                    Timer {
                        id: backgroundBarUpdateTimer
                        interval: 10
                        running: false
                        repeat: false
                        onTriggered: backgroundBar.requestPaint()
                    }

                    onPaint:
                    {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = UM.Theme.getColor("quality_slider_unavailable");

                        const bar_left_right_margin = resolutionSlider.barLeftRightMargin;
                        const tick_left_right_margin = resolutionSlider.tickLeftRightMargin;
                        const tick_margin = resolutionSlider.tickMargin;
                        const bar_thickness = resolutionSlider.tickThickness;
                        const tick_width = resolutionSlider.tickWidth;
                        const tick_height = resolutionSlider.tickHeight;
                        const tick_text_height = resolutionSlider.tickTextHeight;
                        const selected_circle_diameter = resolutionSlider.selectedCircleDiameter;

                        // draw unavailable bar
                        const bar_top = parent.height / 2 - bar_thickness / 2;
                        ctx.fillRect(bar_left_right_margin, bar_top, width - bar_left_right_margin * 2, bar_thickness);

                        // draw unavailable ticks
                        var total_tick_count = resolutionSlider.totalTickCount;
                        const step_size = resolutionSlider.tickStepSize;
                        var current_start_x = bar_left_right_margin + tick_left_right_margin;

                        const tick_top = parent.height / 2 - tick_height / 2;

                        for (var i = 0; i < total_tick_count; ++i)
                        {
                            ctx.fillRect(current_start_x, tick_top, tick_width, tick_height);
                            current_start_x += step_size;
                        }

                        // draw available bar and ticks
                        if (resolutionSlider.avaiableMin != undefined && resolutionSlider.avaiableMax != undefined)
                        {
                            current_start_x = (bar_left_right_margin + tick_left_right_margin) + step_size * (resolutionSlider.avaiableMin - resolutionSlider.fullRangeMin);
                            ctx.fillStyle = UM.Theme.getColor("quality_slider_available");
                            total_tick_count = resolutionSlider.avaiableMax - resolutionSlider.avaiableMin + 1;

                            const available_bar_width = step_size * (total_tick_count - 1);
                            ctx.fillRect(current_start_x, bar_top, available_bar_width, bar_thickness);

                            for (var i = 0; i < total_tick_count; ++i)
                            {
                                ctx.fillRect(current_start_x, tick_top, tick_width, tick_height);
                                current_start_x += step_size;
                            }
                        }

                        // print the selected circle
                        if (resolutionSlider.currentQualityIndex != undefined)
                        {
                            var circle_start_x = (bar_left_right_margin + tick_left_right_margin) + step_size * (resolutionSlider.currentQualityIndex - resolutionSlider.fullRangeMin);
                            circle_start_x = circle_start_x + tick_width / 2 - selected_circle_diameter / 2;
                            var circle_start_y = height / 2 - selected_circle_diameter / 2;
                            ctx.fillStyle = UM.Theme.getColor("quality_slider_handle");
                            ctx.beginPath();
                            ctx.ellipse(circle_start_x, circle_start_y, selected_circle_diameter, selected_circle_diameter);
                            ctx.fill();
                            ctx.closePath();
                        }

                        // print the hovered circle
                        if (resolutionSlider.currentHover != undefined && resolutionSlider.currentHover != resolutionSlider.currentQualityIndex)
                        {
                            var circle_start_x = (bar_left_right_margin + tick_left_right_margin) + step_size * (resolutionSlider.currentHover - resolutionSlider.fullRangeMin);
                            circle_start_x = circle_start_x + tick_width / 2 - selected_circle_diameter / 2;
                            var circle_start_y = height / 2 - selected_circle_diameter / 2;
                            ctx.fillStyle = UM.Theme.getColor("quality_slider_handle_hover");
                            ctx.beginPath();
                            ctx.ellipse(circle_start_x, circle_start_y, selected_circle_diameter, selected_circle_diameter);
                            ctx.fill();
                            ctx.closePath();
                        }

                        // print layer height texts
                        total_tick_count = resolutionSlider.totalTickCount;
                        const step_size = resolutionSlider.tickStepSize;
                        current_start_x = bar_left_right_margin + tick_left_right_margin;
                        for (var i = 0; i < total_tick_count; ++i)
                        {
                            const text_top = parent.height / 2 - tick_height - tick_text_height;
                            ctx.fillStyle = UM.Theme.getColor("quality_slider_text");

                            ctx.font = "12px sans-serif";
                            const string_length = resolutionSlider.model.getItem(i).layer_height_without_unit.length;
                            const offset = string_length / 2 * 4;

                            var start_x = current_start_x - offset;
                            if (i == 0)
                            {
                                start_x = 0;
                            }
                            else if (i == total_tick_count - 1)
                            {
                                start_x = current_start_x - offset * 2.5;
                            }

                            ctx.fillText(resolutionSlider.model.getItem(i).layer_height_without_unit, start_x, text_top);
                            current_start_x += step_size;
                        }
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked:
                        {
                            for (var i = 0; i < resolutionSlider.tickAreaList.length; ++i)
                            {
                                var area = resolutionSlider.tickAreaList[i];
                                if (area.start_x <= mouseX && mouseX <= area.end_x && area.start_y <= mouseY && mouseY <= area.end_y)
                                {
                                    resolutionSlider.currentHover = undefined;
                                    resolutionSlider.currentQualityIndex = area.id;

                                    Cura.MachineManager.setActiveQuality(resolutionSlider.model.getItem(resolutionSlider.currentQualityIndex).id);
                                    return;
                                }
                            }
                            resolutionSlider.currentHover = undefined;
                        }
                        onPositionChanged:
                        {
                            for (var i = 0; i < resolutionSlider.tickAreaList.length; ++i)
                            {
                                var area = resolutionSlider.tickAreaList[i];
                                if (area.start_x <= mouseX && mouseX <= area.end_x && area.start_y <= mouseY && mouseY <= area.end_y)
                                {
                                    resolutionSlider.currentHover = area.id;
                                    return;
                                }
                            }
                            resolutionSlider.currentHover = undefined;
                        }
                        onExited:
                        {
                            resolutionSlider.currentHover = undefined;
                        }
                    }
                }
            }

            //
            // Infill
            //
            Item
            {
                id: infillCellLeft

                anchors.top: speedLabel.bottom
                anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
                anchors.left: parent.left

                width: UM.Theme.getSize("sidebar").width * .45 - UM.Theme.getSize("sidebar_margin").width
                height: UM.Theme.getSize("sidebar_margin").height

                Text
                {
                    id: infillLabel
                    text: catalog.i18nc("@label", "Infill")
                    font: UM.Theme.getFont("default")
                    color: UM.Theme.getColor("text")

                    anchors.top: parent.top
                    anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
                    anchors.left: parent.left
                    anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
                }
            }

            Item
            {
                id: infillCellRight

                height: infillSlider.height + enableGradualInfillCheckBox.height + (UM.Theme.getSize("sidebar_margin").height * 2)
                width: UM.Theme.getSize("sidebar").width * .55

                anchors.left: infillCellLeft.right
                anchors.top: infillCellLeft.top
                anchors.topMargin: UM.Theme.getSize("sidebar_margin").height

                Text {
                    id: selectedInfillRateText

                    anchors.top: parent.top
                    anchors.left: infillSlider.left
                    anchors.leftMargin: (infillSlider.value / infillSlider.stepSize) * (infillSlider.width / (infillSlider.maximumValue / infillSlider.stepSize)) - 10
                    anchors.right: parent.right

                    text: infillSlider.value + "%"
                    horizontalAlignment: Text.AlignLeft

                    color: infillSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                }

                Slider
                {
                    id: infillSlider

                    anchors.top: selectedInfillRateText.bottom
                    anchors.left: parent.left
                    anchors.right: infillIcon.left
                    anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width

                    height: UM.Theme.getSize("sidebar_margin").height

                    minimumValue: 0
                    maximumValue: 100
                    stepSize: 10
                    tickmarksEnabled: true

                    // disable slider when gradual support is enabled
                    enabled: parseInt(infillSteps.properties.value) == 0

                    // set initial value from stack
                    value: parseInt(infillDensity.properties.value)

                    onValueChanged: {
                        infillDensity.setPropertyValue("value", infillSlider.value)
                    }

                    style: SliderStyle
                    {
                        groove: Rectangle {
                            id: groove
                            implicitWidth: 200
                            implicitHeight: 2
                            color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                            radius: 1
                        }

                        handle: Rectangle {
                            id: handleButton
                            anchors.centerIn: parent
                            color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 10
                        }

                        tickmarks: Repeater {
                            id: repeater
                            model: control.maximumValue / control.stepSize + 1
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                width: 1
                                height: 6
                                y: 0
                                x: styleData.handleWidth / 2 + index * ((repeater.width - styleData.handleWidth) / (repeater.count-1))
                            }
                        }
                    }
                }

                Item
                {
                    id: infillIcon

                    width: (infillCellRight.width / 5) - (UM.Theme.getSize("sidebar_margin").width)
                    height: width

                    anchors.right: infillCellRight.right
                    anchors.top: infillSlider.top

                    // we loop over all density icons and only show the one that has the current density and steps
                    Repeater
                    {
                        id: infillIconList
                        model: infillModel

                        property int activeIndex: {
                            for (var i = 0; i < infillModel.count; i++) {
                                var density = parseInt(infillDensity.properties.value)
                                var steps = parseInt(infillSteps.properties.value)
                                var infillModelItem = infillModel.get(i)

                                if (density >= infillModelItem.percentageMin
                                    && density <= infillModelItem.percentageMax
                                    && steps >= infillModelItem.stepsMin
                                    && steps <= infillModelItem.stepsMax){
                                        return i
                                    }
                            }
                            return -1
                        }

                        Item {
                            anchors.fill: parent

                            Rectangle {
                                anchors.fill: parent
                                visible: infillIconList.activeIndex == index

                                UM.RecolorImage {
                                    anchors.fill: parent
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    source: UM.Theme.getIcon(model.icon)
                                    color: UM.Theme.getColor("quality_slider_available")
                                }
                            }
                        }
                    }
                }

                //  Gradual Support Infill Checkbox
                CheckBox {
                    id: enableGradualInfillCheckBox
                    property alias _hovered: enableGradualInfillMouseArea.containsMouse

                    anchors.top: infillSlider.bottom
                    anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
                    anchors.left: infillCellRight.left

                    style: UM.Theme.styles.checkbox
                    enabled: base.settingsEnabled
                    checked: parseInt(infillSteps.properties.value) > 0

                    MouseArea {
                        id: enableGradualInfillMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: true

                        onClicked: {
                            infillSteps.setPropertyValue("value", (parseInt(infillSteps.properties.value) == 0) ? 5 : 0)
                            infillDensity.setPropertyValue("value", 90)
                        }

                        onEntered: {
                            base.showTooltip(enableGradualInfillCheckBox, Qt.point(-infillCellRight.x, 0),
                                catalog.i18nc("@label", "Gradual infill will gradually increase the amount of infill towards the top."))
                        }

                        onExited: {
                            base.hideTooltip()
                        }
                    }

                    Text {
                        id: gradualInfillLabel
                        anchors.left: enableGradualInfillCheckBox.right
                        anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width / 2 // FIXME better margin value
                        text: catalog.i18nc("@label", "Enable gradual")
                        font: UM.Theme.getFont("default")
                        color: UM.Theme.getColor("text")
                        elide: Text.ElideRight
                    }
                }

                //  Infill list model for mapping icon
                ListModel
                {
                    id: infillModel
                    Component.onCompleted:
                    {
                        infillModel.append({
                            percentageMin: -1,
                            percentageMax: 0,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "hollow"
                        })
                        infillModel.append({
                            percentageMin: 0,
                            percentageMax: 40,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "sparse"
                        })
                        infillModel.append({
                            percentageMin: 40,
                            percentageMax: 89,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "dense"
                        })
                        infillModel.append({
                            percentageMin: 90,
                            percentageMax: 9999999999,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "solid"
                        })
                        infillModel.append({
                            percentageMin: 0,
                            percentageMax: 9999999999,
                            stepsMin: 1,
                            stepsMax: 9999999999,
                            icon: "gradual"
                        })
                    }
                }
            }

            //
            //  Enable support
            //
            Text
            {
                id: enableSupportLabel
                visible: enableSupportCheckBox.visible

                anchors.top: enableSupportCheckBox.top

                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
                anchors.verticalCenter: enableSupportCheckBox.verticalCenter

                text: catalog.i18nc("@label", "Generate Support");
                font: UM.Theme.getFont("default");
                color: UM.Theme.getColor("text");
            }

            CheckBox
            {
                id: enableSupportCheckBox
                property alias _hovered: enableSupportMouseArea.containsMouse

                anchors.top: infillCellRight.bottom
                anchors.topMargin: UM.Theme.getSize("sidebar_margin").height * 2
                anchors.left: infillCellRight.left

                style: UM.Theme.styles.checkbox;
                enabled: base.settingsEnabled

                visible: supportEnabled.properties.enabled == "True"
                checked: supportEnabled.properties.value == "True";

                MouseArea
                {
                    id: enableSupportMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: true
                    onClicked:
                    {
                        // The value is a string "True" or "False"
                        supportEnabled.setPropertyValue("value", supportEnabled.properties.value != "True");
                    }
                    onEntered:
                    {
                        base.showTooltip(enableSupportCheckBox, Qt.point(-enableSupportCheckBox.x, 0),
                            catalog.i18nc("@label", "Generate structures to support parts of the model which have overhangs. Without these structures, such parts would collapse during printing."));
                    }
                    onExited:
                    {
                        base.hideTooltip();
                    }
                }
            }

            Text
            {
                id: supportExtruderLabel
                visible: supportExtruderCombobox.visible
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
                anchors.verticalCenter: supportExtruderCombobox.verticalCenter
                text: catalog.i18nc("@label", "Support Extruder");
                font: UM.Theme.getFont("default");
                color: UM.Theme.getColor("text");
            }

            ComboBox
            {
                id: supportExtruderCombobox
                visible: enableSupportCheckBox.visible && (supportEnabled.properties.value == "True") && (machineExtruderCount.properties.value > 1)
                model: extruderModel

                property string color_override: ""  // for manually setting values
                property string color:  // is evaluated automatically, but the first time is before extruderModel being filled
                {
                    var current_extruder = extruderModel.get(currentIndex);
                    color_override = "";
                    if (current_extruder === undefined) return ""
                    return (current_extruder.color) ? current_extruder.color : "";
                }

                textRole: "text"  // this solves that the combobox isn't populated in the first time Cura is started

                anchors.top: enableSupportCheckBox.bottom
                anchors.topMargin: ((supportEnabled.properties.value === "True") && (machineExtruderCount.properties.value > 1)) ? UM.Theme.getSize("sidebar_margin").height : 0
                anchors.left: infillCellRight.left

                width: UM.Theme.getSize("sidebar").width * .55
                height: ((supportEnabled.properties.value == "True") && (machineExtruderCount.properties.value > 1)) ? UM.Theme.getSize("setting_control").height : 0

                Behavior on height { NumberAnimation { duration: 100 } }

                style: UM.Theme.styles.combobox_color
                enabled: base.settingsEnabled
                property alias _hovered: supportExtruderMouseArea.containsMouse

                currentIndex: supportExtruderNr.properties !== null ? parseFloat(supportExtruderNr.properties.value) : 0
                onActivated:
                {
                    // Send the extruder nr as a string.
                    supportExtruderNr.setPropertyValue("value", String(index));
                }
                MouseArea
                {
                    id: supportExtruderMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: base.settingsEnabled
                    acceptedButtons: Qt.NoButton
                    onEntered:
                    {
                        base.showTooltip(supportExtruderCombobox, Qt.point(-supportExtruderCombobox.x, 0),
                            catalog.i18nc("@label", "Select which extruder to use for support. This will build up supporting structures below the model to prevent the model from sagging or printing in mid air."));
                    }
                    onExited:
                    {
                        base.hideTooltip();
                    }
                }

                function updateCurrentColor()
                {
                    var current_extruder = extruderModel.get(currentIndex);
                    if (current_extruder !== undefined) {
                        supportExtruderCombobox.color_override = current_extruder.color;
                    }
                }

            }

            Text
            {
                id: adhesionHelperLabel
                visible: adhesionCheckBox.visible
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
                anchors.right: infillCellLeft.right
                anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width
                anchors.verticalCenter: adhesionCheckBox.verticalCenter
                text: catalog.i18nc("@label", "Build Plate Adhesion");
                font: UM.Theme.getFont("default");
                color: UM.Theme.getColor("text");
                elide: Text.ElideRight
            }

            CheckBox
            {
                id: adhesionCheckBox
                property alias _hovered: adhesionMouseArea.containsMouse

                anchors.top: enableSupportCheckBox.visible ? supportExtruderCombobox.bottom : infillCellRight.bottom
                anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
                anchors.left: infillCellRight.left

                //: Setting enable printing build-plate adhesion helper checkbox
                style: UM.Theme.styles.checkbox;
                enabled: base.settingsEnabled

                visible: platformAdhesionType.properties.enabled == "True"
                checked: platformAdhesionType.properties.value != "skirt" && platformAdhesionType.properties.value != "none"

                MouseArea
                {
                    id: adhesionMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: base.settingsEnabled
                    onClicked:
                    {
                        var adhesionType = "skirt";
                        if(!parent.checked)
                        {
                            // Remove the "user" setting to see if the rest of the stack prescribes a brim or a raft
                            platformAdhesionType.removeFromContainer(0);
                            adhesionType = platformAdhesionType.properties.value;
                            if(adhesionType == "skirt" || adhesionType == "none")
                            {
                                // If the rest of the stack doesn't prescribe an adhesion-type, default to a brim
                                adhesionType = "brim";
                            }
                        }
                        platformAdhesionType.setPropertyValue("value", adhesionType);
                    }
                    onEntered:
                    {
                        base.showTooltip(adhesionCheckBox, Qt.point(-adhesionCheckBox.x, 0),
                            catalog.i18nc("@label", "Enable printing a brim or raft. This will add a flat area around or under your object which is easy to cut off afterwards."));
                    }
                    onExited:
                    {
                        base.hideTooltip();
                    }
                }
            }

            ListModel
            {
                id: extruderModel
                Component.onCompleted: populateExtruderModel()
            }

            //: Model used to populate the extrudelModel
            Cura.ExtrudersModel
            {
                id: extruders
                onModelChanged: populateExtruderModel()
            }

            Item
            {
                id: tipsCell
                anchors.top: adhesionCheckBox.visible ? adhesionCheckBox.bottom : (enableSupportCheckBox.visible ? supportExtruderCombobox.bottom : infillCellRight.bottom)
                anchors.topMargin: UM.Theme.getSize("sidebar_margin").height * 2
                anchors.left: parent.left
                width: parent.width
                height: tipsText.contentHeight * tipsText.lineCount

                Text
                {
                    id: tipsText
                    anchors.left: parent.left
                    anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
                    anchors.right: parent.right
                    anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width
                    anchors.top: parent.top
                    wrapMode: Text.WordWrap
                    text: catalog.i18nc("@label", "Need help improving your prints?<br>Read the <a href='%1'>Ultimaker Troubleshooting Guides</a>").arg("https://ultimaker.com/en/troubleshooting")
                    font: UM.Theme.getFont("default");
                    color: UM.Theme.getColor("text");
                    linkColor: UM.Theme.getColor("text_link")
                    onLinkActivated: Qt.openUrlExternally(link)
                }
            }

            UM.SettingPropertyProvider
            {
                id: infillExtruderNumber

                containerStackId: Cura.MachineManager.activeStackId
                key: "infill_extruder_nr"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: infillDensity
                containerStackId: Cura.MachineManager.activeStackId
                key: "infill_sparse_density"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: infillSteps
                containerStackId: Cura.MachineManager.activeStackId
                key: "gradual_infill_steps"
                watchedProperties: ["value"]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: platformAdhesionType

                containerStackId: Cura.MachineManager.activeMachineId
                key: "adhesion_type"
                watchedProperties: [ "value", "enabled" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportEnabled

                containerStackId: Cura.MachineManager.activeMachineId
                key: "support_enable"
                watchedProperties: [ "value", "enabled", "description" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: machineExtruderCount

                containerStackId: Cura.MachineManager.activeMachineId
                key: "machine_extruder_count"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportExtruderNr

                containerStackId: Cura.MachineManager.activeMachineId
                key: "support_extruder_nr"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }
        }
    }

    function populateExtruderModel()
    {
        extruderModel.clear();
        for(var extruderNumber = 0; extruderNumber < extruders.rowCount() ; extruderNumber++)
        {
            extruderModel.append({
                text: extruders.getItem(extruderNumber).name,
                color: extruders.getItem(extruderNumber).color
            })
        }
        supportExtruderCombobox.updateCurrentColor();
    }
}
