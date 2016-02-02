package com.andrewgura.vo {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

[Bindable]
public class TextureVO {

    private var _sourceBitmap:Bitmap;
    public var originalWidth:Number;
    public var originalHeight:Number;
    public var atfWidth:Number;
    public var atfHeight:Number;

    private var _atfData:ByteArray;
    private var _name:String;


    [Bindable(event="atfDataChanged")]
    public function get atfData():ByteArray {
        return _atfData;
    }

    public function set atfData(value:ByteArray):void {
        if (_atfData == value) return;
        _atfData = value;
        dispatchEvent(new Event("atfDataChanged"));
    }

    [Bindable(event="nameChanged")]
    public function get name():String {
        return _name;
    }

    public function set name(value:String):void {
        if (_name == value) return;
        _name = value;
        dispatchEvent(new Event("nameChanged"));
    }

    public function TextureVO(name:String) {
        this._name = name;
    }

    [Bindable(event="sourceBitmapChanged")]
    public function get sourceBitmap():Bitmap {
        return _sourceBitmap;
    }

    public function set sourceBitmap(value:Bitmap):void {
        if (_sourceBitmap == value) return;
        _sourceBitmap = value;
        this.originalWidth = value.width;
        this.originalHeight = value.height;
        dispatchEvent(new Event("sourceBitmapChanged"));
    }

    public function serialize():ByteArray {
        var output:ByteArray = new ByteArray();
        output.writeObject({name: _name, atfData: _atfData, atfWidth: atfWidth, atfHeight: atfHeight});
        var rect:Rectangle = new Rectangle(0, 0, sourceBitmap.width, sourceBitmap.height);
        var bytes:ByteArray = sourceBitmap.bitmapData.getPixels(rect);
        output.writeObject({rect: rect, data: bytes});
        return output;
    }

    public function deserialize(data:ByteArray):void {
        var o:* = data.readObject();
        for (var field:String in o) {
            this[field] = o[field];
        }
        o = data.readObject();
        var rect:Rectangle = new Rectangle(0, 0, o.rect.width, o.rect.height);
        var bitmapData:BitmapData = new BitmapData(rect.width, rect.height, true);
        bitmapData.setPixels(rect, o.data);
        sourceBitmap = new Bitmap(bitmapData);
    }

    public function get tcaData():Object {
        return {texType: 0, name: _name, data: _atfData};
    }
}
}