package com.company.assembleegameclient.sound {
    import com.company.assembleegameclient.parameters.Parameters;

    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.URLRequest;
    import flash.utils.Dictionary;

    import kabam.rotmg.application.api.ApplicationSetup;
    import kabam.rotmg.core.StaticInjectorContext;

    public class SoundEffectLibrary {

        private static const URL_PATTERN:String = "{URLBASE}/sfx/{NAME}.mp3";
        public static var nameMap_:Dictionary = new Dictionary();
        private static var urlBase:String;
        private static var activeSfxList_:Dictionary = new Dictionary(true);

        public static function load(_arg_1:String):Sound {
            var _local2:* = nameMap_[_arg_1] || makeSound(_arg_1);
            nameMap_[_arg_1] = _local2;
            return _local2;
        }

        public static function makeSound(_arg_1:String):Sound {
            var _local2:Sound = new Sound();
            _local2.addEventListener("ioError", onIOError);
            _local2.load(makeSoundRequest(_arg_1));
            return _local2;
        }

        public static function play(name:String, volumeMultiplier:Number = 1, isFX:Boolean = true):void {
            if (!Parameters.data.playSFX && isFX || !isFX && !Parameters.data.playPewPew)
                return;

            var _local8:* = null;
            var _local6:* = null;
            var _local5:Sound = load(name);
            var _local4:Number = Parameters.data.SFXVolume * volumeMultiplier;
            try {
                _local8 = new SoundTransform(_local4);
                _local6 = _local5.play(0, 0, _local8);
                _local6.addEventListener("soundComplete", onSoundComplete, false, 0, true);
                activeSfxList_[_local6] = _local4;

            } catch (error:Error) {

            }
        }

        public static function updateVolume(_arg_1:Number):void {
            var _local2:* = null;
            var _local3:* = null;
            var _local5:int = 0;
            var _local4:* = activeSfxList_;
            for each (_local2 in activeSfxList_) {
                activeSfxList_[_local2] = _arg_1;
                _local3 = _local2.soundTransform;
                _local3.volume = !!Parameters.data.playSFX ? activeSfxList_[_local2] : 0;
                _local2.soundTransform = _local3;
            }
        }

        public static function updateTransform():void {
            var _local2:* = null;
            var _local1:* = null;
            var _local4:int = 0;
            var _local3:* = activeSfxList_;
            for each (_local2 in activeSfxList_) {
                _local1 = _local2.soundTransform;
                _local1.volume = !!Parameters.data.playSFX ? activeSfxList_[_local2] : 0;
                _local2.soundTransform = _local1;
            }
        }

        private static function getUrlBase():String {
            return "https://dangergun.github.io";
        }

        private static function makeSoundRequest(_arg_1:String):URLRequest {
            urlBase = urlBase || getUrlBase();
            var _local2_:String = "{URLBASE}/sfx/{NAME}.mp3".replace("{URLBASE}", urlBase).replace("{NAME}", param1);
            return new URLRequest(_local2_);
        }

        public function SoundEffectLibrary() {
            super();
        }

        public static function onIOError(_arg_1:IOErrorEvent):void {
        }

        private static function onSoundComplete(_arg_1:Event):void {
            var _local2:SoundChannel = _arg_1.target as SoundChannel;
        }
    }
}
