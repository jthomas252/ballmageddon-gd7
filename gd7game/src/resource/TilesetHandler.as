package resource {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import resource.tileset.environment.TilesetWorld;
	import resource.tileset.object.TilesetBuilding0;
	import resource.tileset.object.TilesetBuilding1;
	import resource.tileset.object.TilesetBuilding2;
	import resource.tileset.object.TilesetObject0;
	import resource.tileset.object.TilesetObject1;
	import resource.tileset.object.TilesetRubble;

	public class TilesetHandler {
		private var objs:Array;   //Object tileset
		private var builds:Array; //Building tileset(s)
		private var tiles:Array;  //Level tileset
		private var rubble:Array;
		
		private static const TILES_ANIMATE_POINT:int = 228; //Replace this with something in TileType?
		public  static const TILES_HAZARD_POINT:int  = 253; 
		
		public function TilesetHandler() {
			tiles  = new Array();
			builds = new Array(new Array(), new Array(), new Array()); //Pushed arrays are for the damage info
			objs   = new Array(new Array(), new Array());
			rubble = new Array();
			
			var x:int = 0; var y:int = 0;
			var tmp:BitmapData;
			
			//Tilesets
			var tWorld:TilesetWorld      = new TilesetWorld();
			var tBuild0:TilesetBuilding0 = new TilesetBuilding0();
			var tBuild1:TilesetBuilding1 = new TilesetBuilding1();
			var tBuild2:TilesetBuilding2 = new TilesetBuilding2();
			var tRubble:TilesetRubble    = new TilesetRubble();
			var tObj0:TilesetObject0     = new TilesetObject0();
			var tObj1:TilesetObject1     = new TilesetObject1();
			
			//Cut the tilesets into smaller pieces...
			for (x = 0; x < tWorld.width; x += Top.TILE_SIZE) {
				for (y = 0; y < tWorld.height; y += Top.TILE_SIZE) {
					tmp = new BitmapData(Top.TILE_SIZE, Top.TILE_SIZE);
					tmp.copyPixels(tWorld.bitmapData, new Rectangle(x, y, Top.TILE_SIZE, Top.TILE_SIZE), new Point());
					tiles.push(tmp.clone());
				}
			}
			
			//Building data -- move into a seperate function?
			for (x = 0; x < tBuild0.width; x += Top.BUILD_SIZE) {
				for (y = 0; y < tBuild0.height; y += Top.BUILD_SIZE) {
					tmp = new BitmapData(Top.BUILD_SIZE, Top.BUILD_SIZE);
					tmp.copyPixels(tBuild0.bitmapData, new Rectangle(x, y, Top.BUILD_SIZE, Top.BUILD_SIZE), new Point());
					builds[0].push(tmp.clone());
					tmp.copyPixels(tBuild1.bitmapData, new Rectangle(x, y, Top.BUILD_SIZE, Top.BUILD_SIZE), new Point());
					builds[1].push(tmp.clone());
					tmp.copyPixels(tBuild2.bitmapData, new Rectangle(x, y, Top.BUILD_SIZE, Top.BUILD_SIZE), new Point());
					builds[2].push(tmp.clone());
				}
			}
			
			//Rubble
			for (x = 0; x < tRubble.width; x += Top.BUILD_SIZE) {
				for (y = 0; y < tRubble.height; y += Top.BUILD_SIZE) {
					tmp = new BitmapData(Top.BUILD_SIZE, Top.BUILD_SIZE);
					tmp.copyPixels(tRubble.bitmapData, new Rectangle(x, y, Top.BUILD_SIZE, Top.BUILD_SIZE), new Point());
					rubble.push(tmp.clone());
				}
			}
			
			//Objects
			for (x = 0; x < tObj0.width; x += 32) {
				for (y = 0; y < tObj0.height; y += 32) {
					tmp = new BitmapData(32, 32);
					tmp.copyPixels(tObj0.bitmapData, new Rectangle(x, y, 32, 32), new Point());
					objs[0].push(tmp.clone());
					tmp.copyPixels(tObj1.bitmapData, new Rectangle(x, y, 32, 32), new Point());
					objs[1].push(tmp.clone());
				}
			}
			
			//Drop the tileset data.
			tmp.dispose(); tmp = null;
			
			tWorld.bitmapData.dispose(); tWorld = null;
			tBuild0.bitmapData.dispose();
			tBuild1.bitmapData.dispose();
			tBuild2.bitmapData.dispose();
			tRubble.bitmapData.dispose();
			tObj0.bitmapData.dispose();
			tObj1.bitmapData.dispose();
			
		} //TilesetHandler
		
		public function getObject(i:int, live:Boolean):BitmapData {
			if (i >= 0 && i < objs[0].length) {
				if (live) {
					return objs[1][i];
				} else {
					return objs[0][i];
				}
			} 
			
			return new BitmapData(32, 32);
		}
		
		public function getTile(i:int):BitmapData {
			if (i < tiles.length && i >= 0) { return tiles[i]; }
			else { return new BitmapData(Top.TILE_SIZE, Top.TILE_SIZE, false, 0x00); }
		} //getTile
		
		public function animateTiles():void {
			for (var i:int = TILES_ANIMATE_POINT; i < tiles.length; i += 2) {
				var hold:BitmapData = new BitmapData(Top.TILE_SIZE, Top.TILE_SIZE);
				
				hold         = tiles[i].clone();
				tiles[i]     = tiles[i + 1].clone();
				tiles[i + 1] = hold.clone();
				hold.dispose();
				hold = null;
			}
		} //animateTiles
		
		public function getRubbleTile(i:int):BitmapData {
			if (rubble.length && i >= 0) { 
				return rubble[i].clone();
			} 
			return new BitmapData(16,16);
		} //getRubbleTile
		
		public function getBuildTile(dmg:int, i:int):BitmapData {
			i += 128;
			
			dmg < 0 ? dmg = 0 : null;
			if (dmg < 3 && i < builds[0].length ) {
				return builds[dmg][i];
			} 
			
			return new BitmapData(Top.BUILD_SIZE, Top.BUILD_SIZE);
		} //getBuildTile
		
		public function get numTiles():int { return tiles.length; }
	}
}