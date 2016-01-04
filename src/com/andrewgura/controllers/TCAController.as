package com.andrewgura.controllers {
import com.andrewgura.nfs12NativeFileFormats.NFSNativeResourceLoader;
import com.andrewgura.nfs12NativeFileFormats.textures.bitmaps.INativeBitmap;
import com.andrewgura.ui.popup.AppPopups;
import com.andrewgura.ui.popup.PopupFactory;
import com.andrewgura.utils.TextureLoader;
import com.andrewgura.vo.TCAProjectVO;
import com.andrewgura.vo.TextureVO;

import flash.display.Bitmap;
import flash.display.BitmapData;

import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;

import mx.events.CollectionEvent;
import mx.events.CollectionEventKind;
import mx.graphics.codec.PNGEncoder;

public class TCAController {

    private var project:TCAProjectVO;

    public function TCAController(project:TCAProjectVO) {
        this.project = project;
        this.project.imageCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onImagesChange);
    }

    public function onImagesChange(event:CollectionEvent):void {
        project.isChangesSaved = false;
        if (event.kind == CollectionEventKind.ADD || event.kind == CollectionEventKind.MOVE || event.kind == CollectionEventKind.UPDATE || event.kind == CollectionEventKind.REPLACE) {
            project.imageCollection.refresh();
        }
    }

    public function importFiles(files:Array):void {
        var textureWrap:TextureLoader;
        var texture:TextureVO;
        for each (var file:File in files) {
            switch (file.extension.toLowerCase()) {
                case 'png':
                case 'jpg':
                    texture = new TextureVO(file.name.substr(0, file.name.length - 4));
                    addTexture(texture);
                    textureWrap = new TextureLoader(texture, file.nativePath);
                    break;
                case 'fsh':
                case 'qfs':
                    try {
                        var nfsTextures:ArrayCollection = NFSNativeResourceLoader.loadTextureFile(file);
                    } catch (e:Error) {
                        PopupFactory.instance.showPopup(AppPopups.ERROR_POPUP, e.message);
                        return;
                    }
                    for each (var nfsTexture:INativeBitmap in nfsTextures) {
                        texture = new TextureVO(nfsTexture.name);
                        addTexture(texture);
                        textureWrap = new TextureLoader(texture);
                        textureWrap.loadByBitmap(new Bitmap(BitmapData(nfsTexture)));
                    }
                    break;
            }
        }
    }

    public function exportPicture(name:String, isOriginal:Boolean):void {
        var texture:TextureVO = getTextureByName(name);
        if (!texture) {
            return;
        }
        var pngData:ByteArray = (new PNGEncoder()).encode(isOriginal ? texture.sourceBitmap.bitmapData : texture.bitmap.bitmapData);
        var f:File;
        if (project.outputTcaPath) {
            f = File.applicationDirectory.resolvePath(project.fileName);
            f = f.parent.resolvePath(project.outputTcaPath);
        } else {
            f = new File();
        }
        f.save(pngData, name + '.png');
    }

    public function exportTCA():void {
        var outputDirectory:File;
        var outputPath:String = TCAProjectVO(project).outputTcaPath;
        if (outputPath.substr(0, 1) == "/") {
            //we are using MVAWorkshop on linux under wine;
            outputPath = 'Z:' + outputPath;
        }
        try {
            var windowsPartitionPathIndex:Number = Math.max(outputPath.indexOf(':\\'), outputPath.indexOf(':/'));
            if (windowsPartitionPathIndex == -1) {
                // we are using relative output path;
                var targetFile:File = (new File()).resolvePath(project.fileName);
                outputDirectory = targetFile.parent.resolvePath(outputPath);
            } else {
                outputDirectory = new File(outputPath);
            }
        } catch (e:Error) {
        }
        if (!outputDirectory || !outputDirectory.exists || !outputDirectory.isDirectory) {
            exportError('Wrong output project directory!');
            return;
        }
        var fs:FileStream = new FileStream();
        var tcaData:ByteArray = project.getExportedTCA();
        fs.open(outputDirectory.resolvePath(project.name + '.tca'), FileMode.WRITE);
        fs.writeBytes(tcaData);
        fs.close();
        PopupFactory.instance.showPopup(AppPopups.INFO_POPUP, 'Export success!');
    }

    private function exportError(msg:String):void {
        PopupFactory.instance.showPopup(AppPopups.ERROR_POPUP, msg, true, null, onOkClick);
        function onOkClick(event:Event):void {
            MainController.openProjectSettings();
        }
    }

    public function addTexture(texture:TextureVO):void {
        var newName:String = getNewNameForDuplicate(texture.name);
        texture.name = newName;
        project.imageCollection.addItem(texture);
    }

    public function deleteItems(items:Array):void {
        if (project.imageCollection.length == 0) {
            return;
        }
        for each (var item:* in items) {
            project.imageCollection.removeItem(item);
        }
    }

    public function getNewNameForDuplicate(name:String, excludeIndex:Number = -1):String {
        var newName:String = name;
        var i:Number = 0;
        var foundTexture:TextureVO =  getTextureByName(newName);
        while (foundTexture != null && project.imageCollection.getItemIndex(foundTexture) != excludeIndex) {
            i++;
            newName = name + '_' + i;
            foundTexture = getTextureByName(newName);
        }
        return newName;
    }

    public function getTextureByName(name:String):TextureVO {
        for each (var texture:TextureVO in project.imageCollection) {
            if (texture.name == name) {
                return texture;
            }
        }
        return null;
    }

}
}
