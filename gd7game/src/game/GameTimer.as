package game {
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	public class GameTimer extends Timer {
		public static const TOTAL_TIME:int = 180;
		
		private var _bmp:BitmapData; 
		private var info:TextField;
		private var time:TextField;
		
		public function GameTimer() {
			_bmp = new BitmapData(200, 200, true, 0xFFFFFFFF);
			this.addEventListener(TimerEvent.TIMER, redraw);
			
			info = new TextField();
			info.defaultTextFormat = Top.TEXT_FORMAT;
			info.embedFonts = true;
			info.text = "TIME";
			info.filters = [new DropShadowFilter(2,45,0,0.5,0)];
			
			time = new TextField();
			time.defaultTextFormat = Top.TEXT_FORMAT;
			time.embedFonts = true;
			time.text = "3:00";
			time.filters = [new DropShadowFilter(4, 45, 0, 0.5, 0)];
			
			super(1000, TOTAL_TIME);
			
			redraw(null);
		}
		
		private function redraw(e:Event):void {
			_bmp.dispose();
			_bmp = new BitmapData(200, 200, true, 0x00);
			
			var i:int = TOTAL_TIME - this.currentCount;
			var m:int = Math.floor(i / 60);
			var s:int = Math.floor(i % 60);
			
			if(s >= 10){
				time.text = String(m + ":" + s);
			} else {
				time.text = String(m + ":0" + s);
			}
			
			this._bmp.draw(info, new Matrix(1, 0, 0, 1, 100 - (info.textWidth / 2), 0));
			this._bmp.draw(time, new Matrix(3, 0, 0, 3, 24, 16));
		}
		
		public function get bmp():BitmapData { return _bmp; }
		
	}
}