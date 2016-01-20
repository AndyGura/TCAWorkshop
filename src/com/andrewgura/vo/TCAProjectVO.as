package com.andrewgura.vo {

import com.andrewgura.controllers.TCAController;

import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

import mx.collections.ArrayCollection;

import spark.collections.Sort;
import spark.collections.SortField;

import starling.text.BitmapFont;

import starling.text.TextField;
import starling.textures.Texture;

[Bindable]
public class TCAProjectVO extends ProjectVO {

    public var outputTcaPath:String = '';
    public var imageCollection:ArrayCollection = new ArrayCollection();
    public static var tcaTextureTypeMap:Dictionary = prepareTextureTypeMap();
    public static var tcaTextureClassMap:Dictionary = prepareTextureClassMap();

    public var loadedPercent:Number = 100;
    public var isFullyLoaded:Boolean = true;

    private static function prepareTextureTypeMap():Dictionary {
        var dict:Dictionary = new Dictionary();
        dict[TextureVO] = 0;
        dict[TextureFontVO] = 1;
        return dict;
    }

    private static function prepareTextureClassMap():Dictionary {
        var dict:Dictionary = new Dictionary();
        dict[0] = TextureVO;
        dict[1] = TextureFontVO;
        return dict;
    }

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
            output.writeByte(tcaTextureTypeMap[Class(getDefinitionByName(getQualifiedClassName(texture)))]);
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
        for each (var fontTexture:TextureVO in imageCollection) {
            if (fontTexture is TextureFontVO) {
                starling.text.TextField.registerBitmapFont(new BitmapFont(Texture.fromAtfData(fontTexture.atfData), TextureFontVO(fontTexture).fontXML), fontTexture.name);
            }
        }
        isChangesSaved = true;
    }

    override public function importFiles(files:Array):void {
        isFullyLoaded = false;
        loadedPercent = 0;
        (new TCAController(this)).importFiles(files);
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
