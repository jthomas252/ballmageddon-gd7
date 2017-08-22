package game {
	import flash.events.Event;
	import flash.display.BitmapData;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	
	public class BoostBar {
		private var _bmp:BitmapData;
		private var txt:TextField;
		
		public function BoostBar() {
			_bmp = new BitmapData(400, 400, true, 0x00);
			
			txt = new TextField();
			txt.defaultTextFormat = Top.TEXT_FORMAT;
			txt.embedFonts = true;
			txt.filters    = [new DropShadowFilter(4, 45, 0, 0.5, 0)];
			txt.text       = "BOOST";	
			txt.width      = txt.textWidth + 80;
		}
		
		public function update(e:Event = null):void {
			_bmp.dispose();
			_bmp = new BitmapData(400, 400, true, 0xFF);
			
			var n:Number = Game.pBall.boostBar / 100;
			
			_bmp.draw(txt);
			_bmp.fillRect(new Rectangle(0, 18, 400, 32),     0xFF353535);
			_bmp.fillRect(new Rectangle(0, 16, 400 * n, 32), 0xFF4D4DDD);
		} //update
		
		public function get bmp():BitmapData { return _bmp; }
	}

}