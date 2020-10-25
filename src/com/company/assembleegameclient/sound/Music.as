package com.company.assembleegameclient.sound {
    import com.company.assembleegameclient.parameters.Parameters;

    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.URLRequest;

    import kabam.rotmg.application.api.ApplicationSetup;
    import kabam.rotmg.core.StaticInjectorContext;

    public class Music {

        private static const MUSIC_URL:String = "https://dangergun.github.io/sfx/music/sorc%20prod.mp3";

        private static var music_:Sound = null;

        private static var musicVolumeTransform:SoundTransform;

        private static var musicChannel_:SoundChannel = null;

        private static var volume:Number = 0.3;

        public static function load():void {
            volume = Parameters.data.musicVolume;
            musicVolumeTransform = new SoundTransform(!!Parameters.data.playMusic ? volume : 0);
            if (Parameters.data.playMusic) {
                if (!music_) {
                    music_ = new Sound();
                    music_.load(new URLRequest("https://dangergun.github.io/sfx/music/sorc%20prod.mp3"));
                }
                musicChannel_ = music_.play(0, 0x7fffffff, musicVolumeTransform);
            }
        }

        public static function setPlayMusic(_arg_1:Boolean):void {
            Parameters.data.playMusic = _arg_1;
            Parameters.save();
            if (Parameters.data.playMusic) {
                if (!music_) {
                    music_ = new Sound();
                    music_.load(new URLRequest("https://dangergun.github.io/sfx/music/sorc%20prod.mp3"));
                }
                musicChannel_ = music_.play(0, 0x7fffffff, musicVolumeTransform);
            } else {
                musicChannel_.stop();
                music_.close();
            }
            musicVolumeTransform.volume = volume;
            musicChannel_.soundTransform = musicVolumeTransform;

        public static function setMusicVolume(_arg_1:Number):void {
            Parameters.data.musicVolume = _arg_1;
            Parameters.save();
            if (!Parameters.data.playMusic) {
                return;
            }
            if (musicVolumeTransform) {
                musicVolumeTransform.volume = _arg_1;
            } else {
                musicVolumeTransform = new SoundTransform(_arg_1);
            }
            musicChannel_.soundTransform = musicVolumeTransform;
        }

        public function Music() {
            super();
        }
    }
}
