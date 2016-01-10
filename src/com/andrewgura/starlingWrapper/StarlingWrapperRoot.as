package com.andrewgura.starlingWrapper {

import starling.display.Sprite;

public class StarlingWrapperRoot extends Sprite {


    public function StarlingWrapperRoot() {
        super();
        StarlingComponent.starlingRoot = this;
    }


}
}
