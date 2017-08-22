package {
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	import utility.DevConsole;
	import flash.geom.Rectangle;
	import utility.SoundPlayer;
	/**
	 * ...
	 * @author Jonathan W. Thomas
	 * 
	 * Global variables. 
	 */
	public class Top {
		//Performance testing
		private static var testTime:int;
		private static var testStarted:Boolean;
		
		//Top stage
		public static var mStage:Stage;
		public static var DISPATCH:EventDispatcher;
		public static var console:DevConsole;
		public static var soundHandler:SoundPlayer;
		public static var localScores:Array;
		
		//Sound control
		public static var soundEnabled:Boolean;
		public static var musicEnabled:Boolean;
		
		//Embed this as 'Courier New' so that the console can use that font and the other can use the embedded font
		[Embed(source="resource/emulogic.ttf", fontFamily='NES', fontName='Courier New', embedAsCFF='false', mimeType='application/x-font-truetype')]
		public static const font:Class;
		
		public static const VERSION:String = "0.1";
		public static const TILE_SIZE:int  = 32;
		public static const BUILD_SIZE:int = 16;
		public static const TEXT_FORMAT:TextFormat = new TextFormat('Courier New', 12, 0xFFFFFF);
		
		public static const CREDIT_TEXT:String = 
		"     -Credits-\n" +
		"Game, Music, Sounds \nand Graphics\n\nCreated by:" +
		"\nTheOrange\n(Jonathan Thomas)\n\nForwardBackspace.com"; 
		
		public static const SCORE_ARRAY:Array = 
		[["JON", 95000],
		["BAL", 91000],
		["BUT", 80000],
		["FAT", 70000],
		["DET", 60000],
		["DRU", 50000],
		["NOP", 45000],
		["LOL", 40000],
		["BAS", 30000],
		["URA", 15000]];		
		
		//Events
		public static const SOUND_MUTE:String       = "SND_MUTE";
		public static const MUSIC_MUTE:String       = "MUS_MUTE";
		public static const SOUND_UNMUTE:String     = "SND_UNMUTE";
		public static const MUSIC_UNMUTE:String     = "MUS_UNMUTE";
		public static const GAME_UNPAUSE:String     = "GAME_UNPAUSE";
		public static const GAME_EXIT:String        = "GAME_EXIT";
		public static const STAT_SCOREUPDATE:String = "STAT_SCORE";
		public static const STAT_HAVOCUPDATE:String = "STAT_HAVOC";
		public static const SCORE_WRITEOUT:String   = "SCORE_WRITEOUT";
		
		//Dev Console Events
		public static const DEV_REPLACETILE:String = "DEV_REPLACETILE"; 
		public static const DEV_ADDBUILD:String    = "DEV_ADDBUILD";
		public static const DEV_QUERYBUILD:String  = "DEV_QUERYBUILD"; 
		public static const DEV_MODBUILD:String    = "DEV_MODBUILD";
		public static const DEV_MOVEBUILD:String   = "DEV_MOVEBUILD";
		public static const DEV_REMBUILD:String    = "DEV_REMBUILD";
		public static const DEV_COPYBUILD:String   = "DEV_COPYBUILD";
		public static const DEV_ADDOBJECT:String   = "DEV_ADDOBJECT";
		public static const DEV_MOVEOBJECT:String  = "DEV_MOVEOBJECT";
		
		public static function performanceTest():void {
			if (testStarted == true) {
				trace("Last test was started " + String(getTimer() - testTime) + "ms ago, was not cancelled properly.");
			} else {
				testStarted = true;
				testTime    = getTimer();
			}
		}
		
		public static function endTest():void {
			trace("Test results: " + String(getTimer() - testTime));
			testStarted = false;
		}
		
		public static function rectCollide(rect1:Rectangle, rect2:Rectangle):Boolean {
			if (rect1.contains(rect2.x, rect2.y)                ||
				rect1.contains(rect2.x + rect2.width, rect2.y)  ||
				rect1.contains(rect2.x, rect2.y + rect2.height) ||
				rect1.contains(rect2.x + rect2.width, rect2.y + rect2.height)) {
					return true;
			}
			return false;
		} //rectCollide
		
		public static function rectCheck(r1:Rectangle, r2:Rectangle):Boolean {
			if ((r1.x > r2.x && r1.x < (r2.x + r2.width)) || ((r1.x + r1.width) > r2.x && (r1.x + r1.width) < (r2.x + r2.width))) {
				if ((r1.y > r2.y && r1.y < (r2.y + r2.height)) || ((r1.y + r1.height) > r2.y && (r1.y + r1.height) < (r2.y + r2.height))) {
					return true;
				}				
			}
			
			return false;
		} //rectCheck
		
		public static function musicToggle():void {
			Top.musicEnabled ? Top.musicEnabled = false  : Top.musicEnabled = true;
			Top.musicEnabled ? Top.soundHandler.unmute() : Top.soundHandler.mute();			
		} //musicToggle
		
		public static function soundToggle():void {
			Top.soundEnabled ? Top.soundEnabled = false : Top.soundEnabled = true;		
		} //soundToggle
	}

}