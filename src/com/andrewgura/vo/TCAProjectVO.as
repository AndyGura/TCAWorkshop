package com.andrewgura.vo {

import com.andrewgura.controllers.TCAController;

import flash.utils.ByteArray;

import mx.collections.ArrayCollection;

import spark.collections.Sort;
import spark.collections.SortField;

[Bindable]
public class TCAProjectVO extends ProjectVO {

    public var outputTcaPath:String = '';

    public var imageCollection:ArrayCollection = new ArrayCollection();

    public function TCAProjectVO() {
        super();
        var sort:Sort = new Sort();
        sort.fields = [new SortField("name")];
        imageCollection.sort = sort;
        imageCollection.refresh();
    }

    override public function serialize():ByteArray {
        var output:ByteArray = super.serialize();
        output.writeObject({
            outputTcaPath: outputTcaPath
        });
        for each (var texture:TextureVO in imageCollection) {
            output.writeObject(texture.serialize());
        }
        output.compress();
        return output;
    }

    override public function deserialize(name:String, fileName:String, data:ByteArray):void {
        super.deserialize(name, fileName, data);
        data.uncompress();
        var settings:* = data.readObject();
        this.outputTcaPath = settings.outputTcaPath;
        while (data.bytesAvailable > 0) {
            var texture:TextureVO = new TextureVO('');
            texture.deserialize(data.readObject());
            imageCollection.addItem(texture);
        }
        isChangesSaved = true;
    }

    override public function importFiles(files:Array):void {
        (new TCAController(this)).importFiles(files);
    }

    public function getExportedTCA():ByteArray {
        var output:ByteArray = new ByteArray();
        for each (var texture:TextureVO in imageCollection) {
            output.writeObject({name: texture.name, data: texture.atfData});
        }
        output.compress();
        return output;
    }

}

}
