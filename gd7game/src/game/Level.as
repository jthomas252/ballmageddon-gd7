package game {
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import resource.level.LevelData;
	
	/**
	 * @author Jonathan W. Thomas
	 */
	
	public class Level {
		private var tiles:Array; 
		private var builds:Array;
		private var objects:Array;
		private var _width:int;
		private var _height:int;
		private var _startX:int;
		private var _startY:int;
		private var _visible:Array;
		private var _visibleObj:Array;
		
		public function Level(rows:int = 256, cols:int = 256, writeDefault:Boolean = false) {
			//Generate a series of tiles into an array here
			tiles       = new Array();
			builds      = new Array();
			objects     = new Array();
			_visible    = new Array();
			_visibleObj = new Array();
			
			if (writeDefault || !iterateData()) {
				//Write a default level if nothing can be loaded. 
				trace("No level can be loaded, loading a blank level...");
				tiles = new Array();
				for (var x:int = 0; x < rows; ++x) {
					tiles.push(new ByteArray());
					for (var y:int = 0; y < cols; ++y) {
						tiles[x].writeByte(256 - 128);
						
					}
				}
				_startX = rows * Top.TILE_SIZE / 2;
				_startY = cols * Top.TILE_SIZE / 2;
			}
			
			_width  = Top.TILE_SIZE * tiles.length;
			_height = Top.TILE_SIZE * tiles[0].length;
			
			//Console listeners
			Top.DISPATCH.addEventListener(Top.DEV_REPLACETILE, devReplaceTile);
			Top.DISPATCH.addEventListener(Top.DEV_QUERYBUILD,  devQueryBuild);
			Top.DISPATCH.addEventListener(Top.DEV_MODBUILD,    devModBuild);
			Top.DISPATCH.addEventListener(Top.DEV_MOVEBUILD,   devMoveBuild);
			Top.DISPATCH.addEventListener(Top.DEV_REMBUILD,    devRemoveBuild);
			Top.DISPATCH.addEventListener(Top.DEV_COPYBUILD,   devCopyBuild);
			Top.DISPATCH.addEventListener(Top.DEV_ADDOBJECT,   devAddObject);
			Top.DISPATCH.addEventListener(Top.DEV_MOVEOBJECT,  devMoveObject);
			} //Level
		
		public function getTileVal(x:int, y:int):int {
			if (x < rowLength && y < colLength && x >= 0 && y >= 0) {
				tiles[x].position = y;
				return (tiles[x].readByte() + 128);
			}
			return -1;
		} //getTileVal
		
		//File reading
		public function iterateData():Boolean {
			//Load the level
			var data:LevelData = new LevelData();
			
			if (data != null) {
				if (data.length < 16) {
					trace("Level file exists, but is too small, check that proper data was exported.");
				} else {
					var x:int; var y:int; var i:int;
					var rows:int = data.readShort();
					var cols:int = data.readShort();
					_startX      = data.readShort();
					_startY      = data.readShort();
					
					//Index each byte for tiles.
					for (x = 0; x < rows; ++x) {
						tiles.push(new ByteArray());
						for (y = 0; y < cols; ++y) {
							tiles[x].writeByte(data.readByte());
						}
					}
					
					var numBuilds:int = data.readShort();
					
					for (i = 0; i < numBuilds; ++i) {
						var px:int = data.readShort(); 
						var py:int = data.readShort();
						var w:int  = data.readByte();
						var h:int  = data.readByte();
						var f:int  = data.readByte();
						
						addBuilding(w, h, f, px, py);
						
						var arr:Array = new Array(); //yarrdy harr harr
						
						for (x = 0; x < w; ++x) {
							arr.push(new ByteArray());
							for (y = 0; y < (h + f); ++y) {
								arr[x].writeByte(data.readByte());
							}
						}
						
						builds[i].changeDisplayTiles(arr);
						builds[i].redrawBitmap();
					}
					
					var numObjs:int = data.readShort();
					
					for (i = 0; i < numObjs; ++i) {
						var ox:int = data.readShort(); 
						var oy:int = data.readShort(); 
						var ot:int = data.readByte();
						objects.push(new GameObject(ox, oy, ot));
					}
					
					return true;
				}
			}
			
			return false;
		} //iterateData
		
		//Writing the file data out
		public function writeData():ByteArray {
			var byte:ByteArray = new ByteArray();
			var x:int; var y:int; var i:int;
			
			//Write the level size
			byte.writeShort(tiles.length);
			byte.writeShort(tiles[0].length);
			
			//Write the start points
			byte.writeShort(_startX);
			byte.writeShort(_startY);
			
			for (x = 0; x < tiles.length; ++x) {
				for (y = 0; y < tiles[x].length; ++y) {
					byte.writeByte(tiles[x][y]);
				}
			}
			
			//Number of buildings
			byte.writeShort(builds.length);
			
			for (i = 0; i < builds.length; ++i) {
				byte.writeShort(builds[i].x / Top.TILE_SIZE);
				byte.writeShort(builds[i].y / Top.TILE_SIZE);
				byte.writeByte(builds[i].width);
				byte.writeByte(builds[i].height);
				byte.writeByte(builds[i].floors);
				
				var display:Array = builds[i].getDisplayTiles();
				
				for (x = 0; x < display.length; ++x) {
					display[x].position = 0;
					for (y = 0; y < display[x].length; ++y) {
						byte.writeByte(display[x].readByte());
					}
				}
			}
			
			//Number of objects
			
			byte.writeShort(objects.length);
			
			for (i = 0; i < objects.length; ++i) {
				byte.writeShort(objects[i].x);
				byte.writeShort(objects[i].y);
				byte.writeByte(objects[i].type);
			}
			
			return byte;
		} //writeData
		
		//Tile commands, for editing purposes only.
		public function modTile(x:int = 0, y:int = 0, m:int = 1):int {
			if (x < tiles.length && y < tiles[0].length && x >= 0 && y >= 0) {
				var last:int = tiles[x][y];
				
				tiles[x][y] += m;
				
				return last;
			}
			return -1;
		} //modTile
		
		public function setTile(x:int = 0, y:int = 0, t:int = 0):int {
			if (x < tiles.length && y < tiles[0].length && x >= 0 && y >= 0) {
				var last:int = tiles[x][y];
				
				tiles[x][y] = t;
				
				return last;
			}
			return -1;
		} //setTile
		
		//Related to a console command in game class. 
		public function addBuilding(w:int, h:int, f:int, x:int, y:int):void {
			builds.push(new Building(w, h, f, x, y));
			
			var i:int = builds.length - 1;
			Top.console.sendMessage(new String("BUILD" + i + " :x:" + builds[i].x + "(" + builds[i].x / Top.TILE_SIZE + "):y:" + builds[i].y + "(" + builds[i].y / Top.TILE_SIZE + "):w:" + builds[i].bmpWidth + ":h:" + builds[i].bmpHeight));
		} //addBuilding
		
		public function getBuilding(i:int = 0):Building {
			if (i < builds.length) {
				return builds[i];
			}
			
			return null;
		} //getBuilding
		
		public function addObject(x:int, y:int, t:int):void {
			x *= 32; y *= 32;
			var o:GameObject = new GameObject(x, y, t);
			objects.push(o);
		} //addObject
		
		public function getObject(i:int):GameObject {
			if (i < objects.length && i >= 0) {
				return objects[i];
			}
			
			return null;
		} //getObject
		
		public function removeObject(d:int):void {
			//Clunky function, but because it's only used in editing it shouldn't matter
			var replace:Array = new Array();
			
			for (var i:int = 0; i < objects.length; ++i) {
				if (i != d) {
					replace.push(objects[i]);
				}
			}
			
			objects = replace;
		}
		
		public function updateVisible(camX:int, camY:int):void {
			var newVis:Array      = new Array();
			var newObj:Array      = new Array();
			var colRect:Rectangle = new Rectangle(camX, camY, Top.mStage.stageWidth, Top.mStage.stageHeight);
			//Paddign
			colRect.x -= 16; colRect.y -= 16;
			colRect.width += 32; colRect.height += 32;
			
			for (var b:int = 0; b < builds.length; ++b) {
				if (Top.rectCollide(colRect, builds[b].getRect())) {
					if (builds[b].updateBMP){
						if (builds[b].dead) {
							builds[b].drawAsRubble(); builds[b].updateBMP = false;
						} else {
							builds[b].redrawBitmap(); builds[b].updateBMP = false;
						}
					}
					newVis.push(b);
				} else {
					builds[b].dropBMP();
					builds[b].updateBMP = true;
				}
			}
			
			for (var o:int = 0; o < objects.length; ++o) {
				if (Top.rectCollide(colRect, objects[o].rect)) {
					newObj.push(o);
				}
			}
			
			_visible    = newVis;
			_visibleObj = newObj;
		} //updateVisible
		
		//----------------------------------------------------
		//  Console Events
		//----------------------------------------------------	
		public function devReplaceTile(e:Event):void {
			//get params
			Top.console.sendMessage("NYI :: REPLACETILE");
			
			//run for loop
		} //devReplaceTile
		
		public function devQueryBuild(e:Event):void {
			var i:int = Top.console.params[1]; 
			if (i >= builds.length) {
				Top.console.sendMessage("Error: Not in range of building array");
			} else {
				Top.console.sendMessage(new String("BUILD" + i + " :x:" + builds[i].x + "(" + builds[i].x / Top.TILE_SIZE + "):y:" + builds[i].y + "(" + builds[i].y / Top.TILE_SIZE + "):w:" + builds[i].bmpWidth + ":h:" + builds[i].bmpHeight));
			}
		} //devQueryBuild
		
		public function devModBuild(e:Event):void {
			var i:int = Top.console.params[1];
			if (i >= builds.length) {
				Top.console.sendMessage("Error: Not in range of building array");
			} else {
				builds[i].mod(Top.console.params[2], Top.console.params[3], Top.console.params[4]);
				Top.console.sendMessage(new String("BUILD" + i + " :x:" + builds[i].x + "(" + builds[i].x / Top.TILE_SIZE + "):y:" + builds[i].y + "(" + builds[i].y / Top.TILE_SIZE + "):w:" + builds[i].bmpWidth + ":h:" + builds[i].bmpHeight));
			}
		} //devModBuild
		
		public function devMoveBuild(e:Event):void {
			var i:int = Top.console.params[1];
			if (i >= builds.length) {
				Top.console.sendMessage("Error: Not in range of building array");
			} else {
				builds[i].move(Top.console.params[2], Top.console.params[3]);
				Top.console.sendMessage(new String("BUILD" + i + " :x:" + builds[i].x + "(" + builds[i].x / Top.TILE_SIZE + "):y:" + builds[i].y + "(" + builds[i].y / Top.TILE_SIZE + "):w:" + builds[i].bmpWidth + ":h:" + builds[i].bmpHeight));
			}
		} //devMoveBuild
		
		public function devRemoveBuild(e:Event):void {
			trace(builds[0].getCollRect());
			Top.console.sendMessage("NYI");
		} //devRemoveBuild
		
		public function devCopyBuild(e:Event):void {
			var i:int = Top.console.params[1];
			if (i >= builds.length) {
				Top.console.sendMessage("Error: Not in range of building array");	
			} else {
				var b:Building = new Building(builds[i].width, builds[i].height, builds[i].floors, Top.console.params[2], Top.console.params[3]);
				b.changeDisplayTiles(builds[i].getDisplayTiles());
				b.redrawBitmap();
				i = builds.push(b) - 1;
				Top.console.sendMessage(new String("BUILD" + i + " :x:" + builds[i].x + "(" + builds[i].x / Top.TILE_SIZE + "):y:" + builds[i].y + "(" + builds[i].y / Top.TILE_SIZE + "):w:" + builds[i].bmpWidth + ":h:" + builds[i].bmpHeight));
			}
		} //devCopyBuild
		
		public function devAddObject(e:Event):void {
			addObject(Top.console.params[1], Top.console.params[2], Top.console.params[3]);
		} //devAddObject
		
		public function devMoveObject(e:Event):void {
			var i:int = Top.console.params[1];
			
			if (i > objects.length) {
				Top.console.sendMessage("Error: Object requested does not exist");
			} else {
				
			}
		} //devMoveObject
		
		public function get visible():Array { return _visible;        }
		public function get visObj():Array  { return _visibleObj;     }
		public function get rowLength():int { return tiles.length;    }
		public function get colLength():int { return tiles[0].length; }
		public function get width():int     { return _width;          }
		public function get height():int    { return _height;         }
		public function get startX():int    { return _startX;         }
		public function get startY():int    { return _startY;         }
		public function get numBuilds():int { return builds.length;   }
		public function get numObjs():int   { return objects.length;  } 
	}
}