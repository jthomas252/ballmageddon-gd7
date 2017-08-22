package game {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	public class PlayerBall extends Bitmap {
		private var _momentumX:Number;
		private var _momentumY:Number;
		
		//Texture offsets to give the ball a movement effect. 
		private var xTextureOff:Number;
		private var yTextureOff:Number;
		
		private var lastX:Number;
		private var lastY:Number;
		private var lastOffX:Number;
		private var lastOffY:Number;
		
		private var texture:Array;
		private var tSel:int;
		private var textureMask:Shape;
		
		private var canDamageX:Boolean;
		private var canDamageY:Boolean;
		private var dmgTimer:Timer;
		private var _boostBar:Number;
		
		private var DAMAGE_INTERVAL:int         = 150;
		private var FORCE_SCALE:Number          = 4;     //Multiplier of momentum 
		private var MIN_MOMENTUM:Number         = 0.50;  //Minimum momentum to apply damage at
		private var TIME_MOVEMENT_SCALE:Number  = 0.1;   //The distance covered per millisecond to pixel
		private var ACCELERATION:Number         = 0.006;  //How quickly the ball builds up speed
		private var ACCELERATE_DECAY:Number     = 0.001; //How quickly the ball slows down when not being accelerated
		private var MOMENTUM_CAP:Number         = 4;     //The maximum travel speed
		private var BOOST_CAP:Number            = 6;     //Maximum speed while boosting.
		private var COLLIDE_BOUNCE:Number       = 0.8;   //The percent of momentum that's retained when colliding with an object
		private var BRAKE_SPEED:Number          = 0.005; //Braking speed
		
		//For Hazard / Sinking
		private static const SINK_RATE:int = 50;
		private var _sinking:Boolean;
		private var sunk:Boolean;
		private var sinkTimer:Timer;
		private var riseTimer:Timer;
		private var clipY:int; 
		
		//Havoc Related
		private static const MAX_BOOST:int         = 100;
		private static const HAVOC_DECAY_SUNK:int  = 25;
		private static const HAVOC_DECAY_NORM:int  = 5;
		private static const DECAY_FREQUENCY:int   = 500;
		private static const HAVOC_LEVEL_REQ:Array = [1750, 2250, 3000, 4250];
		private var _hLevel:int;
		
		private var decayTimer:Timer;
		private var boostTimer:Timer;
		
		private var _paused:Boolean;
		private var boostHeld:Boolean;
		
		public function PlayerBall(bmp:BitmapData) {			
			//IF YOU IMPLEMENT CHARACTER SELECT REMEMBER TO CHANGE THIS TO SOMETHING TO GET CHARACTER INFO!!!
			DAMAGE_INTERVAL        = 150;
			FORCE_SCALE            = 4;     
			MIN_MOMENTUM           = 0.50; 
			TIME_MOVEMENT_SCALE    = 0.1;   
			ACCELERATION           = 0.006;  
			ACCELERATE_DECAY       = 0.001; 
			MOMENTUM_CAP           = 4;     
			BOOST_CAP              = 6;    
			COLLIDE_BOUNCE         = 0.8;  
			BRAKE_SPEED            = 0.005; 		
			
			_paused         = false;
			boostHeld       = false;
			
			//Variable Init
			_boostBar       = 100;
			_momentumX      = 0;
			_momentumY      = 0;
			xTextureOff     = 0;
			yTextureOff     = 0;
			textureMask     = new Shape();
			this.bitmapData = new BitmapData(64, 64, true, 0x00);
			texture         = new Array(bmp); tSel = 0;
			canDamageX      = true;
			canDamageY      = true;
			dmgTimer        = new Timer(DAMAGE_INTERVAL, 1);
			dmgTimer.addEventListener(TimerEvent.TIMER_COMPLETE, damageTick);
			
			clipY           = 0;
			sinkTimer       = new Timer(SINK_RATE, 32);
			riseTimer       = new Timer(SINK_RATE, 1);
			_sinking        = false;
			sunk            = false;
			
			decayTimer      = new Timer(DECAY_FREQUENCY);
			decayTimer.addEventListener(TimerEvent.TIMER, onDecay);
			decayTimer.start();
			
			boostTimer      = new Timer(50);
			boostTimer.addEventListener(TimerEvent.TIMER, boostTick);
			boostTimer.start();
		} //PlayerBall
		
		public function updateHavoc(e:Event):void {
			if (Game.stats.havoc > HAVOC_LEVEL_REQ[_hLevel]) {
				if ((_hLevel) < HAVOC_LEVEL_REQ.length) {
					levelUp(); 
				}
			}
		} //updateHavoc
		
		private function levelUp():void {
			FORCE_SCALE  *= 1.1;
			ACCELERATION *= 1.1;
			BOOST_CAP    *= 1.1;
			MOMENTUM_CAP *= 1.1;
			
			Game.stats.addHavoc(HAVOC_LEVEL_REQ[_hLevel] * -1);
			
			++_hLevel;
		} //levelUp
		
		public function addTexture(bmp:BitmapData):void {
			if (bmp != null) {
				texture.push(bmp);
			}
		} //addTexture
		
		public function get rect():Rectangle {
			var ret:Rectangle = new Rectangle(x, y, width, height);
			return ret;
		} //rect
		
		public function changeTexture(i:int):void {
			tSel = i;
			
			tSel >= texture.length ? tSel = 0 : null;
			tSel < 0               ? tSel = 0 : null;
		} //changeTexture
		
		public function updateGraphics():void {			
			var transMatrix:Matrix = new Matrix(1, 0, 0, 1, xTextureOff, yTextureOff);
			
			this.bitmapData.fillRect(new Rectangle(0, 0, 64, 64), 0x00);
			textureMask.graphics.clear();
			textureMask.graphics.beginBitmapFill(texture[tSel], transMatrix);
			textureMask.graphics.drawCircle(32, 32, 32);
			textureMask.graphics.endFill();
			
			this.bitmapData.draw(textureMask, new Matrix(1,0,0,1,0,clipY));
		} //updateGraphics
		
		//----------------------------------------------------
		//  Water Hazards
		//----------------------------------------------------
		public function startSink():void {
			//Prevent rising and sinking from occuring at the same time
			if (riseTimer.running) {
				sinkTimer = new Timer(SINK_RATE, 32 - (riseTimer.currentCount * 4));
				riseTimer.stop();
				riseTimer.reset();
				
				riseTimer.removeEventListener(TimerEvent.TIMER, whileRising);
				riseTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, finishedRising);
			}
			
			//Begin the sinking process, add event listeners
			sinkTimer.start();
			_sinking = true;
			
			sinkTimer.addEventListener(TimerEvent.TIMER, whileSinking);
			sinkTimer.addEventListener(TimerEvent.TIMER_COMPLETE, finishedSinking);
		} //startSink
		
		public function endSink():void {
			//Do a quick rise 
			sunk     = false;
			_sinking = false;
			
			riseTimer = new Timer(SINK_RATE, (clipY / 16) + 1);
			riseTimer.addEventListener(TimerEvent.TIMER, whileRising);
			riseTimer.addEventListener(TimerEvent.TIMER_COMPLETE, finishedRising);
			riseTimer.start();
			
			sinkTimer.stop();
			sinkTimer.reset();
			sinkTimer.removeEventListener(TimerEvent.TIMER, whileSinking);
			sinkTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, finishedSinking);
		} //endSink
		
		private function whileRising(e:TimerEvent):void {
			clipY -= 16;
			clipY < 0 ? clipY = 0 : null; 
		} //whileRising
		
		private function finishedRising(e:TimerEvent):void {
			sinkTimer = new Timer(SINK_RATE, 32);
			
			riseTimer.removeEventListener(TimerEvent.TIMER, whileRising);
			riseTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, finishedRising);			
		} //finishedRising
		
		private function whileSinking(e:TimerEvent):void {
			clipY += 2;
			
			_momentumX > 0 ? _momentumX -= 0.5 : null;
			_momentumX < 0 ? _momentumX += 0.5 : null;
			
			_momentumY > 0 ? _momentumY -= 0.5 : null;
			_momentumY < 0 ? _momentumY += 0.5 : null;			
		} //whileSinking
		
		private function finishedSinking(e:TimerEvent):void {
			clipY = 64;
			sunk = true;
		} //finishedSinking
		
		//Havoc & Decay
		private function onDecay(e:TimerEvent):void {
			if (!_paused && Game.stats.havoc > 10) {
				if (sunk) {
					//-50 havoc
					Game.stats.addHavoc( -10);
				} else {
					//-5 havoc
					Game.stats.addHavoc( -1);
				}
			}
		}
		
		private function boostTick(e:TimerEvent):void {
			if (!_paused && (!boostHeld || _boostBar < 1.5)) {
				_boostBar += 1;
				_boostBar > 100 ? _boostBar = 100 : null;
			}			
		} //boostTick
		
		public function set paused(val:Boolean):void { _paused = val; } 
		
		//----------------------------------------------------
		//  'Bouncy' collides
		//----------------------------------------------------
		public function collideObj():void {
			_momentumX > 0 ? _momentumX -= 0.5 : _momentumX += 0.5;
			_momentumY > 0 ? _momentumY -= 0.5 : _momentumY += 0.5;
			
			Top.soundHandler.playSound(2);
		}
		
		public function collideX():void {
			_momentumX = -1 * (_momentumX * COLLIDE_BOUNCE);
		} //collideX
		
		public function collideY():void {
			_momentumY = -1 * (_momentumY * COLLIDE_BOUNCE);
		} //collideY
		
		//Damage related functions
		public function get damageY():int {
			var ret:int 
			if (canDamageY){
				if (_momentumY > MIN_MOMENTUM || _momentumY < (MIN_MOMENTUM * -1)) {
					ret = Math.abs(_momentumY * FORCE_SCALE);
				} else {
					ret = 0;
				}
				
				dmgTimer.start();
				canDamageY = false;				
			} else {
				ret = 0;
			}
			
			collideY(); 
			Top.soundHandler.playSound(1, (ret * 0.01) + 0.5);
			return ret;
		} //damageY
		
		public function get damageX():int {
			var ret:int 
			if(canDamageX){
				if (_momentumX >= MIN_MOMENTUM || _momentumX < (MIN_MOMENTUM * -1)) {
					ret = Math.abs(_momentumX * FORCE_SCALE);
				} else {
					ret = 0;
				}
				
				dmgTimer.start();
				canDamageX = false;
			} else {
				ret = 0;
			}
			
			collideX();
			Top.soundHandler.playSound(1, (ret * 0.01) + 0.5);
			return ret;
		} //damageX
		
		private function damageTick(e:TimerEvent):void {
			canDamageX = true;
			canDamageY = true;
		} //damageTick
		
		//----------------------------------------------------
		//  Movement
		//----------------------------------------------------
		public function applyMomentum(left:Boolean, right:Boolean, up:Boolean, down:Boolean, brake:Boolean, boost:Boolean, t:int):void {
			if (brake) {
				_momentumX -= _momentumX * (BRAKE_SPEED * t);
				_momentumY -= _momentumY * (BRAKE_SPEED * t);
			}
			
			if (left || right) {
				if (!(left && right)) {
					left  ? _momentumX -= ACCELERATION * t : null; 
					right ? _momentumX += ACCELERATION * t : null; 
					
					if(boost){
						//Consume boost here
						if(_boostBar > 2){
							left ? _momentumX -= ACCELERATION * t : _momentumX += ACCELERATION * t;
							_momentumX < (BOOST_CAP * -1)   ? _momentumX = BOOST_CAP * -1 : null;
							_momentumX > BOOST_CAP          ? _momentumX = BOOST_CAP      : null;						
						}					
					}
				}
			} else {
				//Decay
				if (_momentumX > 0) { _momentumX -= t * ACCELERATE_DECAY; _momentumX < 0 ? _momentumX = 0 : null; }
				else                { _momentumX += t * ACCELERATE_DECAY; _momentumX > 0 ? _momentumX = 0 : null; }
			}
			
			if (up || down) {
				if (!(up && down)) {
					up   ? _momentumY -= ACCELERATION * t : null; 
					down ? _momentumY += ACCELERATION * t : null; 
					
					if(boost){
						//Consume boost here
						if(_boostBar > 2){
							up ? _momentumY -= ACCELERATION * t : _momentumY += ACCELERATION * t;
							_momentumY < (BOOST_CAP * -1)   ? _momentumY = BOOST_CAP * -1 : null;
							_momentumY > BOOST_CAP          ? _momentumY = BOOST_CAP      : null;						
						} 					
					}
				}
			} else {
				//Decay
				if (_momentumY > 0) { _momentumY -= t * ACCELERATE_DECAY; _momentumY < 0 ? _momentumY = 0 : null; }
				else                { _momentumY += t * ACCELERATE_DECAY; _momentumY > 0 ? _momentumY = 0 : null; }				
			}
			
			if (boost) {
				boostHeld = true;
				_boostBar -= t * 0.02;
				_boostBar < 0 ? _boostBar = 0 : null;				
			} else {
				boostHeld = false;
			}
			
			if (_momentumX != 0 && (!boost || _boostBar < 2.5)) {
				_momentumX < (MOMENTUM_CAP * -1) ? _momentumX = MOMENTUM_CAP * -1 : null;
				_momentumX > MOMENTUM_CAP        ? _momentumX = MOMENTUM_CAP      : null;				
			}
			
			if (_momentumY != 0 && (!boost || _boostBar < 2.5)) {
				_momentumY < (MOMENTUM_CAP * -1) ? _momentumY = MOMENTUM_CAP * -1 : null;
				_momentumY > MOMENTUM_CAP        ? _momentumY = MOMENTUM_CAP      : null;				
			}
		} //applyMomentum
		
		//Movement
		public function move(t:int):void {
			lastX = this.x; lastY = this.y;
			lastOffX = xTextureOff;
			lastOffY = yTextureOff;
			
			if (sunk) {
				_momentumX < ((MOMENTUM_CAP * 0.25) * -1) ? _momentumX = (MOMENTUM_CAP * 0.25) * -1 : null;
				_momentumX > (MOMENTUM_CAP * 0.25)        ? _momentumX = (MOMENTUM_CAP * 0.25)      : null;	
				
				_momentumY < ((MOMENTUM_CAP * 0.25) * -1) ? _momentumY = (MOMENTUM_CAP * 0.25) * -1 : null;
				_momentumY > (MOMENTUM_CAP * 0.25)        ? _momentumY = (MOMENTUM_CAP * 0.25)      : null;					
			}
			
			this.x      += (TIME_MOVEMENT_SCALE * t) * momentumX;
			this.y      += (TIME_MOVEMENT_SCALE * t) * momentumY;
			xTextureOff += (TIME_MOVEMENT_SCALE * t) * momentumX;
			yTextureOff += (TIME_MOVEMENT_SCALE * t) * momentumY;
		} //move		
		
		public function get momentumX():Number { return _momentumX; }
		public function get momentumY():Number { return _momentumY; }
		public function get sinking():Boolean  { return _sinking;   } 
		public function get hLevel():int       { return _hLevel;    }
		public function get hLevelReq():int    { return HAVOC_LEVEL_REQ[_hLevel]; }
		public function get boostBar():Number  { return _boostBar;     }
	}

}