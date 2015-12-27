package com.andrewgura.vo {

import com.andrewgura.utils.PNGDecoder;

import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;

import mx.graphics.codec.PNGEncoder;

[Bindable]
	public class TextureVO {
		
		public var width:Number;
		public var height:Number;
		public var atfData:ByteArray;
		private var _bitmap:Bitmap;
		public var name:String;
		
		public var processingProgress:Number = 0;
		
		public function TextureVO(name:String) {
			this.name = name;
		}
		
		public function get bitmap():Bitmap {
			return _bitmap;
		}

		public function set bitmap(value:Bitmap):void {
			_bitmap = value;
			this.width = value.width;
			this.height = value.height;
		}

		public function serialize():ByteArray {
			var output:ByteArray = new ByteArray();
			output.writeObject(this);
			output.writeObject((new PNGEncoder()).encode(_bitmap.bitmapData));
			return output;
		}

	public function deserialize(data:ByteArray):void {
		var o:* = data.readObject();
		for (var field:String in o) {
			if (field != "bitmap") {
				this[field] = o[field];
			}
		}
		bitmap = new Bitmap((new PNGDecoder()).decode(data.readObject()));
	}

	}
}