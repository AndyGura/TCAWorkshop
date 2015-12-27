package com.andrewgura.vo {

import flash.display.Bitmap;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;

[Bindable]
public class TCAProjectVO extends ProjectVO {

    public var imageCollection:ArrayCollection = new ArrayCollection();

    override public function serialize():ByteArray {
        var output:ByteArray = super.serialize();
        for each (var texture:TextureVO in imageCollection) {
            output.writeObject(texture.serialize());
        }
        return output;
    }

    override public function deserialize(name:String, fileName:String, data:ByteArray):void {
        super.deserialize(name, fileName, data);
        imageCollection = new ArrayCollection();
        while (data.bytesAvailable>0) {
            var texture:TextureVO = new TextureVO('');
            texture.deserialize(data.readObject());
            imageCollection.addItem(texture);
        }
    }
}

}
