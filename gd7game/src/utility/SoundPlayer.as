package utility {
	import flash.events.Event;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import resource.music.GameTrack;
	import resource.music.MenuTrack;
	import resource.sound.SoundBallDamage;
	import resource.sound.SoundBallObject;
	import resource.sound.SoundBuildCollapse;
	import resource.sound.SoundUIClick;

	public class SoundPlayer {
		public static const MENU_TRACK:int = 0;
		public static const GAME_TRACK:int = 1;
		
		private var musicFiles:Array;
		private var soundFiles:Array;
		
		private var activeChannel:SoundChannel;
		
		private var musicTrans:SoundTransform;
		private var soundTrans:Number;
		
		private var resumePos:int;
		private var activeTrack:int;
		
		public function SoundPlayer(m:Number, s:Number) {
			musicFiles = new Array();
			soundFiles = new Array();
			
			resumePos  = -1;
			
			musicTrans = new SoundTransform(m);
			soundTrans = s;
			
			//Import sound files
			var t0:MenuTrack = new MenuTrack();
			var t1:GameTrack = new GameTrack();
			
			var s0:SoundBuildCollapse = new SoundBuildCollapse();
			var s1:SoundBallDamage    = new SoundBallDamage();
			var s2:SoundBallObject    = new SoundBallObject();
			var s3:SoundUIClick       = new SoundUIClick();
			
			musicFiles.push(t0, t1);
			soundFiles.push(s0, s1, s2, s3);
		} //soundPlayer
		
		public function playMusic(i:int):void {
			resumePos     = -1;
			
			if (activeChannel != null) { //Cancel the other song before starting
				activeChannel.stop();
			}
				
			if (!Top.musicEnabled) {
				//Report error... TODO
				Top.musicEnabled ? activeTrack = i : null; 
			} else {
				//Insert a SoundTransform from top later.
				activeChannel = musicFiles[i].play(0, int.MAX_VALUE, musicTrans); //infinite repeat until stopped!
				activeTrack   = i;
			}
		} //playMusic
		
		public function playSound(i:int, vol:Number = 1):void {
			if (!Top.soundEnabled) {
				//Report error
			} else {
				
				var trans:SoundTransform = new SoundTransform(soundTrans * vol);
				soundFiles[i].play(0, 0, trans);
			}
		}
		
		public function adjustSoundVolume(n:Number):void {
			if (n > 1) { n = 1; } else if (n < 0) { n = 0; }
			
			soundTrans = n;
		} //adjustSoundVolume
		
		public function adjustMusicVolume(n:Number):void {
			if (n > 1) { n = 1; } else if (n < 0) { n = 0; }
			
			musicTrans.volume = n;
			if(resumePos == -1){
				var i:int = activeChannel.position;
				activeChannel.stop();
				
				activeChannel = musicFiles[activeTrack].play(i, int.MAX_VALUE, musicTrans);
			}
		}
		
		public function pause():void {
			if (activeChannel != null && resumePos == -1) {
				resumePos = activeChannel.position;
				activeChannel.stop();
			}
		}
		
		public function resume():void {
			if (resumePos >= 0) {
				activeChannel = musicFiles[activeTrack].play(resumePos, int.MAX_VALUE, musicTrans);
				resumePos     = -1;
			}
		}
		
		public function mute():void {
			if (activeChannel != null) {
				activeChannel.stop();
			}
		}
		
		public function unmute():void {
			activeChannel = musicFiles[activeTrack].play(0, int.MAX_VALUE, musicTrans);
		}
		
		public function get musicVolume():int { return musicTrans.volume * 100; }
		public function get soundVolume():int { return soundTrans * 100; }
	}

}