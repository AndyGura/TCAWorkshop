package com.andrewgura.vo {
import flash.utils.ByteArray;

[Bindable]
public class TextureFontVO extends TextureVO {

    public var fontXML:XML = new XML();

    public function TextureFontVO(name:String) {
        super(name);
    }

    override public function serialize():ByteArray {
        var output:ByteArray = super.serialize();
        output.writeUTFBytes(fontXML);
        return output;
    }

    override public function deserialize(data:ByteArray):void {
        super.deserialize(data);
        fontXML = new XML(data.readUTFBytes(data.bytesAvailable));
    }

    override public function get tcaData():Object {
        var data:Object = super.tcaData;
        data.texType = 1;
        data.fontXML = fontXML;
        return data;
    }
}

}
