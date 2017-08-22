package game {
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	public class Building {
		private var displayTiles:Array; //Tiles 
		
		private var _bmpData:BitmapData;    //The actual bitmap data
		private var _bmpShadow:BitmapData;  //The rendering shadow
		
		private var _HP:int;
		private var _width:int;
		private var _height:int;
		private var baseHP:int;
		private var _floors:int; 
		private var _dead:Boolean;
		public var update:Boolean;
		
		public var x:int;
		public var y:int;
		
		public var sx:int;
		public var sy:int;
		
		public var updateBMP:Boolean;
		
		private var collapseTimer:Timer;
		
		public function Building(w:int = 8, h:int = 8, f:int = 2, mx:int = 0, my:int = 0) {
			w = Math.abs(w);
			h = Math.abs(h);
			f = Math.abs(f);
			
			updateBMP     = false;
			baseHP     = (w * h * (f / 2)) / 4; 
			_floors     = f;
			_HP        = baseHP;
			_width     = w;
			_height    = h;
			_dead     = false;
			update    = true;
			collapseTimer = new Timer(150, floors);
			
			_bmpData   = new BitmapData(w * Top.BUILD_SIZE, (h + f) * Top.BUILD_SIZE); 
			_bmpShadow = new BitmapData(w * Top.BUILD_SIZE, (h + f) * Top.BUILD_SIZE, true, 0x55000000);
			
			//Visual data, bytes.
			displayTiles = new Array();
			for (var a:int = 0; a < w; ++a) {
				displayTiles.push(new ByteArray());
				for (var b:int = 0; b < (h + f); ++b) {
					if (b < h) { displayTiles[a].writeByte(8  - 128);
					} else {     displayTiles[a].writeByte(17 - 128);
					}
				}
			}
			
			x = mx * Top.TILE_SIZE; 
			y = my * Top.TILE_SIZE;
			
			sx = x + 16;
			sy = y - 16;
			redrawBitmap();
		} //Building
		
		public function redrawBitmap():void {
			
			if (!_dead) {
				_bmpData = new BitmapData(width * Top.BUILD_SIZE, (height + floors) * Top.BUILD_SIZE);
				_bmpShadow = new BitmapData(width * Top.BUILD_SIZE, (height + floors) * Top.BUILD_SIZE, true, 0x55000000);
				
				collapseTimer.running ? _bmpShadow = new BitmapData(width * Top.BUILD_SIZE, (height + floors) * Top.BUILD_SIZE, true, 0x55000000) : null;
				var dmg:int = Math.round((_HP / baseHP) * 2);
				for (var a:int = 0; a < displayTiles.length; ++a) {
					for (var b:int = 0; b < displayTiles[a].length; ++b ) {
						if(b * Top.BUILD_SIZE < _bmpData.height){
						displayTiles[a].position = b;
						_bmpData.copyPixels(Game.tH.getBuildTile(dmg, displayTiles[a].readByte()),
						new Rectangle(0, 0, Top.BUILD_SIZE, Top.BUILD_SIZE),
						new Point(a * Top.BUILD_SIZE, b * Top.BUILD_SIZE));
						}
					}
				}
			}
		} //redrawBitmap
		
		public function dropBMP():void {
			_bmpData.dispose();
			_bmpShadow.dispose();
		} //dropBMP
		
		public function drawAsRubble():void {
			//y += _floors * Top.BUILD_SIZE;
			
			_bmpData.dispose();
			_bmpData = new BitmapData(_width * Top.BUILD_SIZE, _height * Top.BUILD_SIZE);
			
			for (var a:int = 0; a < _bmpData.width; a += Top.BUILD_SIZE) {
				for (var b:int = 0; b < _bmpData.height; b += Top.BUILD_SIZE) {
					_bmpData.copyPixels(Game.tH.getRubbleTile(Math.random() * 6), new Rectangle(0, 0, 16, 16), new Point(a, b));
				}
			}
		} //drawAsRubble
		
		public function getRect():Rectangle {
			var ret:Rectangle = new Rectangle(x, y, displayTiles.length * Top.BUILD_SIZE, displayTiles[0].length * Top.BUILD_SIZE);
			
			//ret.width  += 16;
			//ret.height += 16;
			
			return ret;
		} //getRect
		
		public function getCollRect():Rectangle {
			var ret:Rectangle = new Rectangle(x, y, colWidth, colHeight);
			ret.y += _floors * Top.BUILD_SIZE;
			
			return ret;
		} //getCollRect
		
		public function getTile(gx:int, gy:int):int {
			if (gx < displayTiles.length && gy < displayTiles[0].length && gx >= 0 && gy >= 0) {
				return displayTiles[gx][gy];
			}
			return 0;
		} //getTile
		
		public function modTile(sx:int, sy:int, m:int):void {
			if (sx < displayTiles.length && sy < displayTiles[0].length && sx >= 0 && sy >= 0) {
				displayTiles[sx][sy] = m;
			}
		} //modTile
		
		public function move(mx:int = 0, my:int = 0):void {
			x = mx * Top.TILE_SIZE;
			y = my * Top.TILE_SIZE;
		} //move
		
		public function mod(w:int, h:int, f:int):void {
			_width  = w;
			_height = h;
			_floors = f;
			
			displayTiles = new Array();
			for (var a:int = 0; a < w; ++a) {
				displayTiles.push(new ByteArray());
				for (var b:int = 0; b < (h + f); ++b) {
					if (b < h) { displayTiles[a].writeByte(8  - 128);
					} else {     displayTiles[a].writeByte(17 - 128);
					}
				}
			}
			
			redrawBitmap();
		} //mod
		
		public function applyDamage(d:int):void {
			_HP -= d;
			
			if (_HP < 0 && !_dead && !collapseTimer.running) {
				Game.stats.buildDestroyed();
				Game.stats.addScore(baseHP * 32);
				Game.stats.addHavoc(baseHP * 4);
				_HP = 0;
				
				collapseTimer.start();
				collapseTimer.addEventListener(TimerEvent.TIMER, collapse);
				collapseTimer.addEventListener(TimerEvent.TIMER_COMPLETE, collapseEnd);
			}
		} //applyDamage
		
		public function changeDisplayTiles(input:Array):void {
			displayTiles = new Array();
			
			for (var i:int = 0; i < input.length; ++i) { 
				displayTiles.push(input[i]);
			}
		} //changeDisplayTiles
		
		public function getDisplayTiles():Array {
			return displayTiles;
		} //getDisplayTiles
		
		public function collapse(e:TimerEvent):void {
			--_floors; y += 16; sy += 16;
			redrawBitmap(); 
			//Play sound effect
			Top.soundHandler.playSound(0, 0.5);
		} //collapse
		
		public function collapseEnd(e:TimerEvent):void {
			_dead = true;
			//Remove listeners
			collapseTimer.removeEventListener(TimerEvent.TIMER, collapse);
			collapseTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, collapseEnd);
			
			//_floors = collapseTimer.currentCount;
			//y      -= collapseTimer.currentCount * 16;
			drawAsRubble(); 
			//Play a different effect? 
		} //collapseEnd
		
		public function get bmpWidth():int     { return displayTiles.length * Top.BUILD_SIZE; }
		public function get bmpHeight():int    { return displayTiles[0].length * Top.BUILD_SIZE; }
		public function get colWidth():int     { return _width * Top.BUILD_SIZE; }
		public function get colHeight():int    { return _height * Top.BUILD_SIZE; }
		public function get bmp():BitmapData    { return _bmpData.clone(); }
		public function get shadow():BitmapData { return _bmpShadow.clone(); }
		public function get dead():Boolean      { return _dead; }
		public function get width():int         { return _width; }
		public function get height():int        { return _height; }
		public function get floors():int        { return _floors; }
	}

}