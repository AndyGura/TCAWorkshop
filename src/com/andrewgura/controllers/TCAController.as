package com.andrewgura.controllers {
import com.andrewgura.events.DataObjectEvent;
import com.andrewgura.nfs12NativeFileFormats.NFSNativeResourceLoader;
import com.andrewgura.nfs12NativeFileFormats.NativeFfnFile;
import com.andrewgura.nfs12NativeFileFormats.NativeShpiArchiveFile;
import com.andrewgura.nfs12NativeFileFormats.textures.bitmaps.INativeBitmap;
import com.andrewgura.ui.popup.AppPopups;
import com.andrewgura.ui.popup.PopupFactory;
import com.andrewgura.utils.DictionaryUtils;
import com.andrewgura.utils.TextureLoader;
import com.andrewgura.vo.FontTextureVO;
import com.andrewgura.vo.TCAProjectVO;
import com.andrewgura.vo.TextureVO;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.FileFilter;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

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

    private var loaders:Dictionary;
    private var texCount:Number = 0;

    public function importFiles(files:Array):void {
        var textureWrap:TextureLoader;
        var texture:TextureVO;
        loaders = new Dictionary();
        texCount = 0;
        for each (var file:File in files) {
            switch (file.extension.toLowerCase()) {
                case 'png':
                case 'jpg':
                    texture = new TextureVO(file.name.substr(0, file.name.length - 4));
                    addTexture(texture);
                    textureWrap = new TextureLoader(texture, file.nativePath);
                    textureWrap.addEventListener(TextureLoader.GENERATION_DONE_EVENT, onATFGenerationComplete);
                    textureWrap.addEventListener(TextureLoader.GENERATION_PERCENT_EVENT, onATFPercentEvent);
                    loaders[textureWrap] = 0;
                    texCount++;
                    break;
                default:
                    try {
                        var nfsData:* = NFSNativeResourceLoader.loadNativeFile(file);
                    } catch (e:Error) {
                        PopupFactory.instance.showPopup(AppPopups.ERROR_POPUP, file.name + ": " + e.message);
                        continue;
                    }
                    importNfsData(nfsData);
                    break;
            }
        }
        project.loadedPercent = 30;
    }

    public function importNfsData(nfsData:*):void {
        project.loadedPercent = 0;
        project.isFullyLoaded = false;
        if (!loaders) {
            loaders = new Dictionary();
        }
        var texture:TextureVO;
        var textureWrap:TextureLoader;
        if (nfsData is NativeShpiArchiveFile) {
            for each (var nfsTexture:INativeBitmap in nfsData) {
                texture = new TextureVO(nfsTexture.name);
                addTexture(texture);
                textureWrap = new TextureLoader(texture);
                textureWrap.loadByBitmap(new Bitmap(BitmapData(nfsTexture)));
                textureWrap.addEventListener(TextureLoader.GENERATION_DONE_EVENT, onATFGenerationComplete);
                textureWrap.addEventListener(TextureLoader.GENERATION_PERCENT_EVENT, onATFPercentEvent);
                loaders[textureWrap] = 0;
                texCount++;
            }
        } else if (nfsData is NativeFfnFile) {
            texture = new FontTextureVO(nfsData.name);
            addTexture(texture);
            textureWrap = new TextureLoader(texture);
            textureWrap.loadByBitmap(new Bitmap(nfsData));
            textureWrap.addEventListener(TextureLoader.GENERATION_DONE_EVENT, onATFGenerationComplete);
            textureWrap.addEventListener(TextureLoader.GENERATION_PERCENT_EVENT, onATFPercentEvent);
            loaders[textureWrap] = 0;
            texCount++;
        }
    }

    private function onATFGenerationComplete(event:Event):void {
        event.target.removeEventListener(TextureLoader.GENERATION_DONE_EVENT, onATFGenerationComplete);
        event.target.removeEventListener(TextureLoader.GENERATION_PERCENT_EVENT, onATFPercentEvent);
        delete loaders[event.target];
        var percent:Number = 30 + 70 * (1 - DictionaryUtils.countKeys(loaders) / texCount);
        var parPercent:Number = 0;
        for (var key:* in loaders) {
            parPercent += loaders[key];
        }
        percent += ((parPercent / 100) * (100 - percent)) / (DictionaryUtils.countKeys(loaders));
        project.loadedPercent = percent;
        if (DictionaryUtils.countKeys(loaders) == 0) {
            project.isFullyLoaded = true;
            project.dispatchEvent(new Event(TCAProjectVO.LOADING_COMPLETE));
        }
    }

    private function onATFPercentEvent(event:DataObjectEvent):void {
        loaders[event.target] = event.data;
        var percent:Number = 30 + 70 * (1 - DictionaryUtils.countKeys(loaders) / texCount);
        var parPercent:Number = 0;
        for (var key:* in loaders) {
            parPercent += loaders[key];
        }
        percent += ((parPercent / 100) * (100 - percent)) / (DictionaryUtils.countKeys(loaders));
        project.loadedPercent = percent;
    }

    public function exportPicture(name:String):void {
        var texture:TextureVO = getTextureByName(name);
        if (!texture) {
            return;
        }
        var pngData:ByteArray = (new PNGEncoder()).encode(texture.sourceBitmap.bitmapData);
        var f:File;
        if (project.outputTcaPath) {
            f = File.applicationDirectory.resolvePath(project.fileName);
            f = f.parent.resolvePath(project.outputTcaPath);
        } else {
            f = new File();
        }
        f.save(pngData, name + '.png');
    }

    public function exportAtf(name:String):void {
        var texture:TextureVO = getTextureByName(name);
        if (!texture) {
            return;
        }
        var f:File;
        if (project.outputTcaPath) {
            f = File.applicationDirectory.resolvePath(project.fileName);
            f = f.parent.resolvePath(project.outputTcaPath);
        } else {
            f = new File();
        }
        f.save(texture.atfData, name + '.atf');
    }

    public function createFont(texture:TextureVO):void {
        var newTexture:FontTextureVO = new FontTextureVO(texture.name);
        newTexture.sourceBitmap = texture.sourceBitmap;
        newTexture.atfData = texture.atfData;
        newTexture.originalWidth = texture.originalWidth;
        newTexture.originalHeight = texture.originalHeight;
        newTexture.atfWidth = texture.atfWidth;
        newTexture.atfHeight = texture.atfHeight;
        project.imageCollection.setItemAt(newTexture, project.imageCollection.getItemIndex(texture));
    }

    public function importFontXml(font:FontTextureVO):void {
        var f:File = new File();
        f.addEventListener(Event.SELECT, onFileSelected);
        f.addEventListener(Event.CANCEL, onFileSelectionCanceled);
        f.browseForOpen('Select font XML', [new FileFilter('Font XML', '*.fnt')]);

        function onFileSelected(event:Event):void {
            File(event.target).removeEventListener(Event.SELECT, onFileSelected);
            File(event.target).removeEventListener(Event.CANCEL, onFileSelectionCanceled);
            var stream:FileStream = new FileStream();
            stream.open(File(event.target), FileMode.READ);
            var xml:XML = new XML(stream.readUTFBytes(stream.bytesAvailable));
            font.fontXML = xml;
        }

        function onFileSelectionCanceled(event:Event):void {
            File(event.target).removeEventListener(Event.SELECT, onFileSelected);
            File(event.target).removeEventListener(Event.CANCEL, onFileSelectionCanceled);
        }
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

    public function addTextures(textures:Array):void {
        if (textures && textures.length > 0) {
            for each (var texture:TextureVO in textures) {
                addTexture(texture);
            }
        }
    }

    public function addTexture(texture:TextureVO):void {
        if (project.imageCollection.getItemIndex(texture) > -1) {
            return;
        }
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
        var foundTexture:TextureVO = getTextureByName(newName);
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
