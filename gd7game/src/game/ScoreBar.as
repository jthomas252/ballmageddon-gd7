package game 
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Jonathan W. Thomas
	 */
	public class ScoreBar {
		private var _bmp:BitmapData;
		private var txt:TextField;
		
		
		public function ScoreBar() {
			_bmp = new BitmapData(400, 400, true, 0x00);
			
			txt = new TextField();
			txt.defaultTextFormat = Top.TEXT_FORMAT;
			txt.embedFonts = true;
			txt.filters = [new DropShadowFilter(4, 45, 0, 0.5, 0)];
			txt.text = "SCORE\n000000";
		}
		
		public function update(e:Event = null):void {
			_bmp.dispose();
			_bmp = new BitmapData(400, 400, true, 0x00);
			
			var i:int = Game.stats.score;
			
			var str:String = String(i);
			
			for (var n:int = str.length; n < 7; ++n) {
				str = "0" + str;
			}
			
			txt.text = "SCORE\n" + str;
			
			this._bmp.draw(txt, new Matrix(2, 0, 0, 2));
		} //update
		
		public function get bmp():BitmapData { return _bmp; }
	}

}