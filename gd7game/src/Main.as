package {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import game.Game;
	import resource.ui.GD7Logo;
	import resource.ui.MainBackground;
	import resource.ui.UILogo;
	import ui.UIButton;
	import ui.UIMenu;
	import utility.DevConsole;
	import utility.SoundPlayer;
	import flash.net.SharedObject;
	
	/**
	 * ...
	 * @author Jonathan W. Thomas
	 */
	
	public class Main extends Sprite {
		private var mainMenu:UIMenu;
		private var charMenu:UIMenu;
		private var gameMenu:UIMenu;
		private var optMenu:UIMenu;
		private var confirmMenu:UIMenu;
		private var confirmFunc:Function;
		private var creditMenu:UIMenu;
		private var scoreMenu:UIMenu;
		private var gInstance:Game;
		private var shr:SharedObject;
		
		public function Main() {
			if (stage != null) {
				finishLoad();
			} else {
				addEventListener(Event.ADDED_TO_STAGE, finishLoad);
			}
		}
		
		public function finishLoad(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, finishLoad);
			
			//Shared object, stored scores
			shr = SharedObject.getLocal("BALLMAGEDDON_localscores");
			
			if (shr.data.exists) {
				Top.localScores = shr.data.scores;
			} else {
				Top.localScores = Top.SCORE_ARRAY;
			}
			
			//Declare globals
			Top.mStage       = this.stage;
			Top.DISPATCH     = new EventDispatcher();
			Top.soundHandler = new SoundPlayer(0.8, 0.6);
			
			//Re-enable these in any online versions, possibly poll a user saved data
			Top.soundEnabled = true;
			Top.musicEnabled = true; 
			
			UIMenu.loadGfx();
			UIButton.loadGfx();
			
			loadMainMenu();
			
			confirmMenu = new UIMenu(420, 292, 192, 192);
			confirmMenu.addText("Sure you want\nto quit?", 16, 16);
			confirmMenu.addButton(32, 80, 128, 32, "yes", "YES");
			confirmMenu.addButton(32, 120, 128, 32, "no" , "NO");
			
			//Developer Console
			Top.console = new DevConsole();
			this.addChild(Top.console);
			
			//Global Key Commands
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Top.DISPATCH.addEventListener(Top.SCORE_WRITEOUT, saveScores);
		} //finishLoad
		
		private function saveScores(e:Event):void {
			shr.data.exists = true;
			shr.data.scores = Top.localScores;
			
			shr.flush();
		} //savePrefabScores
		
		//Load up the main menu, entry point
		private function loadMainMenu(e:Event=null):void {
			mainMenu        = new UIMenu(0, 0, 1024, 768);
			var logo:UILogo = new UILogo();
			var gd7:GD7Logo = new GD7Logo();
			var bg:MainBackground = new MainBackground();
			
			mainMenu.addBitmap(bg.bitmapData, 0, 0);
			mainMenu.addButton(512 - 120,  320, 240, 80, "gameStart", "PLAY GAME");
			mainMenu.addButton(512 - 120,  420, 240, 80, "options",   "OPTIONS");
			mainMenu.addButton(512 - 120,  520, 240, 80, "scores",    "SCORES");
			mainMenu.addButton(1024 - 220, 708, 192, 48, "credit",   "CREDITS");
			mainMenu.addBitmap(logo.bitmapData.clone(), 512 - (logo.width / 2), 96);
			mainMenu.addBitmap(gd7.bitmapData.clone(),  512 - (gd7.width / 2), 752 - gd7.height);
			
			logo.bitmapData.dispose(); gd7.bitmapData.dispose();
			logo = null; gd7 = null;
			
			Top.soundHandler.playMusic(SoundPlayer.MENU_TRACK);
			mainMenu.addEventListener(UIMenu.MENU_BUTTON_PRESSED, parseMainMenu);
			this.addChild(mainMenu);
		} //loadMainMenu
		
		private function loadOptionMenu(e:Event = null):void {
			optMenu = new UIMenu(352, 224, 320, 320);
			
			optMenu.addText("  -Options-", 80, 20);
			if (Top.musicEnabled) {
				optMenu.addText("Music: " + String(Top.soundHandler.musicVolume) + "%", 80, 60);
			} else {
				optMenu.addText("Music: " + "Muted", 80, 60);
			}
			
			optMenu.addButton(80, 80, 32, 32, "musicUp", "+");
			optMenu.addButton(120, 80, 32, 32, "musicDown", "-");
			optMenu.addButton(160, 80, 64, 32, "musicMute", "mute");
			
			if (Top.soundEnabled) {
				optMenu.addText("Sound: " + String(Top.soundHandler.soundVolume) + "%", 80, 120);
			} else {
				optMenu.addText("Sound: " + "Muted", 80, 120);
			}
			
			optMenu.addButton(80, 140, 32, 32, "soundUp", "+");
			optMenu.addButton(120, 140, 32, 32, "soundDown", "-");
			optMenu.addButton(160, 140, 64, 32, "soundMute", "mute");
			
			optMenu.addButton(80, 180, 160, 32, "resetAll", "Erase Data");
			
			optMenu.addButton(80, 280, 160, 32, "close", "Done");
			
			optMenu.addEventListener(UIMenu.MENU_BUTTON_PRESSED, parseOptionMenu);
			
			addChild(optMenu);
		} //loadOptionMenu
		
		private function optionMenuClose():void {
			optMenu.close();
			removeChild(optMenu);
		} //optionMenuClose
		
		private function updateOptionsText():void {
			if (Top.musicEnabled) {
				optMenu.replaceText("Music: " + String(Top.soundHandler.musicVolume) + "%", 1)
			} else {
				optMenu.replaceText("Music:" + "Mute", 1);
			}
			
			if (Top.soundEnabled) {
				optMenu.replaceText("Sound: " + String(Top.soundHandler.soundVolume) + "%", 2);
			} else {
				optMenu.replaceText("Sound:" + "Mute", 2);
			}
		} //updateOptionsText		
		
		//Load an instance of the in-game menu
		private function loadGameMenu(e:Event=null):void {
			gameMenu    = new UIMenu(512 - 160, 384 - 160, 320, 320);
			
			gameMenu.addText("PAUSED", 80, 40, 2);
			gameMenu.addButton(80, 280, 160, 32, "close", "Back to game");
			gameMenu.addButton(80, 240, 160, 32, "exit",  "Exit to menu");
			gameMenu.addButton(80, 160, 160, 32, "option", "Options");
			
			gameMenu.addEventListener(UIMenu.MENU_BUTTON_PRESSED, parseGameMenu);
			
			this.addChild(gameMenu);
			this.swapChildren(gameMenu, Top.console);
		} //gameMenu
		
		//On close of in-game menu
		private function gameMenuClose():void {
			gameMenu.close();
			this.removeChild(gameMenu);
		} //gameMenuClose
		
		private function loadGame(e:Event=null):void {
			mainMenu.close();
			gInstance = new Game();
			
			Top.soundHandler.playMusic(SoundPlayer.GAME_TRACK);
			
			this.addChild(gInstance);
			this.swapChildren(gInstance, Top.console);
			
			gInstance.addEventListener(Game.GAME_OVER, onGameOver);
			gInstance.addEventListener(Game.GAME_MENU, loadGameMenu);
		} //loadGame
		
		private function onGameOver(e:Event = null):void {
			gInstance.removeEventListener(Game.GAME_OVER, onGameOver);
			gInstance.removeEventListener(Game.GAME_MENU, loadGameMenu);
			this.removeChild(gInstance);
			
			//Reload main menu & music
			if(gInstance.endState == "main"){
				loadMainMenu();
			} else { 
				loadMainMenu();
				loadGame();
			}
		} //onGameOver		
		
		private function loadCreditMenu(e:Event = null):void {
			creditMenu = new UIMenu(368, 292, 288, 256);
			
			creditMenu.addText(Top.CREDIT_TEXT, 16, 16);
			creditMenu.addButton(16, 192, 256, 32, "close", "DONE");
			
			creditMenu.addEventListener(UIMenu.MENU_BUTTON_PRESSED, parseCreditMenu);
			addChild(creditMenu);
			swapChildren(creditMenu, Top.console);
		} //loadCreditMenu
		
		private function creditMenuClose():void {
			creditMenu.close();
			removeChild(creditMenu);
		} //creditMenuClose
		
		private function loadScoreMenu(e:Event = null):void {
			scoreMenu = new UIMenu(32, 32, 960, 704);
			
			scoreMenu.addText("HIGH SCORES", 320, 8, 2 );
			scoreMenu.addText(Top.localScores[0][0], 320, 64, 2);
			scoreMenu.addText(Top.localScores[0][1], 448, 64, 2);
			
			scoreMenu.addText(Top.localScores[1][0], 320, 96, 2);
			scoreMenu.addText(Top.localScores[1][1], 448, 96, 2);
			
			scoreMenu.addText(Top.localScores[2][0], 320, 128, 2);
			scoreMenu.addText(Top.localScores[2][1], 448, 128, 2);
			
			scoreMenu.addText(Top.localScores[3][0], 320, 160, 2);
			scoreMenu.addText(Top.localScores[3][1], 448, 160, 2);		
			
			scoreMenu.addText(Top.localScores[4][0], 320, 192, 2);
			scoreMenu.addText(Top.localScores[4][1], 448, 192, 2);
			
			scoreMenu.addText(Top.localScores[5][0], 320, 224, 2);
			scoreMenu.addText(Top.localScores[5][1], 448, 224, 2);
			
			scoreMenu.addText(Top.localScores[6][0], 320, 256, 2);
			scoreMenu.addText(Top.localScores[6][1], 448, 256, 2);			
			
			scoreMenu.addText(Top.localScores[7][0], 320, 288, 2);
			scoreMenu.addText(Top.localScores[7][1], 448, 288, 2);
			
			scoreMenu.addText(Top.localScores[8][0], 320, 320, 2);
			scoreMenu.addText(Top.localScores[8][1], 448, 320, 2);
			
			scoreMenu.addText(Top.localScores[9][0], 320, 352, 2);
			scoreMenu.addText(Top.localScores[9][1], 448, 352, 2);
			
			scoreMenu.addButton(320, 512, 320, 96, "close", "DONE");
			
			scoreMenu.addEventListener(UIMenu.MENU_BUTTON_PRESSED, parseScoreMenu);
			addChild(scoreMenu);
		} //loadScoreMenu
		
		private function scoreMenuClose():void {
			scoreMenu.close();
			
			removeChild(scoreMenu);
		} //scoreMenuClose
		
		private function parseMainMenu(e:Event):void {
			switch(e.target.lastButtonID) {
				case "gameStart": {
					loadGame();
					break;
				}
				
				case "options": {
					loadOptionMenu();
					break;
				}
				
				case "scores": {
					loadScoreMenu();
					break;
				}
				
				case "credit": {
					loadCreditMenu();
					break;
				}
				
				default: {
					break;
				}
			}			
		} //parseMainMenu
		
		private function parseGameMenu(e:Event):void {
			switch(e.target.lastButtonID) {
				case "close": {
					gameMenuClose();
					Top.DISPATCH.dispatchEvent(new Event(Top.GAME_UNPAUSE));
					break;
				}
				
				case "exit": {
					gameMenuClose();
					gInstance.exit(null);
					break;
				}
				
				case "option": {
					loadOptionMenu();
					break;
				}
			}
		} //parseGameMenu
		
		private function parseOptionMenu(e:Event):void {
			switch(e.target.lastButtonID) {
				case "close": {
					optionMenuClose();
					break;
				}
				
				case "musicUp": {
					Top.soundHandler.adjustMusicVolume((Top.soundHandler.musicVolume / 100) + 0.01);
					updateOptionsText(); 
					break;
				}
				
				case "musicDown": {
					Top.soundHandler.adjustMusicVolume((Top.soundHandler.musicVolume / 100) - 0.01);
					updateOptionsText(); 
					break;
				}
				
				case "musicMute": {
					Top.musicToggle();
					updateOptionsText(); 
					break;
				}
				
				case "soundUp": {
					Top.soundHandler.adjustSoundVolume((Top.soundHandler.soundVolume / 100) + 0.01);
					updateOptionsText(); 
					break;
				}
				
				case "soundDown": {
					Top.soundHandler.adjustSoundVolume((Top.soundHandler.soundVolume / 100) - 0.01);
					updateOptionsText(); 
					break;
				}
				
				case "soundMute": {
					Top.soundToggle();
					updateOptionsText(); 
					break;
				}
				
				case "resetAll": {
					Top.localScores = Top.SCORE_ARRAY;
					saveScores(null);
					break;
				}
			}
		} //parseOptionMenu
		
		private function parseCreditMenu(e:Event):void {
			switch(e.target.lastButtonID) {
				case "close": {
					creditMenuClose();
					break;
				}
			}
		} //parseCreditMenu
		
		private function parseScoreMenu(e:Event):void {
			switch(e.target.lastButtonID) {
				case "close": {
					scoreMenuClose();
					break;
				}
			}
		} //parseScoreMenu
		
		private function onKeyDown(e:KeyboardEvent):void {
			switch(e.keyCode) {
				//M
				case 77: {
					if (e.ctrlKey) {
						Top.musicToggle();
					}
					break;
				}
				
				//S
				case 83: {
					if (e.ctrlKey) {
						Top.soundToggle();
					}
				}
			}
		} //onKeyDown
	}
}