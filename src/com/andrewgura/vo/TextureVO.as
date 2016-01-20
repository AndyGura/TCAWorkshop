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

    public var atfData:ByteArray;
    public var name:String;

    public function TextureVO(name:String) {
        this.name = name;
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
        output.writeObject({name: name, atfData: atfData, atfWidth: atfWidth, atfHeight: atfHeight});
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
        return {texType: 0, name: name, data: atfData};
    }

}
}