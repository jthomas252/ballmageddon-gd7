package game {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import resource.tileset.object.TextureBall;
	import flash.system.System;
	import resource.TilesetHandler;
	import flash.net.FileReference;
	import flash.utils.getTimer;
	import ui.UIMenu;
	
	/**
	 * @author Jonathan W. Thomas
	 * 
	 * Main game handler and rendering class. All game logic and rendering goes through this.
	 * Contains instances of the PlayerBall and Level classes. 
	 * 
	 * Last Revision: July 8th, 2012
	 */
	
	public class Game extends Bitmap {
		//----------------------------------------------------
		//  Variables and Constuctor
		//----------------------------------------------------
		private const CAMERA_SPEED:Number = 0.005;
		private const ANIMATE_DELAY:int   = 400;
		
		public static var stats:Stat; //Gameplay stats, score and havoc info
		public static var lvl:Level;        //Instance of the level. 
		public static var pBall:PlayerBall; //Instance of the players character. 
		
		public  static var tH:TilesetHandler //Handles available tiles
		
		//Assorted variables
		private var paused:Boolean;
		private var tLast:int;       //Time passed since the last frame was drawn in the gameplay loop.
		
		//Development purposes
		private var editMode:Boolean  //If editing the level. Probably need some kind of control if game logic is active. 
		
		//Camera stuff
		private var camLock:Boolean;  //For making editing easier. 
		private var camMove:Boolean;  //If the mouse is down (camera move enabled) 
		private var lastX:Number;     //Last mouse X
		private var lastY:Number;     //Last mouse Y
		private var lastCamX:int;     //Last Camera X
		private var lastCamY:int;     //Last Camera Y
		private var camX:Number;      //Current camera position.
		private var camY:Number;      //Y-Axis
		private var maxDrawableX:int; //Maximum tiles that can be drawn according to resolution.
		private var maxDrawableY:int; //Y-Axis 
		private var minCamX:int;      //Minimum camera X
		private var minCamY:int;      //Minimum camera Y
		private var maxCamX:int;      //Maximum camera X
		private var maxCamY:int;      //Maximum camera Y
		private var _endState:String; 
		private var initials:String;
		private var repScore:int;
		
		//Stuff to keep keys held down.
		private var moveUpHeld:Boolean;
		private var moveDownHeld:Boolean;
		private var moveLeftHeld:Boolean;
		private var moveRightHeld:Boolean;
		private var brakeHeld:Boolean;
		private var boostHeld:Boolean;
		
		//Testing / Debug
		private var pTex:TextureBall;
		private var debugDisplay:TextField; //This gets moved to UI stuff later on, shouldn't be showing up by default. 
		private var memText:String;
		private var controlText:TextField;
		private var frames:int;
		private var fpsString:String;
		private var fpsTimer:Timer;
		private var animate:int; 
		
		//INTERFACE
		private var gTimer:GameTimer;
		private var scoreUI:ScoreBar;
		private var havocUI:HavocBar;
		private var boostUI:BoostBar;
		private var endScreen:UIMenu;
		
		//Editor Vars
		private var tilePicker:int;
		private var buildPicker:int;
		private var file:FileReference;
		private var drawDown:Boolean;
		private var animateDraw:Boolean;
		
		//Drawing Toggles, for DevConsole
		private var drawPlayer:Boolean;
		private var drawBuilding:Boolean;
		private var drawObject:Boolean;
		
		//Building editing tools
		private var buildSelX:int;
		private var buildSelY:int;
		private var buildSelT:int;
		private var collEnabled:Boolean;
		private var objSelT:int;
		
		//EVENTS
		public static const GAME_OVER:String = "GAME_OVER";
		public static const GAME_MENU:String = "GAME_MENU";
		
		//----------------------------------------------------
		//  Game Class
		//----------------------------------------------------		
		public function Game()  {
			stats = new Stat();
			
			//Variable initalization
			setMaxDrawable(null);
			paused   = false;   tLast       = 0;
			editMode = false;   camMove     = false;
			lastX    = 0;       lastY       = 0;
			minCamX  = 0;       minCamY     = 0;
			frames   = 0;       tilePicker  = -128;
			animate  = 0;       drawDown    = false;
			memText  = "\n";    animateDraw = false;
			lastCamX = 0;       lastCamY    = 0;
			buildPicker = 0;
			buildSelX = 0;
			buildSelY = 0;
			buildSelT = -127;
			objSelT   = 0;
			_endState = "main";
			initials  = "AAA";
			
			drawPlayer   = true;
			drawBuilding = true;
			drawObject   = true;
			collEnabled  = true;
			paused       = false;
			
			file = new FileReference(); 
			
			/*
			fpsTimer = new Timer(1000);
			fpsTimer.start();
			fpsTimer.addEventListener(TimerEvent.TIMER, fps);
			*/
			
			tH       = new TilesetHandler();
			lvl      = new Level();
			
			//For the game timer 
			gTimer   = new GameTimer();
			gTimer.addEventListener(TimerEvent.TIMER_COMPLETE, gTimerOver);
			gTimer.start();
			
			maxCamX  = (lvl.rowLength * Top.TILE_SIZE) - Top.mStage.stageWidth;       
			maxCamY  = (lvl.colLength * Top.TILE_SIZE) - Top.mStage.stageHeight;
			
			moveUpHeld    = false; moveDownHeld  = false;
			moveLeftHeld  = false; moveRightHeld = false;
			brakeHeld     = false; boostHeld     = false;	
			
			//Cut up the series of ball textures
			var tmp:Array = new Array();
			pTex          = new TextureBall();
			for (var y:int = 0; y < pTex.height; y += 128) {
				var btmp:BitmapData = new BitmapData(128, 128);
				btmp.copyPixels(pTex.bitmapData, new Rectangle(0, y, 128, 128), new Point());
				tmp.push(btmp);
			}
			
			//Initalize and add in the textures
			pBall = new PlayerBall(tmp[0]);
			for (var x:int = 1; x < tmp.length; ++x) {
				pBall.addTexture(tmp[x]);
				tmp[x] = null;
			}
			tmp = null;
			
			//Center the ball in the middle of the map
			pBall.x = lvl.startX; pBall.y = lvl.startY; 
			pTex  = null;
			
			//Set the camera starting position
			camX     = (pBall.x + (pBall.width  / 2) - (Top.mStage.stageWidth  / 2));       
			camY     = (pBall.y + (pBall.height / 2) - (Top.mStage.stageHeight / 2));
			
			this.bitmapData = new BitmapData(Top.mStage.stageWidth, Top.mStage.stageHeight, true, 0xFF332233);
			
			debugDisplay                   = new TextField();
			debugDisplay.defaultTextFormat = Top.TEXT_FORMAT;
			
			//For gameplay loop / framerate tracking. 
			this.addEventListener(Event.ENTER_FRAME, onFrame);
			
			//Input handlers
			Top.mStage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			Top.mStage.addEventListener(KeyboardEvent.KEY_UP,   keyUp);
			Top.mStage.addEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
			Top.mStage.addEventListener(MouseEvent.MOUSE_UP,    mouseUp);
			Top.mStage.addEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
			
			//Ingame interface
			scoreUI = new ScoreBar();
			Top.DISPATCH.addEventListener(Top.STAT_SCOREUPDATE, scoreUI.update);
			scoreUI.update();
			
			//Havoc
			havocUI = new HavocBar();
			Top.DISPATCH.addEventListener(Top.STAT_HAVOCUPDATE, pBall.updateHavoc);
			Top.DISPATCH.addEventListener(Top.STAT_HAVOCUPDATE, havocUI.update);
			havocUI.update();
			
			//Boost
			boostUI = new BoostBar();
			boostUI.update();
			
			/* Uncomment for development
			//Debug Text -- REMOVE FROM FINAL 
			Top.mStage.addChild(debugDisplay); 
			debugText();
			debugDisplay.embedFonts = true;
			debugDisplay.width  = 512;
			debugDisplay.height = 256;
			debugDisplay.x      = 4;
			debugDisplay.y      = Top.mStage.stageHeight - debugDisplay.textHeight - 4;
			*/
			
			//Dev Console Listeners
			Top.DISPATCH.addEventListener(Top.DEV_ADDBUILD, devAddBuilding);
			
			lvl.updateVisible(camX, camY);  render(true); 
		} //Game
		
		private function setMaxDrawable(e:Event):void {
			maxDrawableX = Math.ceil(Top.mStage.stageWidth  / (Top.TILE_SIZE)) + 1;
			maxDrawableY = Math.ceil(Top.mStage.stageHeight / (Top.TILE_SIZE)) + 1;
		} //setMaxDrawable 
		
		private function onFrame(e:Event):void {
			!paused ? gameTick(getTimer() - tLast) : null;
			tLast = getTimer();
			++frames; 
			
			//debugText();
		} //onFrame
		
		private function fps(e:Event):void {
			fpsString = String(frames);
			frames    = 0;
			memText   = (Math.round(System.totalMemory / 10485.76) / 100) + "(MB)\n";
		} //fps
		
		//----------------------------------------------------
		//  Game Loop
		//----------------------------------------------------
		private function gameTick(t:int):void {
			//Animate if the time is up
			animate += t;
			if (animate >= ANIMATE_DELAY) {
				tH.animateTiles();
				animate = 0 + (animate - ANIMATE_DELAY);
				//animateDraw = true;
			} else {
				animateDraw = false;
			}
			
			//Get the tile that the ball is standing on
			if (!pBall.sinking){
				if (lvl.getTileVal((pBall.x + 32) / Top.TILE_SIZE, (pBall.y + 32) / Top.TILE_SIZE) >= TilesetHandler.TILES_HAZARD_POINT) {
					//Start water hazard.
					pBall.startSink();
				}
			} else {
				if (lvl.getTileVal((pBall.x + 32) / Top.TILE_SIZE, (pBall.y + 32) / Top.TILE_SIZE) <= TilesetHandler.TILES_HAZARD_POINT) {
					//End water hazard.
					pBall.endSink();
				} 
			}
			
			//Send movement keys to thee ball
			pBall.applyMomentum(moveLeftHeld, moveRightHeld,moveUpHeld,moveDownHeld, brakeHeld, boostHeld, t);
			
			//If not paused and theres reason for it run movement.
			pBall.move(t);
			
			//Remove from live?
			collEnabled ? collCheck() : null;
			
			//If not editing and if the ball has momentum center the camera.
			if (!editMode && (pBall.momentumX > 0 || pBall.momentumX < 0 || pBall.momentumY > 0 || pBall.momentumY < 0)) {
				centerCam(t);
			} else {
				lastCamX = camX; lastCamY = camY;
			}
			
			boostUI.update();
			render(animateDraw); 
		} //gameTick
		
		private function collCheck():void {
			//Check collision. (Move this into it's own function?)
			//-- Level Bounds -- Maybe remove this from final? 
			//X
			if (pBall.x < 0) {
				pBall.x = 0;
				pBall.collideX();
			} else {
				if ((pBall.x + pBall.width) > lvl.width) {
					pBall.x = lvl.width - pBall.width;
					pBall.collideX();
				}
			}
			
			//Y
			if (pBall.y < 0) {
				pBall.y = 0;
				pBall.collideY();
			} else {
				if ((pBall.y + pBall.height) > lvl.height) {
					pBall.y = lvl.height - pBall.height;
					pBall.collideY();
				}
			}
			
			for (var i:int = 0; i < lvl.visible.length; ++i) {
				var tmpBuild:Building = lvl.getBuilding(lvl.visible[i]);
				
				if (Top.rectCollide(tmpBuild.getCollRect(), pBall.rect) && !tmpBuild.dead) {
					var cy:int = tmpBuild.getCollRect().y;
					var cx:int = tmpBuild.getCollRect().x;
					
					//Y Collision & Damage
					if (pBall.y > cy && pBall.y < (cy + tmpBuild.colHeight)) {
						//This side can only collide from the top
						pBall.y += 4;
						tmpBuild.applyDamage(pBall.damageY); tmpBuild.redrawBitmap();
					} else if ((pBall.y + pBall.height) > cy && (pBall.y + pBall.height) < (cy + tmpBuild.colHeight)) {
						//This point can only collide from the bottom
						pBall.y -= 4;
						tmpBuild.applyDamage(pBall.damageY); tmpBuild.redrawBitmap();
					}
					
					//X Collision & Damage
					if (pBall.x > cx && pBall.x < (cx + tmpBuild.colWidth)) {
						//This point can only collide from the left
						pBall.x += 4;
						tmpBuild.applyDamage(pBall.damageX); tmpBuild.redrawBitmap();
					} else if ((pBall.x + pBall.width) > cx && (pBall.x + pBall.width) < (cx + tmpBuild.colWidth)) {
						//This point can only collide from the right
						pBall.x -= 4;
						tmpBuild.applyDamage(pBall.damageX); tmpBuild.redrawBitmap();
					}
				}
			}
			
			for (var o:int = 0; o < lvl.visObj.length; ++o) {
				var tmpObj:GameObject = lvl.getObject(lvl.visObj[o]);
				
				if (tmpObj.live && Top.rectCheck(tmpObj.rect, pBall.rect)) {
					tmpObj.kill(); pBall.collideObj();
				}
			}
			
			lvl.updateVisible(camX, camY);
		} //collCheck();
		
		//For debug display, remove from live version. 
		/*
		private function debugText():void {
			debugDisplay.text =
			"FPS    |   " + fpsString + " \n" + 
			"MEM    |   " + memText;
			"pBall  |X  " + pBall.x + " \n" +
			"       |Y  " + pBall.y + " \n" +
			"       |MX " + (Math.round(pBall.momentumX * 100) / 100) + "\n" +
			"       |MY " + (Math.round(pBall.momentumY * 100) / 100) + "\n" +
			"Camera |X  " + (Math.round(camX)) + "\n" +
			"       |Y  " + (Math.round(camY)) + "\n" +
			"TileSel|#  " + tilePicker;
		}
		*/
		
		//----------------------------------------------------
		//  Rendering
		//----------------------------------------------------
		private function render(redrawAll:Boolean = false):void {
			
			//Determine the x/y pixel offsets from camX/Y
			//This is so the camera scrolls smoothly from small movements
			var xPxOffset:int = camX % Top.TILE_SIZE;
 			var yPxOffset:int = camY % Top.TILE_SIZE;
			
			//Calc the start points
			var drawPointX:int = camX / Top.TILE_SIZE;
			var drawPointY:int = camY / Top.TILE_SIZE;
			
			//The number of tiles to draw
			var drawsX:int     = drawPointX + maxDrawableX;
			var drawsY:int     = drawPointY + maxDrawableY;
			
			//Check if the X length is exceeding the level size.
			if (drawsX > lvl.rowLength) {
				drawsX     = lvl.rowLength;
				drawPointX = lvl.rowLength - (maxDrawableX - 1);
			}
			
			//Check if the Y length is exceeding the level size.
			if (drawsY > lvl.colLength) {
				drawsY     = lvl.colLength;
				drawPointY = lvl.colLength - (maxDrawableY - 1);
			}
			
			//Drawing tiles
			var cPoint:Point = new Point((Top.TILE_SIZE * -1) - xPxOffset, (Top.TILE_SIZE * -1) - yPxOffset);
			//Run the for loop 
			for (var x:int = drawPointX; x <= drawsX; ++x) {
				cPoint.x += Top.TILE_SIZE;
				cPoint.y =  (Top.TILE_SIZE * -1) - yPxOffset; //Correct Y each loop reset
				for (var y:int = drawPointY; y <= drawsY; ++y) {
					cPoint.y += Top.TILE_SIZE;
					
					this.bitmapData.copyPixels(
					tH.getTile(lvl.getTileVal(x, y)),
					new Rectangle(0, 0, Top.TILE_SIZE, Top.TILE_SIZE),
					cPoint);
				}
			}
			
			var buildFront:Array  = new Array();
			var objectFront:Array = new Array();
			
			if (drawObject) { 
				for (var o:int = 0; o < lvl.visObj.length; ++o) { 
					var tmpObj:GameObject = lvl.getObject(lvl.visObj[o]);		
					
					if ((tmpObj.y + tmpObj.height) < (pBall.y + pBall.height) || !tmpObj.live) {
						//this.bitmapData.draw(tH.getObject(tmpObj.type, tmpObj.live),
						//	new Matrix(1, 0, 0, 1, tmpObj.x - camX + 4, tmpObj.y - camY - 4),
						//	new ColorTransform(0, 0, 0, 0.2));
						this.bitmapData.draw(tH.getObject(tmpObj.type, tmpObj.live),
							new Matrix(1, 0, 0, 1, tmpObj.x - camX, tmpObj.y - camY));
					} else {
						objectFront.push(o);
					}
				}
			}
			
			var skewMat:Matrix; //For potential shadow manipulation
			//Draw buildings
			if (drawBuilding) {
				for (var v:int = 0; v < lvl.visible.length; ++v) {
					var tmpBuild:Building = lvl.getBuilding(lvl.visible[v]);				
					
					if ((tmpBuild.y + tmpBuild.bmpHeight) < (pBall.y + pBall.height) || tmpBuild.dead) {
						//Big performance drain... 
						skewMat = new Matrix(1, 0, 0, 1, tmpBuild.sx - camX, tmpBuild.sy - camY);
						
						//tmpBuild.dead ? null : this.bitmapData.draw(tmpBuild.shadow, skewMat);
						this.bitmapData.copyPixels(
							tmpBuild.bmp,
							new Rectangle(0, 0, tmpBuild.bmpWidth, tmpBuild.bmpHeight),
							new Point(tmpBuild.x - camX, tmpBuild.y - camY)
						);
					} else { 
						buildFront.push(v);
					}
				}
			}
			
			//Draw the player object
			if(drawPlayer){
				pBall.updateGraphics();
				this.bitmapData.draw(pBall, new Matrix(1.03, 0, 0, 1, pBall.x - camX + 8, pBall.y - camY - 8), new ColorTransform(0, 0, 0, 0.2));
				this.bitmapData.draw(pBall, new Matrix(1.03, 0, 0, 1, pBall.x - camX, pBall.y - camY)); //Try and change to copyPixels? 
			}		
			
			//Draw any objects that should be in front
			for (var z:int = 0; z < objectFront.length; ++z ) {
				var fObj:GameObject = lvl.getObject(lvl.visObj[objectFront[z]]);
				
				//this.bitmapData.draw(tH.getObject(fObj.type, fObj.live),
				//	new Matrix(1, 0, 0, 1, fObj.x - camX + 4, fObj.y - camY - 4),
				//	new ColorTransform(0, 0, 0, 0.2));				
				this.bitmapData.draw(tH.getObject(fObj.type, fObj.live),
					new Matrix(1, 0, 0, 1, fObj.x - camX, fObj.y - camY));
			}
			
			for (var a:int = 0; a < buildFront.length; ++a ) {
				var front:Building = lvl.getBuilding(lvl.visible[buildFront[a]]);
				skewMat = new Matrix(1, 0, 0, 1, front.sx - camX, front.sy - camY);
				
				//front.dead ? null : this.bitmapData.draw(front.shadow, skewMat);
				this.bitmapData.copyPixels(
					front.bmp,
					new Rectangle(0, 0, front.bmpWidth, front.bmpHeight),
					new Point(front.x - camX, front.y - camY)
				);
				
				if (Top.rectCollide(front.getRect(), pBall.rect)) {
					this.bitmapData.draw(pBall, new Matrix(1.03, 0, 0, 1, pBall.x - camX, pBall.y - camY), new ColorTransform(0, 0, 0, 0.2)); 
				}
			}
			
			//Draw UI 
			if(editMode){
				//Level Editor UI
				/*
				this.bitmapData.fillRect(new Rectangle(0, 0, 100, 34), 0x00000000);
				this.bitmapData.copyPixels(tH.getTile(tilePicker + 128 - 1), new Rectangle(0, 0, 32, 32), new Point(1, 1));
				this.bitmapData.copyPixels(tH.getTile(tilePicker + 128), new Rectangle(0, 0, 32, 32),     new Point(34, 1));
				this.bitmapData.copyPixels(tH.getTile(tilePicker + 128 + 1), new Rectangle(0, 0, 32, 32), new Point(67, 1));
				
				this.bitmapData.fillRect(new Rectangle(0, 32, 32, 32), 0xFF0000FF);
				this.bitmapData.copyPixels(tH.getBuildTile(2, buildSelT), new Rectangle(0,0,16,16), new Point(4,44));
				
				this.bitmapData.fillRect(new Rectangle(lvl.getBuilding(buildPicker).x + (buildSelX * 16) - camX, 
				lvl.getBuilding(buildPicker).y + (buildSelY * 16) - camY, 12, 4), 0xFFFF0000);
				
				this.bitmapData.draw(tH.getObject(objSelT, true), new Matrix(1, 0, 0, 1, 0, 128));
				*/
			} else {
				//In-game UI
				this.bitmapData.draw(gTimer.bmp, new Matrix(1, 0, 0, 1, 412, 8));
				this.bitmapData.draw(scoreUI.bmp, new Matrix(1, 0, 0, 1, 8, 8));
				this.bitmapData.draw(havocUI.bmp, new Matrix(1, 0, 0, 1, 8, 708));
				this.bitmapData.draw(boostUI.bmp, new Matrix(1, 0, 0, 1, 616, 708));
			}		
			
		} //render
		
		private function pause():void {
			gTimer.stop();
			paused = true;
			pBall.paused = true;
			
			Top.soundHandler.pause();
			this.dispatchEvent(new Event(GAME_MENU));
			Top.DISPATCH.addEventListener(Top.GAME_UNPAUSE, unpause);
		}
							
		private function unpause(e:Event):void {
			gTimer.start();
			paused = false;
			pBall.paused = false;
			Top.soundHandler.resume();
			Top.DISPATCH.removeEventListener(Top.GAME_UNPAUSE, unpause);
		} //unpause
		
		//----------------------------------------------------
		//  Exiting
		//----------------------------------------------------
		public function exit(e:Event):void {
			//Remove Event Listeners
			this.removeEventListener(Event.ENTER_FRAME, onFrame);
			Top.mStage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			Top.mStage.removeEventListener(KeyboardEvent.KEY_UP,   keyUp);
			Top.mStage.removeEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
			Top.mStage.removeEventListener(MouseEvent.MOUSE_UP,    mouseUp);
			Top.mStage.removeEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
			//Top.mStage.removeChild(debugDisplay);
			
			//Clean out data
			this.bitmapData.dispose();
			
			//Return to main menu
			this.dispatchEvent(new Event(GAME_OVER));
		} //exit
		
		private function gTimerOver(e:Event):void {
			//Load the score / stat screen before doing an exit.
			endScreen = new UIMenu(32, 32, 960, 704);
			
			gTimer.stop();
			paused = true;
			pBall.paused = true;
			
			endScreen.addText("GAME OVER", 240, 16, 4);
			endScreen.addText(String("Buildings destroyed " + stats.buildsDestroyed + " out of " + (lvl.numBuilds - 1)), 120, 96, 2);
			endScreen.addText(String("Objects destroyed   " + stats.objsDestroyed   + " out of " + (lvl.numObjs - 1)), 120, 128, 2);
			endScreen.addText(String("Final Score:" + stats.score), 60, 192, 4);
			
			for (var s:int = 0; s < Top.localScores.length; ++s) {
				if (stats.score > Top.localScores[s][1]) {
					repScore = s
					s        = Top.localScores.length;
					endScreen.addButton(424, 356, 32, 32, "d1+", "+");
					endScreen.addButton(456, 356, 32, 32, "d2+", "+");
					endScreen.addButton(488, 356, 32, 32, "d3+", "+");
					endScreen.addButton(424, 434, 32, 32, "d1-", "-");
					endScreen.addButton(456, 434, 32, 32, "d2-", "-");
					endScreen.addButton(488, 434, 32, 32, "d3-", "-");	
					endScreen.addButton(528, 394, 96, 32, "dOk", "OK");
					endScreen.addText("ENTER YOUR INITIALS\n\n       " + initials, 160, 288, 3);
				}
			}
			
			endScreen.addButton(320, 500, 320, 32, "replay", "Replay");
			endScreen.addButton(320, 580, 320, 32, "exit", "Exit to Main Menu");
			Top.mStage.addChild(endScreen);
			
			endScreen.addEventListener(UIMenu.MENU_BUTTON_PRESSED, endScreenInput)
		} //gTimerOver
		
		private function endScreenInput(e:Event):void {
			var i:int;
			switch(e.target.lastButtonID) {
				case "d1+": {
					i = initials.charCodeAt(0); ++i;
					
					if (i < 65) {
						i = 90;
					} else if (i > 90) {
						i = 65;
					}
					
					initials = String.fromCharCode(i, initials.charCodeAt(1), initials.charCodeAt(2));
					endScreen.replaceText("ENTER YOUR INITIALS\n\n       " + initials, 4);
					break;
				}
				
				case "d1-": {
					i = initials.charCodeAt(0); --i;
					
					if (i < 65) {
						i = 90;
					} else if (i > 90) {
						i = 65;
					}
					
					initials = String.fromCharCode(i, initials.charCodeAt(1), initials.charCodeAt(2));
					endScreen.replaceText("ENTER YOUR INITIALS\n\n       " + initials, 4);					
					break;
				}
				
				case "d2+": {
					i = initials.charCodeAt(1); ++i;
					
					if (i < 65) {
						i = 90;
					} else if (i > 90) {
						i = 65;
					}
					
					initials = String.fromCharCode(initials.charCodeAt(0), i, initials.charCodeAt(2));
					endScreen.replaceText("ENTER YOUR INITIALS\n\n       " + initials, 4);
					break;
				}
				
				case "d2-": {
					i = initials.charCodeAt(1); --i;
					
					if (i < 65) {
						i = 90;
					} else if (i > 90) {
						i = 65;
					}
					
					initials = String.fromCharCode(initials.charCodeAt(0), i, initials.charCodeAt(2));
					endScreen.replaceText("ENTER YOUR INITIALS\n\n       " + initials, 4);					
					break;
				}
				
				case "d3+": {
					i = initials.charCodeAt(2); ++i;
					
					if (i < 65) {
						i = 90;
					} else if (i > 90) {
						i = 65;
					}
					
					initials = String.fromCharCode(initials.charCodeAt(0), initials.charCodeAt(1), i);
					endScreen.replaceText("ENTER YOUR INITIALS\n\n       " + initials, 4);
					break;
				}
				
				case "d3-": {
					i = initials.charCodeAt(2); --i;
					
					if (i < 65) {
						i = 90;
					} else if (i > 90) {
						i = 65;
					}
					
					initials = String.fromCharCode(initials.charCodeAt(0), initials.charCodeAt(1), i);
					endScreen.replaceText("ENTER YOUR INITIALS\n\n       " + initials, 4);					
					break;
				}
				
				case "dOk": {
					/*
					var cpArray:Array = Top.localScores.slice(); 
					
					for (var s:int = repScore; s < Top.localScores.length; ++s) {
						if (s > 0) {
							trace(s);
							//Push down by one
							cpArray[s][0] = Top.localScores[s - 1][0];
							cpArray[s][1] = Top.localScores[s - 1][1];
						}
					}
					
					Top.localScores = cpArray;
					*/
					
					Top.localScores[repScore][0] = initials;
					Top.localScores[repScore][1] = stats.score;
					
					Top.DISPATCH.dispatchEvent(new Event(Top.SCORE_WRITEOUT));
					
					endScreen.close();
					exit(null);
					break;
				}
				
				case "replay": {
					_endState = "replay";
					
					endScreen.close();
					exit(null);
					break;
				}
				
				case "exit": {
					endScreen.close();
					exit(null);
					break;
				}
			}
		} //endScreenInput
		
		//----------------------------------------------------
		//  Camera and Scaling
		//----------------------------------------------------		
		private function centerCam(t:int):void {
			lastCamX = camX;
			lastCamY = camY;
			
			//Using the camera follow multiplier by the difference between the camera and centered ball position.
			var toMoveX:Number = (CAMERA_SPEED * t) * (camX - ((pBall.x + (pBall.width  / 2)) - (Top.mStage.stageWidth  / 2)));  
			var toMoveY:Number = (CAMERA_SPEED * t) * (camY - ((pBall.y + (pBall.height / 2)) - (Top.mStage.stageHeight / 2)));
			
			//Apply the changes here
			camX -= toMoveX;
			camY -= toMoveY;
			
			//If the changes hit the edges of the screen then go ahead and set the to that. 
			if (camX < minCamX || camY < minCamY) {
				camX < minCamX ? camX = minCamX : null;
				camY < minCamY ? camY = minCamY : null;
			} 
			if (camX > maxCamX || camY > maxCamY) { 
				camX > maxCamX ? camX = maxCamX : null;
				camY > maxCamY ? camY = maxCamY : null;
			}
			
			lvl.updateVisible(camX, camY);
		}
		
		//----------------------------------------------------
		//  Keyboard Handling
		//----------------------------------------------------
		private function keyDown(e:KeyboardEvent):void {
			//Game mode key commands
			if(!editMode){
				switch(e.keyCode) {
					//ESC
					case 27: {
						if (!paused) {
							pause();
						}
						break;
					}
					
					//LEFT
					case 37: {
						moveLeftHeld = true;
						break;
					}
					//UP
					case 38: {
						moveUpHeld = true;
						break;
					}
					//RIGHT
					case 39: {
						moveRightHeld = true;
						break;
					}
					//DOWN
					case 40: {
						moveDownHeld = true;
						break;
					}
					//X -- Boost
					case 88: {
						boostHeld = true;
						break;
					}
					//Z -- Brake
					case 90: {
						brakeHeld = true;;
						break;
					}
					default: {
						break;
					}
				}
			} else {
			//Editing Key Commands
				switch(e.keyCode) {
					//LEFT
					case 37: {
						if (e.ctrlKey){
						lvl.getBuilding(buildPicker).move((lvl.getBuilding(buildPicker).x / Top.TILE_SIZE) - 1, (lvl.getBuilding(buildPicker).y / Top.TILE_SIZE));
						} else {
							--buildSelX;
							buildSelX < 0 ? buildSelX = 0 : null;
						}
						break;
					}
					//UP
					case 38: {
						if (e.ctrlKey){
						lvl.getBuilding(buildPicker).move((lvl.getBuilding(buildPicker).x / Top.TILE_SIZE), (lvl.getBuilding(buildPicker).y / Top.TILE_SIZE) - 1);
						} else {
							--buildSelY;
							buildSelY < 0 ? buildSelY = 0 : null;
						}
						break;
					}
					//RIGHT
					case 39: {
						if (e.ctrlKey){
						lvl.getBuilding(buildPicker).move((lvl.getBuilding(buildPicker).x / Top.TILE_SIZE) + 1, (lvl.getBuilding(buildPicker).y / Top.TILE_SIZE));
						} else {
							++buildSelX;
							buildSelX >= lvl.getBuilding(buildPicker).width ? buildSelX = lvl.getBuilding(buildPicker).width - 1 : null;
						}
						break;
					}
					//DOWN
					case 40: {
						if (e.ctrlKey) {
						lvl.getBuilding(buildPicker).move((lvl.getBuilding(buildPicker).x / Top.TILE_SIZE), (lvl.getBuilding(buildPicker).y / Top.TILE_SIZE) + 1);
						} else {
							++buildSelY;
							buildSelY >= (lvl.getBuilding(buildPicker).height + lvl.getBuilding(buildPicker).floors) ? buildSelY = lvl.getBuilding(buildPicker).height + lvl.getBuilding(buildPicker).floors - 1 : null;
						}
						break;
					}					
					
					//Cam Move
					case 72: {
						//Camera movement
						if(editMode){
							camMove = true; 
							lastX = mouseX; lastY = mouseY;
						}
						break;
					}
					
					//X
					case 88: {
						//Copy a tile
						buildSelT = lvl.getBuilding(buildPicker).getTile(buildSelX, buildSelY);
						lvl.getBuilding(buildPicker).redrawBitmap();
						break;
					}
					
					//Z 
					case 90: {
						//Write a tile
						lvl.getBuilding(buildPicker).modTile(buildSelX, buildSelY, buildSelT);
						lvl.getBuilding(buildPicker).redrawBitmap();
						break;
					}
 						
					//F12 -- DEV - Save / Show Level Bitmap
					case 123: {
						//Save this to a file! -- REMOVE FROM FINAL
						var byte:ByteArray = lvl.writeData();
						file.save(byte, "level.dat");
						break;
					}
					
					//+
					case 187: {
						++buildSelT; e.ctrlKey ? buildSelT += 8 : null;
						buildSelT > 128 ? buildSelT = -128 : null;
						break;
					}
					
					//- 
					case 189: {
						--buildSelT; e.ctrlKey ? buildSelT -= 8 : null;
						buildSelT < -128 ? buildSelT = 128 : null;
						break;
					}
					
					//.
					case 190: {
						--objSelT; e.ctrlKey ? objSelT -= 8 : null;
						objSelT <= 0 ? objSelT = 0 : null;
						break;
					}
					
					// /
					case 191: {
						++objSelT; e.ctrlKey ? objSelT -= 8 : null;
						objSelT >= 256 ? objSelT = 256 : null;
						break;
					}
					
					//[
					case 219: {
						--tilePicker; 
						tilePicker < -128 ? tilePicker = 128 : null;
						break;
					}
					//]
					case 221: {
						++tilePicker; 
						tilePicker > 128 ? tilePicker = -128 : null;
						break;
					}
					default: {
						break;
					}
				}				
			}
			/*
			//Key commands active in all modes.
			switch(e.keyCode) {
				//F4 -- Debug Reserved
				case 115: {
					Top.DISPATCH.dispatchEvent(new Event(Top.GAME_UNPAUSE));
					debugDisplay.visible ? debugDisplay.visible = false: debugDisplay.visible = true;
					break;
				}
				
				//F5 -- Edit Mode Activate
				case 116: {
					editMode ? editMode = false : editMode = true; 
					break;
				}
				
				//F6 -- Toggle player visibility
				case 117: {
					drawPlayer ? drawPlayer = false : drawPlayer = true;
					break;
				}
				
				//F7 -- Toggle building visibility
				case 118: {
					drawBuilding ? drawBuilding = false : drawBuilding = true;
					break;
				}
				
				//F8 -- Toggle object visibility
				case 119: {
					drawObject ? drawObject = false : drawObject = true;
					break;
				}
				
				//F9 -- Toggle collision
				case 120: {
					collEnabled ? collEnabled = false : collEnabled = true;
				}
				
				default: {
					break;
				}
			}
			*/
		} //keyDown
		
		private function keyUp(e:KeyboardEvent):void {
			switch(e.keyCode) {
				
				//LEFT
				case 37: {
					moveLeftHeld = false;
					break;
				}
				
				//UP
				case 38: {
					moveUpHeld = false;
					break;
				}
				
				//RIGHT
				case 39: {
					moveRightHeld = false;
					break;
				}
				
				//DOWN
				case 40: {
					moveDownHeld = false;
					break;
				}
				
				//H
				case 72: {
					camMove = false;
					break;
				}
				
				//X -- Boost
				case 88: {
					boostHeld = false;
					break;
				}
				
				//Z -- Brake
				case 90: {
					brakeHeld = false;
					break;
				}
			}
		} //keyUp
		
		//----------------------------------------------------
		//  Mouse Handling
		//----------------------------------------------------		
		private function mouseDown(e:MouseEvent):void {
			//Writing tool
			if (!e.altKey && !e.shiftKey && editMode) {
				lvl.setTile(Math.floor((mouseX + camX) / Top.TILE_SIZE), 
							Math.floor((mouseY + camY) / Top.TILE_SIZE), 
							tilePicker);
				drawDown = true;
			}
			
			if (e.shiftKey) { 
				if (e.altKey) {
					lvl.addObject(Math.floor((mouseX + camX) / Top.TILE_SIZE), Math.floor((mouseY + camY) / Top.TILE_SIZE), objSelT);
					lvl.updateVisible(camX, camY);
				} else {
					for (var i:int = 0; i < lvl.visible.length; ++i) { 
						if (lvl.getBuilding(lvl.visible[i]).getRect().containsPoint(new Point(mouseX + camX, mouseY + camY))) {
							buildPicker = lvl.visible[i];
							i = lvl.visible.length; 
							
							trace("Building selected: " + buildPicker);
							trace("BuildingX: " + Math.floor((mouseX + camX) / 32) + " Y: " + Math.floor((mouseY + camY) / 32));
						}
					}
				}
			}
			
			//Eyedropper / copy tool
			if (e.altKey) {
				if(e.ctrlKey){
					for (var o:int = 0; o < lvl.visObj.length; ++o) {
						if (lvl.getObject(lvl.visObj[o]).rect.containsPoint(new Point(mouseX + camX, mouseY + camY))) {
							lvl.removeObject(lvl.visObj[o]);
							o = lvl.visObj.length;
						}
					}
				} else {
					tilePicker = lvl.getTileVal(Math.floor((mouseX + camX) / Top.TILE_SIZE), Math.floor((mouseY + camY) / Top.TILE_SIZE)) - 128;
				}
			}			
		} //mouseDown

		private function mouseUp(e:MouseEvent):void {
			drawDown = false;
		} //mouseUp
		
		private function mouseMove(e:MouseEvent):void {
			if (drawDown) {
				lvl.setTile(Math.floor((mouseX + camX) / Top.TILE_SIZE), Math.floor((mouseY + camY) / Top.TILE_SIZE), tilePicker); 	
			}
			
			if (editMode && camMove) {
				//Switch these around for inverted controls?
				camX -= mouseX - lastX;
				camY -= mouseY - lastY;
				
				//Smooth mouse movement
				lastX = mouseX; lastY = mouseY;
				
				lvl.updateVisible(camX, camY);
			}
		} //mouseMove
		
		//----------------------------------------------------
		//  Console Events
		//----------------------------------------------------		
		
		public function devAddBuilding(e:Event):void {
			lvl.addBuilding(Top.console.params[1], Top.console.params[2], Top.console.params[3], Top.console.params[4], Top.console.params[5]);
			lvl.updateVisible(camX, camY);
		} //devAddBuilding
		
		public function get endState():String { return _endState; }
	}
}