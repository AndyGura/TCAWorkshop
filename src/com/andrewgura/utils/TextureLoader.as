package com.andrewgura.utils {

import com.andrewgura.vo.TextureVO;

import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.setTimeout;

import mx.graphics.codec.PNGEncoder;

public class TextureLoader extends EventDispatcher {

    public static var canExecuteATF2PNG:Number = 8;

    public static const GENERATION_DONE_EVENT:String = "GENERATION_DONE_EVENT";

    public function TextureLoader(texture:TextureVO, nativePath:String) {
        texture.processingProgress = 10;
        this.texture = texture;
        var loader:Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
        loader.load(new URLRequest(nativePath));
    }

    private var texture:TextureVO;
    private var tempDirectory:File;

    private function encodePNG():void {
        var pngData:ByteArray = (new PNGEncoder()).encode(texture.bitmap.bitmapData);
        texture.processingProgress = 60;
        var file:File = new File(tempDirectory.nativePath + '\\' + texture.name + '.png');
        var fs:FileStream = new FileStream();
        fs.open(file, FileMode.WRITE);
        fs.writeBytes(pngData, 0, pngData.length);
        fs.close();
        executePNG2ATF();
    }

    private function executePNG2ATF():void {
        if (canExecuteATF2PNG < 1) {
            setTimeout(executePNG2ATF, 500);
            return;
        }
        canExecuteATF2PNG--;
        var nativeProcess:NativeProcess = new NativeProcess();
        var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
        var exeFile:File = File.applicationDirectory.resolvePath('assets\\png2atf.exe');
        nativeProcessStartupInfo.executable = exeFile;
        nativeProcessStartupInfo.workingDirectory = tempDirectory;
        var args:Vector.<String> = new Vector.<String>();
        args.push('/low', 'png2atf.exe', '-c', 'e', '-i', texture.name + '.png', '-o', texture.name + '.atf');
        nativeProcessStartupInfo.arguments = args;
        nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, exitNativeProcessHandler);
        nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onInputHandler);
        nativeProcess.start(nativeProcessStartupInfo);
        nativeProcess.closeInput();
    }

    private function getResized(bitmap:Bitmap):Bitmap {
        var scaleX:Number = calculateNewDimension(bitmap.width) / bitmap.width;
        var scaleY:Number = calculateNewDimension(bitmap.height) / bitmap.height;
        var matrix:Matrix = new Matrix();
        matrix.scale(scaleX, scaleY);
        var newBitmap:BitmapData = new BitmapData(calculateNewDimension(bitmap.width), calculateNewDimension(bitmap.height), true, 0);
        newBitmap.draw(bitmap, matrix);
        return new Bitmap(newBitmap);
    }

    private function calculateNewDimension(value:Number):Number {
        for (var i:Number = 1; i <= 256; i <<= 1) {
            if (i >= value) break;
        }
        return i;
    }

    private function onLoadComplete(event:Event):void {
        texture.processingProgress = 30;
        texture.bitmap = Bitmap(LoaderInfo(event.target).content);
        texture.bitmap = getResized(texture.bitmap);
        tempDirectory = File.createTempDirectory();
        encodePNG();
    }

    private function onInputHandler(event:Event):void {
        texture.processingProgress += 10;
    }

    private function exitNativeProcessHandler(event:NativeProcessExitEvent):void {
        canExecuteATF2PNG++;
        texture.processingProgress = 100;
        trace('Convert to atf complete', texture.name);
        var file:File = new File(tempDirectory.nativePath + '\\' + texture.name + '.atf');
        var data:ByteArray = new ByteArray();
        var f:FileStream = new FileStream();
        f.open(file, FileMode.READ);
        f.readBytes(data, 0, f.bytesAvailable);
        f.close();
        texture.atfData = data;
        tempDirectory.deleteDirectoryAsync(true);
    }

}
}