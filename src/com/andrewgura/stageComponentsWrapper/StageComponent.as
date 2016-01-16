package com.andrewgura.stageComponentsWrapper {
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.core.FlexGlobals;
import mx.core.UIComponent;
import mx.events.FlexEvent;
import mx.events.ResizeEvent;

import spark.components.Group;
import spark.components.supportClasses.GroupBase;
import spark.core.MaskType;

import starling.core.Starling;

public class StageComponent extends Group {

    private static var starlingMasks:Array = [];
    public static var initialize:* = function init():void {
        var application:DisplayObject = DisplayObject(FlexGlobals.topLevelApplication);
        application.addEventListener(Event.ADDED_TO_STAGE, onApplicationAddedToStage);
    }();

    private static function onApplicationAddedToStage(event:Event):void {
        var stage:Stage = FlexGlobals.topLevelApplication.stage;
        stage.addEventListener(ResizeEvent.RESIZE, onStageResized);
        stage.align = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
    }

    protected static function onStageResized(e:Event = null):void {
        if (visibleStarlingComponentsCount == 0) {
            return;
        }
        var stage:Stage = FlexGlobals.topLevelApplication.stage;
        if (stage.stageWidth == 0 || stage.stageHeight == 0) {
            return;
        }
        var stageWidth:Number = Number.max(stage.stageWidth, 32);
        var stageHeight:Number = Number.max(stage.stageHeight, 32);
        var viewPortRectangle:Rectangle = new Rectangle();
        viewPortRectangle.width = stageWidth;
        viewPortRectangle.height = stageHeight;
        if (Starling.current && Starling.current.stage) {
            Starling.current.viewPort = viewPortRectangle;
            Starling.current.stage.stageWidth = stageWidth;
            Starling.current.stage.stageHeight = stageHeight;
        }
    }

    protected var application:DisplayObject = DisplayObject(FlexGlobals.topLevelApplication);
    protected var parentsInfo:Array = [];
    protected var isShow:Boolean = false;
    protected var currentMask:Sprite;
    protected static var maskGroup:Group;
    protected static var fullMask:UIComponent;
    protected static var visibleStarlingComponentsCount:Number = 0;

    private function addedToStageHandler(event:Event):void {
        updateMask();
        setupParents();
        if (isGloballyVisible()) {
            setMask();
            isShow = true;
            visibleStarlingComponentsCount++;
            if (visibleStarlingComponentsCount == 1) {
                onStageResized();
            }
        }
    }

    protected function setupParents():void {
        runOnParents(a);
        function a(displayObject:DisplayObject):void {
            parentsInfo.push({displayObject: displayObject, originalMask: displayObject.mask});
            if (displayObject == this || displayObject == application) {
                displayObject.addEventListener(ResizeEvent.RESIZE, onResize);
            }
            displayObject.addEventListener(FlexEvent.SHOW, hideShowHandler);
            displayObject.addEventListener(FlexEvent.HIDE, hideShowHandler);
        }
    }

    private function onResize(event:Event):void {
        callLater(onResizeWithDelay);
    }

    protected function onResizeWithDelay():void {
        if (visibleStarlingComponentsCount == 0) {
            return;
        }
        updateMask();
    }

    protected function updateMask():void {
        if (!fullMask) {
            fullMask = new UIComponent();
            fullMask.blendMode = BlendMode.LAYER;
        }
        if (!maskGroup) {
            maskGroup = new Group();
            maskGroup.width = application.width;
            maskGroup.height = application.height;
            maskGroup.addElement(fullMask);
        }
        fullMask.graphics.clear();
        fullMask.graphics.beginFill(0x666666);
        fullMask.graphics.drawRect(0, 0, application.width, application.height);
        fullMask.graphics.endFill();

        var thisRealPosition:Point = localToGlobal(new Point());
        if (!currentMask) {
            currentMask = new Sprite();
            currentMask.blendMode = BlendMode.ERASE;
        }
        currentMask.graphics.clear();
        currentMask.graphics.beginFill(0);
        currentMask.graphics.drawRect(thisRealPosition.x, thisRealPosition.y, this.width, this.height);
        currentMask.graphics.endFill();
    }

    protected function setMask():void {
        for each (var o:* in parentsInfo) {
            var displayObject:DisplayObject = o.displayObject;
            if (displayObject == this || !(displayObject is GroupBase)) {
                continue;
            }
            GroupBase(displayObject).mask = maskGroup;
            GroupBase(displayObject).maskType = MaskType.ALPHA;
        }
        fullMask.addChild(currentMask);
    }

    protected function unsetMask():void {
        if (fullMask && fullMask.getChildIndex(currentMask) > -1) {
            fullMask.removeChild(currentMask);
        }
        if (fullMask.numChildren == 0) {
            for each (var o:* in parentsInfo) {
                var displayObject:DisplayObject = o.displayObject;
                if (displayObject == this || !(displayObject is GroupBase)) {
                    continue;
                }
                GroupBase(displayObject).mask = null;
            }
        }
    }

    protected function hideShowHandler(event:FlexEvent):void {
        if (isGloballyVisible()) {
            if (!isShow) {
                updateMask();
                setMask();
                isShow = true;
                visibleStarlingComponentsCount++;
                if (visibleStarlingComponentsCount == 1) {
                    onStageResized();
                }
            }
        } else {
            if (isShow) {
                unsetMask();
                isShow = false;
                visibleStarlingComponentsCount--;
            }
        }
    }

    protected function isGloballyVisible():Boolean {
        var isVisible:Boolean = true;
        for each (var info:* in parentsInfo) {
            var displayObject:DisplayObject = info.displayObject;
            if (!displayObject.visible) {
                isVisible = false;
                break;
            }
        }
        return isVisible;
    }

    private function runOnParents(func:Function, displayObject:DisplayObject = null):void {
        if (!displayObject) {
            displayObject = this;
        }
        func(displayObject);
        if (displayObject != application) {
            runOnParents(func, displayObject.parent);
        }
    }
}
}
