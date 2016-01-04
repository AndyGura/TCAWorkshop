package com.andrewgura.vo {

import com.andrewgura.utils.TextureLoader;

import flash.filesystem.File;
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
        output.compress();
        return output;
    }

    override public function deserialize(name:String, fileName:String, data:ByteArray):void {
        super.deserialize(name, fileName, data);
        imageCollection = new ArrayCollection();
        data.uncompress();
        while (data.bytesAvailable > 0) {
            var texture:TextureVO = new TextureVO('');
            texture.deserialize(data.readObject());
            imageCollection.addItem(texture);
        }
    }

    override public function importFiles(files:Array):void {
        for each (var file:File in files) {
            var texture:TextureVO = new TextureVO(file.name.substr(0, file.name.length - 4));
            imageCollection.addItem(texture);
            var textureWrap:TextureLoader = new TextureLoader(texture, file.nativePath);
        }
    }
}

}
