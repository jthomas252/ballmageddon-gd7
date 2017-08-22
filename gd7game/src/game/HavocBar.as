package game {
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.filters.DropShadowFilter;
	
	/**
	 * ...
	 * @author Jonathan W. Thomas
	 */
	public class HavocBar {
		private var _bmp:BitmapData;
		private var txt:TextField;
		
		public function HavocBar() {
			_bmp = new BitmapData(400, 400, true, 0x00);
			
			txt = new TextField();
			txt.defaultTextFormat = Top.TEXT_FORMAT;
			txt.embedFonts = true;
			txt.filters    = [new DropShadowFilter(4, 45, 0, 0.5, 0)];
			txt.text       = "HAVOC                     LVL. 1";	
			txt.width      = txt.textWidth + 80;
		}
		
		public function update(e:Event = null):void {
			_bmp.dispose();
			_bmp = new BitmapData(400, 400, true, 0xFF);
			
			var n:Number = Game.stats.havoc / Game.pBall.hLevelReq;
			
			txt.text = "HAVOC                     LVL. " + (Game.pBall.hLevel + 1);
			_bmp.draw(txt);
			_bmp.fillRect(new Rectangle(0, 18, 400, 32),     0xFF353535);
			_bmp.fillRect(new Rectangle(0, 16, 400 * n, 32), 0xFFD12222);
		} //update
		
		public function get bmp():BitmapData { return _bmp; }
	}
}