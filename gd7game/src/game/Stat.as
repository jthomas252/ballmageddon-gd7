package game {
	import flash.events.Event;

	public class Stat {
		
		private var _score:int;
		private var _havoc:int;
		
		private var _buildDestroyed:int;
		private var _objDestroyed:int;
		
		public function Stat() {
			_score = 0;
			_havoc = 0;
			
			_buildDestroyed = 0;
			_objDestroyed = 0;
		}
		
		public function addScore(s:int):void {
			_score += s;
			
			Top.DISPATCH.dispatchEvent(new Event(Top.STAT_SCOREUPDATE));
		}
		
		public function addHavoc(h:int):void {
			_havoc += h;
			
			Top.DISPATCH.dispatchEvent(new Event(Top.STAT_HAVOCUPDATE));
		}
		
		public function buildDestroyed():void {
			++_buildDestroyed;
		} 
		
		public function objDestroyed():void {
			++_objDestroyed;
		}
		
		public function get score():int { return _score; }
		public function get havoc():int { return _havoc; }
		
		public function get buildsDestroyed():int { return _buildDestroyed; }
		public function get objsDestroyed():int   { return _objDestroyed;  }
	}
}