package com.company.assembleegameclient.appengine {
    import com.company.assembleegameclient.objects.ObjectLibrary;
    import com.company.assembleegameclient.objects.Player;

    import flash.events.Event;
    import flash.system.System;

    import io.decagames.rotmg.tos.popups.ToSPopup;
    import io.decagames.rotmg.ui.popups.signals.ShowPopupSignal;

    import kabam.rotmg.account.core.Account;
    import kabam.rotmg.core.StaticInjectorContext;
    import kabam.rotmg.promotions.model.BeginnersPackageModel;
    import kabam.rotmg.servers.api.LatLong;

    import org.swiftsuspenders.Injector;

    public class SavedCharactersList extends Event {

        public static const SAVED_CHARS_LIST:String = "SAVED_CHARS_LIST";
        public static const AVAILABLE:String = "available";
        public static const UNAVAILABLE:String = "unavailable";
        public static const UNRESTRICTED:String = "unrestricted";
        private static const DEFAULT_LATLONG:LatLong = new LatLong(37.4436, -122.412);
        private static const DEFAULT_SALESFORCE:String = "unavailable";

        public var accountId_:String;
        public var nextCharId_:int;
        public var maxNumChars_:int;
        public var numChars_:int = 0;
        public var savedChars_:Vector.<SavedCharacter>;
        public var charStats_:Object;
        public var totalFame_:int = 0;
        public var bestCharFame_:int = 0;
        public var fame_:int = 0;
        public var credits_:int = 0;
        public var tokens_:int = 0;
        public var numStars_:int = 0;
        public var nextCharSlotPrice_:int;
        public var guildName_:String;
        public var guildRank_:int;
        public var name_:String = null;
        public var nameChosen_:Boolean;
        public var converted_:Boolean;
        public var isAdmin_:Boolean;
        public var canMapEdit_:Boolean;
        public var news_:Vector.<SavedNewsItem>;
        public var myPos_:LatLong;
        public var salesForceData_:String = "unavailable";
        public var hasPlayerDied:Boolean = false;
        public var classAvailability:Object;
        public var isAgeVerified:Boolean;
        public var vaultItems:Vector.<Vector.<int>>;
        private var origData_:String;
        private var charsXML_:XML;
        private var account:Account;

        public function SavedCharactersList(_arg_1:String) {
            var _local5:* = undefined;
            var _local4:* = null;
            savedChars_ = new Vector.<SavedCharacter>();
            charStats_ = {};
            news_ = new Vector.<SavedNewsItem>();
            super("SAVED_CHARS_LIST");
            this.origData_ = _arg_1;
            this.charsXML_ = new XML(this.origData_);
            var _local3:XML = XML(this.charsXML_.Account);
            this.parseUserData(_local3);
            this.parseBeginnersPackageData(_local3);
            this.parseGuildData(_local3);
            this.parseCharacterData();
            this.parseCharacterStatsData();
            this.parseNewsData();
            this.parseGeoPositioningData();
            this.parseSalesForceData();
            this.reportUnlocked();
            var _local2:Injector = StaticInjectorContext.getInjector();
            if (_local2) {
                _local4 = _local2.getInstance(Account);
                _local4.reportIntStat("BestLevel", this.bestOverallLevel());
                _local4.reportIntStat("BestFame", this.bestOverallFame());
                _local4.reportIntStat("NumStars", this.numStars_);
                _local4.verify("VerifiedEmail" in _local3);
            }
            this.classAvailability = {};
            var _local7:int = 0;
            var _local6:* = this.charsXML_.ClassAvailabilityList.ClassAvailability;
            for each (_local5 in this.charsXML_.ClassAvailabilityList.ClassAvailability) {
                this.classAvailability[_local5.@id.toString()] = _local5.toString();
            }
        }

        override public function clone():Event {
            return new SavedCharactersList(this.origData_);
        }

        override public function toString():String {
            return "[ numChars: " + this.numChars_ + " maxNumChars: " + this.maxNumChars_ + " ]";
        }

        public function dispose():void {
            System.disposeXML(this.charsXML_);
        }

        public function getCharById(charId:int):SavedCharacter {
            var character:* = null;
            var default:int = 0;
            var charList:* = this.savedChars_;
            for each (character in this.savedChars_) {
                if (character.charId() == charId) {
                    return character;
                }
            }
            return null;
        }

        public function isFirstTimeLogin():Boolean {
            return false in this.charsXML_;
        }

        public function bestLevel(_arg_1:int):int {
            var charStats:CharacterStats = this.charStats_[_arg_1];
            return charStats == null ? 0 : charStats.bestLevel();
        }

        public function bestOverallLevel():int {
            var returnVar:int = 0;
            var character:* = null;
            var default:int = 0;
            var charStats:* = this.charStats_;
            for each (character in this.charStats_) {
                if (character.bestLevel() > _local1) {
                    returnVar = character.bestLevel();
                }
            }
            return returnVar;
        }

        public function bestFame(_arg_1:int):int {
            var _local2:CharacterStats = this.charStats_[_arg_1];
            return _local2 == null ? 0 : _local2.bestFame();
        }

        public function bestOverallFame():int {
            var _local1:int = 0;
            var _local2:* = null;
            var _local4:int = 0;
            var _local3:* = this.charStats_;
            for each (_local2 in this.charStats_) {
                if (_local2.bestFame() > _local1) {
                    _local1 = _local2.bestFame();
                }
            }
            return _local1;
        }

        public function levelRequirementsMet(_arg_1:int):Boolean {
            var _local3:int = 0;
            var _local4:* = null;
            var _local2:XML = ObjectLibrary.xmlLibrary_[_arg_1];
            var _local6:int = 0;
            var _local5:* = _local2.UnlockLevel;
            for each (_local4 in _local2.UnlockLevel) {
                _local3 = ObjectLibrary.idToType_[_local4.toString()];
                if (this.bestLevel(_local3) < int(_local4.@level)) {
                    return false;
                }
            }
            return true;
        }

        public function availableCharSlots():int {
            return this.maxNumChars_ - this.numChars_;
        }

        public function hasAvailableCharSlot():Boolean {
            return this.numChars_ < this.maxNumChars_;
        }

        public function newUnlocks(_arg_1:int, _arg_2:int):Array {
            var _local10:* = null;
            var _local7:int = 0;
            var _local6:Boolean = false;
            var _local9:Boolean = false;
            var _local3:* = null;
            var _local4:int = 0;
            var _local5:int = 0;
            var _local11:int = 0;
            var _local8:* = [];
            while (_local11 < ObjectLibrary.playerChars_.length) {
                _local10 = ObjectLibrary.playerChars_[_local11];
                _local7 = _local10.@type;
                if (!this.levelRequirementsMet(_local7)) {
                    _local6 = true;
                    _local9 = false;
                    var _local13:int = 0;
                    var _local12:* = _local10.UnlockLevel;
                    for each (_local3 in _local10.UnlockLevel) {
                        _local4 = ObjectLibrary.idToType_[_local3.toString()];
                        _local5 = _local3.@level;
                        if (this.bestLevel(_local4) < _local5) {
                            if (_local4 != _arg_1 || _local5 != _arg_2) {
                                _local6 = false;
                                break;
                            }
                            _local9 = true;
                        }
                    }
                    if (_local6 && _local9) {
                        _local8.push(_local7);
                    }
                }
                _local11++;
            }
            return _local8;
        }

        private function parseUserData(_arg_1:XML):void {
            this.accountId_ = _arg_1.AccountId;
            this.name_ = _arg_1.Name;
            this.nameChosen_ = "NameChosen" in _arg_1;
            this.converted_ = "Converted" in _arg_1;
            this.isAdmin_ = "Admin" in _arg_1;
            Player.isAdmin = this.isAdmin_;
            Player.isMod = "Mod" in _arg_1;
            this.canMapEdit_ = "MapEditor" in _arg_1;
            this.totalFame_ = _arg_1.Stats.TotalFame;
            this.bestCharFame_ = _arg_1.Stats.BestCharFame;
            this.fame_ = _arg_1.Stats.Fame;
            this.credits_ = _arg_1.Credits;
            this.tokens_ = _arg_1.FortuneToken;
            this.nextCharSlotPrice_ = _arg_1.NextCharSlotPrice;
            this.isAgeVerified = this.accountId_ != "" && _arg_1.IsAgeVerified == 1;
            this.hasPlayerDied = true;
        }

        private function parseBeginnersPackageData(_arg_1:XML):void {
            var _local3:int = 0;
            var _local2:BeginnersPackageModel = this.getBeginnerModel();
            if (_arg_1.hasOwnProperty("BeginnerPackageStatus")) {
                _local3 = _arg_1.BeginnerPackageStatus;
                _local2.status = _local3;
            } else {
                _local2.status = 0;
            }
        }

        private function getBeginnerModel():BeginnersPackageModel {
            var _local1:Injector = StaticInjectorContext.getInjector();
            return _local1.getInstance(BeginnersPackageModel);
        }

        private function parseGuildData(_arg_1:XML):void {
            var _local2:* = null;
            if ("Guild" in _arg_1) {
                _local2 = XML(_arg_1.Guild);
                this.guildName_ = _local2.Name;
                this.guildRank_ = _local2.Rank;
            }
        }

        private function parseCharacterData():void {
            var _local1:* = null;
            this.nextCharId_ = int(this.charsXML_.@nextCharId);
            this.maxNumChars_ = int(this.charsXML_.@maxNumChars);
            var _local3:int = 0;
            var _local2:* = this.charsXML_.Char;
            for each (_local1 in this.charsXML_.Char) {
                this.savedChars_.push(new SavedCharacter(_local1, this.name_));
                this.numChars_++;
            }
            this.savedChars_.sort(SavedCharacter.compare);
        }

        private function parseCharacterStatsData():void {
            var _local1:int = 0;
            var _local2:* = null;
            var _local3:* = null;
            var _local4:XML = XML(this.charsXML_.Account.Stats);
            var _local6:int = 0;
            var _local5:* = _local4.ClassStats;
            for each (_local2 in _local4.ClassStats) {
                _local1 = _local2.@objectType;
                _local3 = new CharacterStats(_local2);
                this.numStars_ = this.numStars_ + _local3.numStars();
                this.charStats_[_local1] = _local3;
            }
        }

        private function parseNewsData():void {
            var _local2:* = null;
            var _local1:XML = XML(this.charsXML_.News);
            var _local4:int = 0;
            var _local3:* = _local1.Item;
            for each (_local2 in _local1.Item) {
                this.news_.push(new SavedNewsItem(_local2.Icon, _local2.Title, _local2.TagLine, _local2.Link, _local2.Date));
            }
        }

        private function parseGeoPositioningData():void {
            if ("Lat" in this.charsXML_ && "Long" in this.charsXML_) {
                this.myPos_ = new LatLong(this.charsXML_.Lat, this.charsXML_.Long);
            } else {
                this.myPos_ = DEFAULT_LATLONG;
            }
        }

        private function parseSalesForceData():void {
            if ("SalesForce" in this.charsXML_ && "SalesForce" in this.charsXML_) {
                this.salesForceData_ = this.charsXML_.SalesForce;
            }
        }

        private function parseTOSPopup():void {
            if ("TOSPopup" in this.charsXML_) {
                StaticInjectorContext.getInjector().getInstance(ShowPopupSignal).dispatch(new ToSPopup());
            }
        }

        private function reportUnlocked():void {
            var _local1:Injector = StaticInjectorContext.getInjector();
            if (_local1) {
                this.account = _local1.getInstance(Account);
                this.account && this.updateAccount();
            }
        }

        private function updateAccount():void {
            var character:* = null;
            var charId:int = 0;
            var unlockedClasses:int = 0;
            var counter:int = 0;
            while (counter < ObjectLibrary.playerChars_.length) {
                character = ObjectLibrary.playerChars_[counter];
                charId = character.@type;
                if (this.levelRequirementsMet(charId)) {
                    this.account.reportIntStat(character.@id + "Unlocked", 1);
                    unlockedClasses++;
                }
                counter++;
            }
            this.account.reportIntStat("ClassesUnlocked", unlockedClasses);
        }
    }
}
