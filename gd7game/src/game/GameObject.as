package game {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	public class GameObject {
		public  var x:int;
		public  var y:int;
		private var _type:int;
		private var _width:int;
		private var _height:int;
		private var _live:Boolean;
		
		public function GameObject(sx:int, sy:int, t:int) {
			x = sx; y = sy;
			_width  = 32;
			_height = 32;
			_type   = t;
			_live   = true;
			
		} //GameObject
		
		public function get rect():Rectangle {
			var ret:Rectangle = new Rectangle(x, y, _width, _height);
			return ret;
		}
		
		public function kill():void {
			Game.stats.addScore(50);
			Game.stats.addHavoc(10);
			Game.stats.objDestroyed();
			_live = false;
		}
		
		public function get width():int      { return _width; }
		public function get height():int     { return _height; }
		public function get type():int       { return _type; }
		public function get live():Boolean   { return _live; }
	}

}