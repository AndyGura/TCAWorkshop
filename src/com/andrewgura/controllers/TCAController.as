package com.andrewgura.controllers {
import com.andrewgura.utils.TextureLoader;
import com.andrewgura.vo.TCAProjectVO;
import com.andrewgura.vo.TextureVO;

import flash.filesystem.File;

import mx.events.CollectionEvent;

public class TCAController {

    private var project:TCAProjectVO;

    public function TCAController(project:TCAProjectVO) {
        this.project = project;
        this.project.imageCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onImagesChange);
    }

    public function onImagesChange(event:CollectionEvent):void {
        project.isChangesSaved = false;
    }

    public function addTexturesFromImageFiles(textures:Array):void {
        for each (var file:File in textures) {
            var texture:TextureVO = new TextureVO(file.name.substr(0, file.name.length-4));
            project.imageCollection.addItem(texture);
            var textureWrap:TextureLoader = new TextureLoader(texture, file.nativePath);
        }
    }

    public function deleteItem(index:Number):void {
        if (project.imageCollection.length == 0) {
            return;
        }
        project.imageCollection.removeItemAt(index);
    }

}
}
