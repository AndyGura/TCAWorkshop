package com.andrewgura.controllers {
import com.andrewgura.vo.TCAProjectVO;

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

    public function deleteItem(index:Number):void {
        if (project.imageCollection.length == 0) {
            return;
        }
        project.imageCollection.removeItemAt(index);
    }

}
}
