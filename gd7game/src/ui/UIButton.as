package ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import resource.ui.TextureButton;
	
	public class UIButton extends Bitmap {
		public static const PRESSED:String = "press";
		public static const RELEASE:String = "rel";
		public static const UPDATE:String  = "update";
		
		public var label:TextField;
		private var _id:String;
		private var eventSprite:Sprite;
		
		private static var gfxArray:Array;
		
		public function UIButton(i:String, sx:int, sy:int, w:int = 0, h:int = 0, txt:String = null, px:int = 0, py:int = 0):void {			
			
			this.bitmapData        = new BitmapData(w, h);
			this.bitmapData.fillRect(new Rectangle(0, 0, w, h), 0x00000000);
			
			x = sx; y = sy;
			_id = i;
			
			if (txt != null) {
				label                   = new TextField();
				label.defaultTextFormat = Top.TEXT_FORMAT;
				label.defaultTextFormat.align = "center";
				label.textColor         = 0xFFFFFF;
				label.embedFonts        = true;
				label.text              = txt;
				label.width             = w;
				label.height            = h;
				
				//center the label);
				label.y                 = (h / 2) - (label.textHeight / 2);
				label.x                 = (w / 2) - (label.textWidth / 2);
				
				this.bitmapData.draw(label, new Matrix(1, 0, 0, 1, label.x, label.y));
			}
			
			eventSprite   = new Sprite();
			eventSprite.x = sx + px;
			eventSprite.y = sy + py;
			eventSprite.graphics.beginFill(0, 0);
			eventSprite.graphics.drawRect(0, 0, w, h);
			eventSprite.graphics.endFill();
			
			Top.mStage.addChild(eventSprite);
			eventSprite.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown); 
			eventSprite.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			eventSprite.addEventListener(MouseEvent.MOUSE_OUT,  onMouseOut);
			eventSprite.addEventListener(MouseEvent.MOUSE_UP,   onMouseUp);
			
			redraw();
		}
		
		private function redraw(clr:ColorTransform = null):void {
			this.bitmapData.fillRect(new Rectangle(0, 0, width, height), 0x00000000);
			
			if (gfxArray != null) {
				for (var x:int = 0; x < this.width; x += 16) {
					for (var y:int = 0; y < this.height; y += 16) {
						if (x == 0) { //Left hand
							if (y == 0) { //Top Left
								this.bitmapData.draw(gfxArray[0], new Matrix(1, 0, 0, 1, x, y), clr);
							} else if (y == this.height - 16) { //Bottom Left
								this.bitmapData.draw(gfxArray[2], new Matrix(1, 0, 0, 1, x, y), clr);
							} else { //Middle Left
								this.bitmapData.draw(gfxArray[1], new Matrix(1, 0, 0, 1, x, y), clr);
							}
						} else if (y == 0) {
							if (x == this.width - 16) { //Top Right
								this.bitmapData.draw(gfxArray[6], new Matrix(1, 0, 0, 1, x, y), clr);
							} else { //Top Middle
								this.bitmapData.draw(gfxArray[3], new Matrix(1, 0, 0, 1, x, y), clr);
							}
						} else if (x == this.width - 16) { 
							if (y == this.height - 16) { //Bottom Right
								this.bitmapData.draw(gfxArray[8], new Matrix(1, 0, 0, 1, x, y), clr);
							} else { //Middle Right
								this.bitmapData.draw(gfxArray[7], new Matrix(1, 0, 0, 1, x, y), clr);
							}
						} else if (y == this.height - 16) {
							this.bitmapData.draw(gfxArray[5], new Matrix(1, 0, 0, 1, x, y), clr);
						} else { //Center
							this.bitmapData.draw(gfxArray[4], new Matrix(1, 0, 0, 1, x, y), clr);
						}
					}
				}
			}
			
			this.bitmapData.draw(label, new Matrix(1, 0, 0, 1, label.x, label.y), clr);
		} //redraw
		
		private function onMouseDown(e:MouseEvent):void {
			redraw(new ColorTransform(0.5, 0.5, 0.5));
			this.dispatchEvent(new Event(UPDATE));
			this.dispatchEvent(new Event(PRESSED)); 
		} //onMouseDown
		
		private function onMouseOver(e:MouseEvent):void {
			redraw(new ColorTransform(1, 1, 2.5));
			this.dispatchEvent(new Event(UPDATE));	
		} //onMouseOver
		
		private function onMouseOut(e:MouseEvent):void {
			redraw(new ColorTransform(1, 1, 1));
			this.dispatchEvent(new Event(UPDATE));		
		} //onMouseOut
		
		private function onMouseUp(e:MouseEvent):void {
			redraw(new ColorTransform(1, 1, 1));
			this.dispatchEvent(new Event(UPDATE));
			this.dispatchEvent(new Event(RELEASE));	
			Top.soundHandler.playSound(3);
		} //onMouseUp
		
		public static function loadGfx():void {
			var texture:TextureButton = new TextureButton();
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
		
		public function close():void {
			eventSprite.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown); 
			eventSprite.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			eventSprite.addEventListener(MouseEvent.MOUSE_OUT,  onMouseOut);
			eventSprite.addEventListener(MouseEvent.MOUSE_UP,   onMouseUp);
			
			Top.mStage.removeChild(eventSprite);
		}
		
		public function get id():String  { return _id; }
	}
}