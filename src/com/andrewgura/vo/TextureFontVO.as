package com.andrewgura.vo {
import com.andrewgura.utils.getObjectMemoryHash;

import flash.events.Event;
import flash.utils.ByteArray;

import starling.text.BitmapFont;
import starling.text.TextField;
import starling.textures.Texture;

[Bindable]
public class TextureFontVO extends TextureVO {

    private var _fontXML:XML = new XML();

    public function TextureFontVO(name:String) {
        super(name);
    }

    override public function serialize():ByteArray {
        var output:ByteArray = super.serialize();
        output.writeUTFBytes(_fontXML);
        return output;
    }

    override public function deserialize(data:ByteArray):void {
        super.deserialize(data);
        fontXML = new XML(data.readUTFBytes(data.bytesAvailable));
    }

    override public function get tcaData():Object {
        var data:Object = super.tcaData;
        data.texType = 1;
        data.fontXML = _fontXML;
        return data;
    }

    [Bindable(event="fontXMLChanged")]
    public function get fontXML():XML {
        return _fontXML;
    }

    public function set fontXML(value:XML):void {
        if (value == _fontXML) return;
        if (_fontXML) {
            TextField.unregisterBitmapFont(getObjectMemoryHash(this) + name);
        }
        _fontXML = value;
        if (_fontXML) {
            TextField.registerBitmapFont(new BitmapFont(Texture.fromAtfData(atfData), _fontXML), getObjectMemoryHash(this) + name);
        }
        dispatchEvent(new Event("fontXMLChanged"));
    }

    override public function set name(value:String):void {
        if (value == name) return;
        if (_fontXML) {
            TextField.unregisterBitmapFont(getObjectMemoryHash(this) + name);
            TextField.registerBitmapFont(new BitmapFont(Texture.fromAtfData(atfData), _fontXML), getObjectMemoryHash(this) + value);
        }
        super.name = value;
    }

    override public function set atfData(value:ByteArray):void {
        if (value == atfData) return;
        if (_fontXML) {
            TextField.unregisterBitmapFont(getObjectMemoryHash(this) + name);
            TextField.registerBitmapFont(new BitmapFont(Texture.fromAtfData(value), _fontXML), getObjectMemoryHash(this) + name);
        }
        super.atfData = value;
    }

}

}
