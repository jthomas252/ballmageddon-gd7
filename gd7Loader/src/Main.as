package {
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
    public class Main extends MovieClip {
        public var loader:Loader;
        public var request:URLRequest;
		public var loadTxt:TextField;
		
		[Embed(source="emulogic.ttf", fontFamily='NES', fontName='Courier New', embedAsCFF='false', mimeType='application/x-font-truetype')]
		public static const font:Class;
			
		/**
		 * Preloader Only -- Draw and add in graphics
		 */
        public function Main() {
            loader  = new Loader();
            request = new URLRequest("http://www.forwardbackspace.com/gd7game.swf");
			
			this.graphics.beginFill(0x00);
			this.graphics.drawRect(0, 0, 1024, 768);
			this.graphics.endFill();
			
			loadTxt = new TextField();
			loadTxt.defaultTextFormat = new TextFormat("Courier New", 12, 0xFFFFFF);
			loadTxt.embedFonts = true;
			loadTxt.x = 40;
			loadTxt.y = 64;
			loadTxt.width = 480;
			
			this.addChild(loadTxt);
			
			Security.allowDomain("*"); 
			
			loader.load(request);
			
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
        }
		
        // This will fire when your main swf is loaded in.
        protected function completeHandler(e:Event):void {
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, completeHandler);
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
			
			this.graphics.clear();
            addChild(loader);
        }
		
        // this will fire if there's a problem with loading in the swf
        protected function errorHandler(e:IOErrorEvent):void {
        }
		
        // this will fire constantly while the target swf is being loaded, so you can see how much more you have to load.
        protected function progressHandler(e:ProgressEvent):void {
            var perLoaded:Number = (e.bytesLoaded / e.bytesTotal);
			
			loadTxt.text = "Loading...\n" + String(Math.round((e.bytesLoaded / e.bytesTotal) * 100)) + "%";
			
			this.graphics.beginFill(0xFFFFFF);
			this.graphics.drawRect(32, 16, 992 * perLoaded, 32);
        }
    }
}