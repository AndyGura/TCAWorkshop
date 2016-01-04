package com.andrewgura.vo {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

[Bindable]
public class TextureVO {

    public var width:Number;
    public var height:Number;
    public var atfData:ByteArray;
    public var sourceBitmap:Bitmap;
    private var _bitmap:Bitmap;
    public var name:String;

    public var processingProgress:Number = 0;

    public function TextureVO(name:String) {
        this.name = name;
    }

    [Bindable(event="bitmapChanged")]
    public function get bitmap():Bitmap {
        return _bitmap;
    }

    public function set bitmap(value:Bitmap):void {
        _bitmap = value;
        this.width = value.width;
        this.height = value.height;
        dispatchEvent(new Event("bitmapChanged"));
    }

    public function serialize():ByteArray {
        var output:ByteArray = new ByteArray();
        output.writeObject(this);
        var rect:Rectangle = new Rectangle(0, 0, sourceBitmap.width, sourceBitmap.height);
        var bytes:ByteArray = sourceBitmap.bitmapData.getPixels(rect);
        output.writeObject({rect: rect, data: bytes});
        rect = new Rectangle(0, 0, bitmap.width, bitmap.height);
        var bytes:ByteArray = bitmap.bitmapData.getPixels(rect);
        output.writeObject({rect: rect, data: bytes});
        return output;
    }

    public function deserialize(data:ByteArray):void {
        var o:* = data.readObject();
        for (var field:String in o) {
            if (field != "bitmap" && field != "sourceBitmap") {
                this[field] = o[field];
            }
        }
        o = data.readObject();
        var rect:Rectangle = new Rectangle(0, 0, o.rect.width, o.rect.height);
        var bitmapData:BitmapData = new BitmapData(rect.width, rect.height, true);
        bitmapData.setPixels(rect, o.data);
        sourceBitmap = new Bitmap(bitmapData);
        o = data.readObject();
        rect = new Rectangle(0, 0, o.rect.width, o.rect.height);
        bitmapData = new BitmapData(rect.width, rect.height, true);
        bitmapData.setPixels(rect, o.data);
        bitmap = new Bitmap(bitmapData);
    }

}
}