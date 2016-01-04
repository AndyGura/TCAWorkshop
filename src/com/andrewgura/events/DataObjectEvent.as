package com.andrewgura.events {
import flash.events.Event;

public class DataObjectEvent extends Event {

    public var data:*;

    public function DataObjectEvent(type:String, data:*, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(type, bubbles, cancelable);
        this.data = data;
    }


    override public function clone():Event {
        var clone:DataObjectEvent = DataObjectEvent(super.clone());
        clone.data = data;
        return clone;
    }
}
}
