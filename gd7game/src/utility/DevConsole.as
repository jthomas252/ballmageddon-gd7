package utility {
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	public class DevConsole extends TextField {
		private static const MAX_LINES:int = 13;
		
		private static var messages:Array;
		private static var input:String;
		private var        _params:Array;
		
		public function DevConsole() {
			
			this.defaultTextFormat = Top.TEXT_FORMAT;
			//this.embedFonts        = true;
			this.width             = Top.mStage.stageWidth;
			this.height            = 256;
			this.background        = true;
			this.alpha             = 0.8;
			this.backgroundColor   = 0x44000000;
			this.visible           = false;
			this.selectable        = false;
			
			_params  = new Array();
			
			messages = new Array();
			
			input    = "";
			
			Top.mStage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		}
		
		public function keyDown(e:KeyboardEvent):void {
			switch(e.keyCode) {
				//Backspace
				case 8: {
					if (input.length > 0) {
						input = input.substr(0, input.length - 1);
					}
					if (e.ctrlKey) {
						input = "";
					}
					break;
				}
				
				//Enter
				case 13: {
					if (input.length > 0) {
						parseInput(); 
						input = "";
					}
					break;
				}
				
				//Send arrow keys to break or else they break the console
				case 37: {
					break;
				}
				
				case 38: {
					break;
				}
				
				case 39: {
					break;
				}
				
				case 40: {
					break;
				}
				
				//Same for F keys
				case 112: {
					break;
				}
				
				case 113: {
					break;
				}
				
				case 114: {
					break;
				}
				
				case 115: {
					break;
				}
				
				case 116: { 
					break;
				}
				
				case 117: {
					break;
				}
				
				case 118: {
					break;
				}
				
				case 119: {
					break;
				}
				
				case 120: {
					break;
				}
				
				//Tilde
				case 192: {
					//this.visible ? this.visible = false : this.visible = true;
					break;
				}
				
				default: {
					if (this.visible) {
						if(!e.shiftKey && !e.ctrlKey && !e.altKey){
						input += String.fromCharCode(e.charCode);
						}
					}
					break;
				}
			}

			
			update();
		}
		
		private function update():void {
			var str:String = new String();
			var i:int = 0;
			for (i; i < messages.length; ++i) {
				str += messages[messages.length - (i + 1)];
				str += "\n";
			}
			
			if (i < MAX_LINES) {
				for (i; i < MAX_LINES; ++i) {
					str += "\n";
				}
			}
			
			//Add input
			input = input.toUpperCase();
			str += "\n>: " + input;
			this.text = str;
		}
		
		private function parseInput():void {
			input = input.toUpperCase();
			var inputArray:Array = input.split(" ");
			var msgText:String   = "";
			
			switch(inputArray[0]) {
				case "ADDBUILDING": {
					if (inputArray.length < 6) {
						msgText = "ADDBUILDING: Insufficent parameters";
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_ADDBUILD));
					}
					break;
				}
				
				case "COPYBUILDING": {
					if (inputArray.length < 3) {
						msgText = "COPYBUILDING: Insufficent parameters";  
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_COPYBUILD));
					}
					break;
				}
				
				case "MODBUILDING": {
					if (inputArray.length < 4) {
						msgText = "MODBUILDING: Insufficent parameters";
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_MODBUILD));
					}
					break;
				}
				
				case "MOVEBUILDING": {
					if (inputArray.length < 3) {
						msgText = "MOVEBUILDING: Insufficent parameters";
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_MOVEBUILD));
					}
					break;
				}
				
				case "REMOVEBUILDING": {
					if (inputArray.length < 1) {
						msgText = "REMOVEBUILDING: Insufficent parameters";
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_REMBUILD));
					}
					break;
				}
				
				case "QUERYBUILDING": {
					if (inputArray.length < 1) {
						msgText = "QUERYBUILDING: Insufficent parameters";
					} else {
						_params = inputArray; 
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_QUERYBUILD));
					}
					break;
				}
				
				case "ADDOBJECT": {
					if (inputArray.length < 3) {
						msgText = "ADDOBJECT: Insufficent parameters";
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_ADDOBJECT));
					}
					break;
				}
				
				case "MOVEOBJECT": {
					if (inputArray.length < 3) {
						msgText = "MOVEOBJECT: Insufficent parameters";
					} else {
						_params = inputArray;
						Top.DISPATCH.dispatchEvent(new Event(Top.DEV_MOVEOBJECT));
					}
					break;
				}
				
				case "HELP": {//Print Help Text
					msgText =
					"-- Command Listing --- Parameters ----\n" +
					"ADDBUILDING         | width height floors x y\n" +
					"QUERYBUILDING       | building\n" + 
					"MODBUILDING         | building width height floors\n" +
					"MOVEBUILDING        | building x y\n" + 
					"REMOVEBUILDING      | building\n" +
					"COPYBUILDING        | building x y\n" + 
					"ADDOBJECT           | x y type\n" +
					"MOVEOBJECT          | object x y\n" + 
					"--------------------------------------";
					break;
				}
				
				default: {
					msgText = String(inputArray[0]) + ": Command not found, type 'HELP' for a listing of commands.";
					break;
				}
			}
			
			if (msgText.length > 0) {
				var pushData:Array = msgText.split("\n");
				pushData.reverse();
				for (var i:int = 0; i < pushData.length; ++i){
					messages.push(pushData[i]);
				}
			}
			
			while (messages.length > MAX_LINES) { 
				messages.shift();
			}
			
		}
		
		public function sendMessage(str:String):void {
			if (str != null) {
				messages.push(str);
				update();
			}
		}
		
		public function get params():Array { return _params; }
	}

}