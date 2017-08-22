package ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import resource.ui.TextureMenu;
	
	public class UIMenu extends Bitmap{
		
		private var buttons:Array;
		private var _lastButtonID:String;
		
		private var bmpArray:Array;
		private var bmpMatrix:Array;
		
		private var txtArray:Array;
		private var txtMatrix:Array;
		
		private var _active:Boolean;
		
		private static var gfxArray:Array;
		
		public static const MENU_BUTTON_PRESSED:String = "MENU_BUTTON_PRESSED";
		public static const MENU_CLOSE:String          = "MENU_CLOSE";
		
		public function UIMenu(sx:int, sy:int, sw:int, sh:int) {
			x = sx;     y = sy;
			buttons       = new Array();
			_lastButtonID = "none";
			bmpArray      = new Array();
			bmpMatrix     = new Array();
			txtArray      = new Array();
			txtMatrix     = new Array();
			
			this.bitmapData = new BitmapData(sw, sh, true, 0x000000);
			redraw(null);
			
			Top.mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		} //UIMenu
		
		public static function loadGfx():void {
			var texture:TextureMenu = new TextureMenu();
			gfxArray = new Array();
			
			var tmp:BitmapData = new BitmapData(16, 16);
			
			for (var x:int = 0; x < texture.width; x += 16) {
				for (var y:int = 0; y < texture.height; y += 16) {
					tmp.copyPixels(texture.bitmapData, new Rectangle(x, y, 16, 16), new Point());
					gfxArray.push(tmp.clone());
				}
			}
			
			tmp.dispose();
			texture.bitmapData.dispose();
			texture = null;
		} //loadGfx
		
		public function addButton(bx:int, by:int, bw:int, bh:int, str:String = "close", txt:String = null):void {
			var btn:UIButton = new UIButton(str, bx, by, bw, bh, txt, this.x, this.y);
			
			btn.addEventListener(UIButton.UPDATE, redraw);
			btn.addEventListener(UIButton.PRESSED, buttonEvent);
			buttons.push(btn);
			
			redraw(null);
		} //addButton
		
		public function addBitmap(bmp:BitmapData, x:int, y:int, s:int = 1):void {
			if (bmp != null) {
				bmpArray.push(bmp);
				var mat:Matrix = new Matrix(s, 0, 0, s, x, y);
				bmpMatrix.push(mat);
			}
			redraw(null);
		} //addBitmap
		
		public function addText(txt:String, x:int, y:int, s:int = 1):void {
			var label:TextField = new TextField();
			
			label.defaultTextFormat = Top.TEXT_FORMAT;
			label.text              = txt;
			label.embedFonts        = true;
			label.width             = label.textWidth  + 8;
			label.height            = label.textHeight + 8;
			
			var mat:Matrix = new Matrix(s, 0, 0, s, x, y);
			
			txtArray.push(label);
			txtMatrix.push(mat);
			
			redraw(null);
		} //addText
		
		private function buttonEvent(e:Event):void {
			_lastButtonID = e.target.id;
			this.dispatchEvent(new Event("MENU_BUTTON_PRESSED"));
		} //buttonEvent
		
		public function replaceText(txt:String, i:int):void {
			if (i > 0 && i < txtArray.length) {
				txtArray[i].text = txt; 
			}
			
			redraw(null);
		} //replaceText
		
		public function redraw(e:Event):void {
			var i:int;
			
			if (gfxArray != null) {
				for (var x:int = 0; x < this.width; x += 16) {
					for (var y:int = 0; y < this.height; y += 16) {
						if (x == 0) { //Left hand
							if (y == 0) { //Top Left
								this.bitmapData.draw(gfxArray[0], new Matrix(1, 0, 0, 1, x, y));
							} else if (y == this.height - 16) { //Bottom Left
								this.bitmapData.draw(gfxArray[2], new Matrix(1, 0, 0, 1, x, y));
							} else { //Middle Left
								this.bitmapData.draw(gfxArray[1], new Matrix(1, 0, 0, 1, x, y));
							}
						} else if (y == 0) {
							if (x == this.width - 16) { //Top Right
								this.bitmapData.draw(gfxArray[6], new Matrix(1, 0, 0, 1, x, y));
							} else { //Top Middle
								this.bitmapData.draw(gfxArray[3], new Matrix(1, 0, 0, 1, x, y));
							}
						} else if (x == this.width - 16) { 
							if (y == this.height - 16) { //Bottom Right
								this.bitmapData.draw(gfxArray[8], new Matrix(1, 0, 0, 1, x, y));
							} else { //Middle Right
								this.bitmapData.draw(gfxArray[7], new Matrix(1, 0, 0, 1, x, y));
							}
						} else if (y == this.height - 16) {
							this.bitmapData.draw(gfxArray[5], new Matrix(1, 0, 0, 1, x, y));
						} else { //Center
							this.bitmapData.draw(gfxArray[4], new Matrix(1, 0, 0, 1, x, y));
						}
					}
				}
			}
			
			//Draw any stored bitmaps 
			for (var b:int = 0; b < bmpArray.length; ++b) {
				this.bitmapData.draw(bmpArray[b], bmpMatrix[b]);
			}
			
			//Draw Text
			for (var t:int = 0; t < txtArray.length; ++t) {
				this.bitmapData.draw(txtArray[t], txtMatrix[t]);
			}
			
			//Draw buttons
			for (i = 0; i < buttons.length; ++i) {
				this.bitmapData.draw(buttons[i], new Matrix(1, 0, 0, 1, buttons[i].x, buttons[i].y));
			}
			
		} //redraw
		
		public function close():void {
			var i:int;
			
			for (i = 0; i < bmpArray.length; ++i) {
				bmpArray[i].dispose();
			}
			
			for (i = 0; i < buttons.length; ++i) {
				buttons[i].removeEventListener(UIButton.UPDATE, redraw);
				buttons[i].removeEventListener(UIButton.PRESSED, buttonEvent);
				buttons[i].close();
			}
			
			Top.mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			this.bitmapData.dispose();
		} //close
		
		public function onKeyDown(e:KeyboardEvent):void {
			switch(e.keyCode) {
				//ESC
				case 27: {
					_lastButtonID = "close";
					this.dispatchEvent(new Event("MENU_BUTTON_PRESSED"));					
					break;
				}
			}
		} //onKeyDown
		
		public function get active():Boolean      { return _active; }
		public function get lastButtonID():String { return _lastButtonID; }
	}
}