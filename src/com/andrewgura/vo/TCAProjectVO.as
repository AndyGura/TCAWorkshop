package com.andrewgura.vo {

import com.andrewgura.controllers.TCAController;

import flash.utils.ByteArray;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.events.CollectionEvent;
import mx.events.DragEvent;

import spark.collections.Sort;
import spark.collections.SortField;

[Bindable]
public class TCAProjectVO extends ProjectVO {

    public static const TEXTURES_COLLECTION_CHANGE:String = "TEXTURES_COLLECTION_CHANGE";
    public static const LOADING_COMPLETE:String = 'LOADING_COMPLETE';

    public var outputTcaPath:String = '';
    public var imageCollection:ArrayCollection = new ArrayCollection();
    public static var tcaTextureClassMap:Dictionary = prepareTextureClassMap();

    public var loadedPercent:Number = 100;
    public var isFullyLoaded:Boolean = true;

    private static function prepareTextureClassMap():Dictionary {
        var dict:Dictionary = new Dictionary();
        dict[0] = TextureVO;
        dict[1] = FontTextureVO;
        return dict;
    }

    public function TCAProjectVO() {
        super();
        var sort:Sort = new Sort();
        sort.fields = [new SortField("name")];
        imageCollection.sort = sort;
        imageCollection.refresh();
        imageCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onTextureCollectionChange);
    }

    private function onTextureCollectionChange(event:CollectionEvent):void {
        dispatchEvent(new CollectionEvent(TEXTURES_COLLECTION_CHANGE, false, false, event.kind, event.location, event.oldLocation, event.items));
    }

    override public function serialize():ByteArray {
        var output:ByteArray = super.serialize();
        output.writeObject({
            outputTcaPath: outputTcaPath
        });
        for each (var texture:TextureVO in imageCollection) {
            output.writeByte(texture.textureType);
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
            var texClass:Class = tcaTextureClassMap[data.readByte()];
            var texture:TextureVO = new texClass('');
            texture.deserialize(data.readObject());
            imageCollection.addItem(texture);
        }
        isChangesSaved = true;
    }

    override public function importFiles(files:Array):void {
        isFullyLoaded = false;
        loadedPercent = 0;
        (new TCAController(this)).importFiles(files);
    }

    override public function processDragDrop(event:DragEvent):void {
        var dropTextures:* = event.dragSource.dataForFormat("textureListItems");
        (new TCAController(this)).addTextures(dropTextures);
    }

    public function getExportedTCA():ByteArray {
        var output:ByteArray = new ByteArray();
        for each (var texture:TextureVO in imageCollection) {
            output.writeObject(texture.tcaData);
        }
        output.compress();
        return output;
    }

}

}
