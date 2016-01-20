package com.andrewgura.utils {
import flash.utils.Dictionary;

public class DictionaryUtils {

    public static function countKeys(myDictionary:Dictionary):int {
        var n:int = 0;
        for (var key:* in myDictionary) {
            n++;
        }
        return n;
    }

}
}
