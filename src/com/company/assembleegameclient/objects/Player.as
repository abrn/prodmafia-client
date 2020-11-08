package com.company.assembleegameclient.objects {
    import com.company.assembleegameclient.map.Camera;
    import com.company.assembleegameclient.map.Square;
    import com.company.assembleegameclient.map.mapoverlay.CharacterStatusText;
    import com.company.assembleegameclient.objects.particles.HealingEffect;
    import com.company.assembleegameclient.objects.particles.LevelUpEffect;
    import com.company.assembleegameclient.parameters.Parameters;
    import com.company.assembleegameclient.sound.SoundEffectLibrary;
    import com.company.assembleegameclient.util.AnimatedChar;
    import com.company.assembleegameclient.util.ConditionEffect;
    import com.company.assembleegameclient.util.FameUtil;
    import com.company.assembleegameclient.util.FreeList;
    import com.company.assembleegameclient.util.MaskedImage;
    import com.company.assembleegameclient.util.PlayerUtil;
    import com.company.assembleegameclient.util.TimeUtil;
    import com.company.assembleegameclient.util.TextureRedrawer;
    import com.company.assembleegameclient.util.redrawers.GlowRedrawer;
    import com.company.rotmg.graphics.StarGraphic;
    import com.company.util.CachingColorTransformer;
    import com.company.util.ConversionUtil;
    import com.company.util.IntPoint;
    import com.company.util.MoreColorUtil;
    import com.company.util.MoreStringUtil;
    import com.company.util.PointUtil;
    
    import flash.display.BitmapData;
    import flash.display.GraphicsBitmapFill;
    import flash.display.Sprite;
    import flash.filters.DropShadowFilter;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    
    import io.decagames.rotmg.supportCampaign.data.SupporterCampaignModel;
    
    import kabam.rotmg.assets.services.CharacterFactory;
    import kabam.rotmg.chat.model.ChatMessage;
    import kabam.rotmg.core.StaticInjectorContext;
    import kabam.rotmg.game.model.UseBuyPotionVO;
    import kabam.rotmg.game.signals.AddTextLineSignal;
    import kabam.rotmg.messaging.impl.incoming.Text;
    import kabam.rotmg.text.view.BitmapTextFactory;
    import kabam.rotmg.text.view.stringBuilder.StaticStringBuilder;
    import kabam.rotmg.text.view.stringBuilder.StringBuilder;
    
    import org.osflash.signals.Signal;
    import org.swiftsuspenders.Injector;
    
    public class Player extends Character {
        
        public static const MS_BETWEEN_TELEPORT: int = 10000;
        
        public static const MS_REALM_TELEPORT: int = 120000;
        
        private static const MOVE_THRESHOLD: Number = 0.4;
        
        private static const NEARBY: Vector.<Point> = new <Point>[new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(1, 1)];
        
        private static const RANK_STAR_BG_OFFSET_MATRIX: Matrix = new Matrix(0.8, 0, 0, 0.8, 0, 0);
        private const MIN_MOVE_SPEED: Number = 0.004;
        private const MAX_MOVE_SPEED: Number = 0.0096;
        private const DIF_MOVE_SPEED: Number = 0.0056;
        private const MIN_ATTACK_FREQ: Number = 0.0015;
        private const MAX_ATTACK_FREQ: Number = 0.008;
        private const DIF_ATTACK_FREQ: Number = 0.0065;
        private const MIN_ATTACK_MULT: Number = 0.5;
        private const MAX_ATTACK_MULT: Number = 2;
        private const DIF_ATTACK_MULT: Number = 1.5;
        private const DEFAULT_DROPSHADOW_FILTER: DropShadowFilter = new DropShadowFilter(0, 0, 0, 0.5, 6, 6, 1);
        private const lightBlueCT: ColorTransform = new ColorTransform(0.541176470588235, 0.596078431372549, 0.870588235294118);
        private const darkBlueCT: ColorTransform = new ColorTransform(0.192156862745098, 0.301960784313725, 0.858823529411765);
        private const redCT: ColorTransform = new ColorTransform(0.756862745098039, 0.152941176470588, 0.176470588235294);
        private const orangeCT: ColorTransform = new ColorTransform(0.968627450980392, 0.576470588235294, 0.117647058823529);
        private const yellowCT: ColorTransform = new ColorTransform(1, 1, 0);
        private const hpPotionVO: UseBuyPotionVO = new UseBuyPotionVO(2594, UseBuyPotionVO.CONTEXTBUY);
        private const mpPotionVO: UseBuyPotionVO = new UseBuyPotionVO(2595, UseBuyPotionVO.CONTEXTBUY);
        private const RANK_OFFSET_MATRIX: Matrix = new Matrix(1, 0, 0, 1, 2, 2);
        private const NAME_OFFSET_MATRIX: Matrix = new Matrix(1, 0, 0, 1, 20, 1);
        public static var isAdmin: Boolean = false;
        public static var isMod: Boolean = false;
        private static var newP: Point = new Point();
        
        public static function fromPlayerXML(_arg_1: String, _arg_2: XML): Player {
            var _local3: int = 0;
            var _local6: * = null;
            var _local7: Player = null;
            var _local5: * = _arg_1;
            var _local4: * = _arg_2;
            _local3 = _local4.ObjectType;
            try {
                _local6 = ObjectLibrary.xmlLibrary_[_local3];
                _local7 = new Player(_local6);
                _local7.name_ = _local5;
                _local7.level_ = _local4.Level;
                _local7.exp_ = _local4.Exp;
                _local7.equipment_ = ConversionUtil.toIntVector(_local4.Equipment);
                _local7.calculateStatBoosts();
                _local7.lockedSlot = new Vector.<int>(_local7.equipment_.length);
                _local7.maxHP_ = _local7.maxHPBoost_ + int(_local4.MaxHitPoints);
                _local7.hp_ = int(_local4.HitPoints);
                _local7.maxMP_ = _local7.maxMPBoost_ + int(_local4.MaxMagicPoints);
                _local7.mp_ = int(_local4.MagicPoints);
                _local7.attack_ = _local7.attackBoost_ + int(_local4.Attack);
                _local7.defense_ = _local7.defenseBoost_ + int(_local4.Defense);
                _local7.speed_ = _local7.speedBoost_ + int(_local4.Speed);
                _local7.dexterity_ = _local7.dexterityBoost_ + int(_local4.Dexterity);
                _local7.vitality_ = _local7.vitalityBoost_ + int(_local4.HpRegen);
                _local7.wisdom = _local7.wisdomBoost_ + int(_local4.MpRegen);
                _local7.tex1Id_ = _local4.hasOwnProperty("Tex1") ? int(_local4.Tex1) : 0;
                _local7.tex2Id_ = _local4.hasOwnProperty("Tex2") ? int(_local4.Tex2) : 0;
                _local7.hasBackpack_ = _local4.HasBackpack == "1";
            } catch (error: Error) {
                throw new Error("Type: 0x" + _local3.toString(16) + " doesn\'t exist. " + error.message);
            }
            return _local7;
        }

        public function Player(_arg_1: XML) {
            followPos = new Point(0, 0);
            followVec = new Point(0, 0);
            mousePos_ = new Point(0, 0);
            creditsWereChanged = new Signal();
            fameWasChanged = new Signal();
            supporterFlagWasChanged = new Signal();
            ip_ = new IntPoint();
            var _local2: Injector = StaticInjectorContext.getInjector();
            this.addTextLine = _local2.getInstance(AddTextLineSignal);
            this.factory = _local2.getInstance(CharacterFactory);
            this.supportCampaignModel = _local2.getInstance(SupporterCampaignModel);
            super(_arg_1);
            this.attackMax_ = int(_arg_1.Attack.@max);
            this.defenseMax_ = int(_arg_1.Defense.@max);
            this.speedMax_ = int(_arg_1.Speed.@max);
            this.dexterityMax_ = int(_arg_1.Dexterity.@max);
            this.vitalityMax_ = int(_arg_1.HpRegen.@max);
            this.wisdomMax_ = int(_arg_1.MpRegen.@max);
            this.maxHPMax_ = int(_arg_1.MaxHitPoints.@max);
            this.maxMPMax_ = int(_arg_1.MaxMagicPoints.@max);
            this.className = _arg_1.@id;
            this.texturingCache_ = new Dictionary();
            this.breathBarFillMatrix = new Matrix();
            this.breathBarBackFillMatrix = new Matrix();
        }
        public var isWalking: Boolean = false;
        public var projectileLifeMult: Number = 1.0;
        public var projectileSpeedMult: Number = 1.0;
        public var className: String;
        public var xpTimer: int;
        public var skinId: int;
        public var skin: AnimatedChar;
        public var isShooting: Boolean;
        public var accountId_: String = "";
        public var credits_: int = 0;
        public var tokens_: int = 0;
        public var numStars_: int = 0;
        public var starsBg_: int = 0;
        public var fame_: int = 0;
        public var nameChosen_: Boolean = false;
        public var currFame_: int = -1;
        public var nextClassQuestFame_: int = -1;
        public var legendaryRank_: int = -1;
        public var guildName_: String = null;
        public var guildRank_: int = -1;
        public var isFellowGuild_: Boolean = false;
        public var breath_: int = -1;
        public var maxMP_: int = 200;
        public var mp_: Number = 0;
        public var nextLevelExp_: int = 1000;
        public var exp_: int = 0;
        public var attack_: int = 0;
        public var speed_: int = 0;
        public var dexterity_: int = 0;
        public var vitality_: int = 0;
        public var wisdom: int = 0;
        public var mpZeroed_: Boolean = false;
        public var maxHPBoost_: int = 0;
        public var maxMPBoost_: int = 0;
        public var attackBoost_: int = 0;
        public var defenseBoost_: int = 0;
        public var speedBoost_: int = 0;
        public var vitalityBoost_: int = 0;
        public var wisdomBoost_: int = 0;
        public var dexterityBoost_: int = 0;
        public var xpBoost_: int = 0;
        public var healthPotionCount_: int = 0;
        public var magicPotionCount_: int = 0;
        public var attackMax_: int = 0;
        public var defenseMax_: int = 0;
        public var speedMax_: int = 0;
        public var dexterityMax_: int = 0;
        public var vitalityMax_: int = 0;
        public var wisdomMax_: int = 0;
        public var maxHPMax_: int = 0;
        public var maxMPMax_: int = 0;
        public var hasBackpack_: Boolean = false;
        public var supporterFlag: int = 0;
        public var starred_: Boolean = false;
        public var ignored_: Boolean = false;
        public var distSqFromThisPlayer_: Number = 0;
        public var relMoveVec_: Point = null;
        public var conMoveVec: Point = null;
        public var attackPeriod_: int = 0;
        public var nextAltAttack_: int = 0;
        public var nextTeleportAt_: int = 0;
        public var lastTpTime_: int = 0;
        public var dropBoost: int = 0;
        public var tierBoost: int = 0;
        public var isDefaultAnimatedChar: Boolean = true;
        public var projectileIdSetOverrideNew: String = "";
        public var projectileIdSetOverrideOld: String = "";
        public var addTextLine: AddTextLineSignal;
        public var fakeTex1: int = -1;
        public var fakeTex2: int = -1;
        public var followLanded: Boolean = false;
        public var hpLog: Number = 0;
        public var clientHp: int = 100;
        public var syncedChp: int;
        public var healBuffer: int = 0;
        public var healBufferTime: int = 0;
        public var autoNexusNumber: int = 0;
        public var requestHealNumber: int = 0;
        public var autoHpPotNumber: int = 0;
        public var autoHealNumber: int = 0;
        public var autoMpPotNumber: int = 0;
        public var autoMpPercentNumber: int = 0;
        public var lastHpPotTime: int = 0;
        public var lastMpPotTime: int = 0;
        public var ticksHPLastOff: int = 0;
        public var lastHealRequest: int = 0;
        public var checkStacks: Boolean = false;
        public var isJumping: Boolean = false;
        public var jumpStart: int = -1;
        public var jumpDist: Number = 0;
        public var jumpRot: Number = 0;
        public var petType: int;
        public var petSize: int;
        public var followPos: Point;
        public var followVec: Point;
        public var mousePos_: Point;
        public var creditsWereChanged: Signal;
        public var fameWasChanged: Signal;
        public var supporterFlagWasChanged: Signal;
        public var range: Number = -1;
        public var icMS: int = -1;
        protected var rotate_: Number = 0;
        protected var moveMultiplier_: Number = 1;
        protected var healingEffect_: HealingEffect = null;
        protected var nearestMerchant_: Merchant = null;
        protected var breathBarFillMatrix: Matrix;
        protected var breathBarBackFillMatrix: Matrix;
        private var prevWeaponId: int = -1;
        private var prevLifeMult: Number = -1;
        private var prevSpeedMult: Number = -1;
        private var famePortrait_: BitmapData = null;
        private var hallucinatingMaskedTex: MaskedImage;
        private var factory: CharacterFactory;
        private var supportCampaignModel: SupporterCampaignModel;
        private var breathBarBackFill: GraphicsBitmapFill = null;
        private var breathBarFill: GraphicsBitmapFill = null;
        private var lastAutoAbilityAttempt: int = 0;
        private var previousDamaging: Boolean = false;
        private var previousWeak: Boolean = false;
        private var previousBerserk: Boolean = false;
        private var previousDaze: Boolean = false;
        private var ip_: IntPoint;
        private var prevTime: int = -1;
        
        override public function moveTo(_arg_1: Number, _arg_2: Number): Boolean {
            var _local3: Boolean = super.moveTo(_arg_1, _arg_2);
            if (map_.gs_.isSafeMap) {
                this.nearestMerchant_ = this.getNearbyMerchant();
            }
            return _local3;
        }
        
        override public function updateStatuses(): void {
            var _local1: Boolean = false;
            if (this.map_.player_ == this) {
                this.isWeak = this.isWeak_();
                this.isSlowed = this.isSlowed_();
                this.isSick = this.isSick_();
                this.isDazed = this.isDazed_();
                this.isStunned = this.isStunned_();
                this.isBlind = this.isBlind_();
                this.isDrunk = this.isDrunk_();
                this.isBleeding = this.isBleeding_();
                this.isConfused = this.isConfused_();
                this.isParalyzed = this.isParalyzed_();
                this.isSpeedy = this.isSpeedy_();
                this.isNinjaSpeedy = this.isNinjaSpeedy_();
                this.isHallucinating = this.isHallucinating_();
                this.isDamaging = this.isDamaging_();
                this.isBerserk = this.isBerserk_();
                this.isUnstable = this.isUnstable_();
                this.isDarkness = this.isDarkness_();
                this.isSilenced = this.isSilenced_();
                this.isExposed = this.isExposed_();
                this.isQuiet = this.isQuiet_();
            }
            this.isInvisible = this.isInvisible_();
            this.isHealing = this.isHealing_();
            super.updateStatuses();
        }
        
        override public function update(param1: int, param2: int): Boolean {
            var _local6: Number = NaN;
            var _local15: Boolean = false;
            var _local8: * = null;
            var _local9: * = null;
            var _local14: * = null;
            var _local13: int = 0;
            var _local12: int = 0;
            var _local7: Number = NaN;
            if (this.map_.player_ == this) {
                var weaponId: int = this.equipment_[0];
                var wepDelta: Boolean = this.prevWeaponId != weaponId;
                var lifeMultDelta: Boolean = this.prevLifeMult != this.projectileLifeMult;
                var speedMultDelta: Boolean = this.prevSpeedMult != this.projectileSpeedMult;
                
                if (weaponId != -1) {
                    if (this.range == -1 || wepDelta || lifeMultDelta || speedMultDelta) {
                        var weaponXML: XML = ObjectLibrary.xmlLibrary_[weaponId];
                        this.range = (weaponXML.Projectile.LifetimeMS * this.projectileLifeMult
                                * weaponXML.Projectile.Speed * this.projectileSpeedMult) / 10000;
                        
                        if (wepDelta)
                            this.prevWeaponId = weaponId;
                        if (lifeMultDelta)
                            this.prevLifeMult = this.projectileLifeMult;
                        if (speedMultDelta)
                            this.prevSpeedMult = this.projectileSpeedMult;
                    }
                } else this.range = -1;
                
                if (this.isPaused) {
                    return true;
                }
                this.calcHealth(getTimer() - map_.gs_.lastUpdate_);
                if (this.checkHealth(param1)) {
                    return false;
                }
                if (this.icMS != -1 && TimeUtil.getTrueTime() - this.icMS >= this.icTime() * Parameters.data.timeScale) {
                    this.icMS = -1;
                }
                this.checkMana(param1);
                _local15 = false;
                if (followPos.x != 0 && followPos.y != 0) {
                    if (Parameters.followingName && Parameters.followName != "" && Parameters.followPlayer) {
                        if (this.followLanded) {
                            this.followVec.x = 0;
                            this.followVec.y = 0;
                            this.followLanded = false;
                        } else {
                            _local15 = true;
                            if (param1 - this.lastTpTime_ > Parameters.data.fameTpCdTime && getDistSquared(x_, y_, Parameters.followPlayer.tickPosition_.x, Parameters.followPlayer.tickPosition_.y) > Parameters.data.teleDistance) {
                                lastTpTime_ = param1;
                                teleToClosestPoint(followPos);
                            }
                            this.follow(this.followPos.x, this.followPos.y);
                        }
                    } else if (Parameters.fameBot) {
                        if (this.followLanded) {
                            this.followVec.x = 0;
                            this.followVec.y = 0;
                            this.followLanded = false;
                        } else {
                            _local15 = true;
                            this.follow(this.followPos.x, this.followPos.y);
                        }
                    }
                }
                if (Parameters.questFollow) {
                    if (this.followLanded) {
                        this.followVec.x = 0;
                        this.followVec.y = 0;
                        this.followLanded = false;
                    } else if (map_.quest_.objectId_ > 0) {
                        _local8 = map_.goDict_[map_.quest_.objectId_];
                        if (_local8) {
                            this.followPos.x = _local8.x_;
                            this.followPos.y = _local8.y_;
                        }
                        _local15 = true;
                        this.follow(this.followPos.x, this.followPos.y);
                    } else {
                        this.followPos.x = this.x_;
                        this.followPos.y = this.y_;
                        this.follow(this.followPos.x, this.followPos.y);
                    }
                } else if (Parameters.VHS == 2) {
                    if (false && this.isQuiet) {
                        this.follow(this.x_, this.y_);
                    } else if (this.followLanded || getDistSquared(x_, y_, followPos.x, followPos.y) <= 0.2) {
                        if (Parameters.VHSRecordLength > 0) {
                            if (Parameters.VHSIndex >= Parameters.VHSRecordLength) {
                                Parameters.VHSIndex = 0;
                            }
                            var _local18: Number = Parameters.VHSIndex;
                            Parameters.VHSIndex++;
                            Parameters.VHSNext = Parameters.VHSRecord[_local18];
                            this.followPos.x = Parameters.VHSNext.x;
                            this.followPos.y = Parameters.VHSNext.y;
                            this.followLanded = false;
                        }
                    } else {
                        _local15 = true;
                        this.follow(this.followPos.x, this.followPos.y);
                    }
                } else if (Parameters.VHS == 1) {
                    if (this.x_ != -1 && this.y_ != -1) {
                        if (Parameters.VHSRecord.length == 0) {
                            Parameters.VHSRecord.push(new Point(this.x_, this.y_));
                        } else {
                            _local9 = Parameters.VHSRecord[Parameters.VHSRecord.length - 1];
                            if (_local9.x != this.x_ || _local9.y != this.y_) {
                                _local6 = this.getDistSquared(this.x_, this.y_, _local9.x, _local9.y);
                                if (_local6 >= 1) {
                                    Parameters.VHSRecord.push(new Point(this.x_, this.y_));
                                }
                            }
                        }
                    }
                } else if (!(false && Parameters.giftChestLootMode == 1)) {
                    if (!(false && Parameters.giftChestLootMode == 2)) {
                        if (Parameters.bazaarJoining) {
                            if (this.map_.isNexus) {
                                _local14 = this.map_.findObject(1872);
                                if (_local14) {
                                    _local15 = true;
                                    _local6 = this.getDist(x_, y_, _local14.x_, _local14.y_);
                                    this.followPos.x = _local14.x_;
                                    if (Math.abs(_local14.y_ - this.y_) > 0.8 && (Math.abs(_local14.x_ - this.x_) < 0.5 || _local6 < Parameters.bazaarDist)) {
                                        this.followPos.y = _local14.y_;
                                    } else {
                                        this.followPos.y = this.y_;
                                    }
                                    this.follow(this.followPos.x, this.followPos.y);
                                    if (_local6 <= 1) {
                                        followLanded = true;
                                        _local15 = false;
                                        this.map_.gs_.gsc_.usePortal(_local14.objectId_);
                                    }
                                } else if (Parameters.bazaarLR == "left") {
                                    this.followPos.x = this.x_ - 2;
                                    this.followPos.y = this.y_;
                                    this.follow(-1, -1);
                                    _local15 = true;
                                } else if (Parameters.bazaarLR == "right") {
                                    this.followPos.x = this.x_ + 2;
                                    this.followPos.y = this.y_;
                                    this.follow(-1, -1);
                                    _local15 = true;
                                }
                            } else {
                                Parameters.bazaarJoining = false;
                            }
                        }
                    }
                }
                if (!_local15) {
                    this.followVec.x = 0;
                    this.followVec.y = 0;
                }
                if (!(map_.isVault && !Parameters.data.autoLootInVault) && !isPaused && Parameters.data.AutoLootOn) {
                    this.autoLoot(param1);
                }
                if (Parameters.swapINVandBP) {
                    if (this.hasBackpack_) {
                        if (map_.gs_.lastUpdate_ - map_.gs_.gsc_.lastInvSwapTime >= 500) {
                            while (Parameters.swapINVandBPcounter <= 8) {
                                _local13 = Parameters.swapINVandBPcounter + 4;
                                _local12 = Parameters.swapINVandBPcounter + 12;
                                _local18 = Parameters.swapINVandBPcounter;
                                Parameters.swapINVandBPcounter++;
                                if (_local18 >= 8) {
                                    Parameters.swapINVandBP = false;
                                    Parameters.swapINVandBPcounter = 0;
                                    break;
                                }
                                if (!(equipment_[_local13] == -1 && equipment_[_local12] == -1) && equipment_[_local13] != equipment_[_local12]) {
                                    map_.gs_.gsc_.invSwap(this, this, _local12, equipment_[_local12], this, _local13, equipment_[_local13]);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            var _local17: * = 0;
            var _local11: Number = NaN;
            var _local5: Number = NaN;
            var _local4: Vector3D = null;
            var _local10: Number = NaN;
            var _local3: int = 0;
            var _local16: Vector.<uint> = null;
            if (!this.isPaused) {
                if (!this.map_.gs_.isSafeMap) {
                    if (this.tierBoost) {
                        this.tierBoost = this.tierBoost - param2;
                        if (this.tierBoost < 0) {
                            this.tierBoost = 0;
                        }
                    }
                    if (this.dropBoost) {
                        this.dropBoost = this.dropBoost - param2;
                        if (this.dropBoost < 0) {
                            this.dropBoost = 0;
                        }
                    }
                }
                if (this.xpTimer) {
                    this.xpTimer = this.xpTimer - param2;
                    if (this.xpTimer < 0) {
                        this.xpTimer = 0;
                    }
                }
                if (this.isHealing && !Parameters.data.noParticlesMaster) {
                    if (this.healingEffect_ == null) {
                        this.healingEffect_ = new HealingEffect(this);
                        this.map_.addObj(this.healingEffect_, x_, y_);
                    }
                }
            }
            if (this.healingEffect_) {
                this.map_.removeObj(this.healingEffect_.objectId_);
                this.healingEffect_ = null;
            }
            if (this.relMoveVec_) {
                _local17 = Number(Parameters.data.cameraAngle);
                if (this.rotate_ != 0) {
                    _local17 = Number(_local17 + param2 * Parameters.PLAYER_ROTATE_SPEED * this.rotate_);
                    Parameters.data.cameraAngle = _local17;
                }
                if (this.relMoveVec_.x != 0 || this.relMoveVec_.y != 0) {
                    if (_local15) {
                        _local15 = false;
                    }
                    _local11 = this.getMoveSpeed();
                    _local5 = Math.atan2(this.relMoveVec_.y, this.relMoveVec_.x);
                    if (this.square.props_.slideAmount_ > 0 && !Parameters.data.ignoreIce) {
                        _local4 = new Vector3D();
                        _local4.x = _local11 * Math.cos(_local17 + _local5);
                        _local4.y = _local11 * Math.sin(_local17 + _local5);
                        _local4.z = 0;
                        _local10 = _local4.length;
                        _local4.scaleBy(-(this.square.props_.slideAmount_ - 1));
                        this.moveVec_.scaleBy(this.square.props_.slideAmount_);
                        if (this.moveVec_.length < _local10) {
                            this.moveVec_ = this.moveVec_.add(_local4);
                        }
                    } else {
                        this.moveVec_.x = _local11 * Math.cos(_local17 + _local5);
                        this.moveVec_.y = _local11 * Math.sin(_local17 + _local5);
                    }
                } else if (this.conMoveVec && (this.conMoveVec.x != 0 || this.conMoveVec.y != 0)) {
                    _local11 = this.getMoveSpeed();
                    _local7 = PointUtil.distanceXY(0, 0, this.conMoveVec.x, this.conMoveVec.y);
                    if (_local7 < 1) {
                        _local11 = _local11 * _local7;
                    }
                    _local5 = -Math.atan2(this.conMoveVec.y, this.conMoveVec.x);
                    if (this.square.props_.slideAmount_ > 0 && !Parameters.data.ignoreIce) {
                        _local4 = new Vector3D();
                        _local4.x = _local11 * Math.cos(_local17 + _local5);
                        _local4.y = _local11 * Math.sin(_local17 + _local5);
                        _local4.z = 0;
                        _local10 = _local4.length;
                        _local4.scaleBy(-(this.square.props_.slideAmount_ - 1));
                        this.moveVec_.scaleBy(this.square.props_.slideAmount_);
                        if (this.moveVec_.length < _local10) {
                            this.moveVec_ = this.moveVec_.add(_local4);
                        }
                    } else {
                        this.moveVec_.x = _local11 * Math.cos(_local17 + _local5);
                        this.moveVec_.y = _local11 * Math.sin(_local17 + _local5);
                    }
                } else if (_local15 && this.followPos && this.followVec.x != 0 || this.followVec.y != 0) {
                    _local11 = this.getMoveSpeed();
                    _local5 = Math.atan2(this.followVec.y, this.followVec.x);
                    if (this.square.props_.slideAmount_ > 0 && !Parameters.data.ignoreIce) {
                        _local4 = new Vector3D();
                        _local4.x = _local11 * Math.cos(_local5);
                        _local4.y = _local11 * Math.sin(_local5);
                        _local4.z = 0;
                        _local10 = _local4.length;
                        _local4.scaleBy(-(this.square.props_.slideAmount_ - 1));
                        this.moveVec_.scaleBy(this.square.props_.slideAmount_);
                        if (this.moveVec_.length < _local10) {
                            this.moveVec_ = this.moveVec_.add(_local4);
                        }
                    } else {
                        this.moveVec_.x = _local11 * Math.cos(_local5);
                        this.moveVec_.y = _local11 * Math.sin(_local5);
                    }
                } else if (!Parameters.data.ignoreIce && this.moveVec_.length > 0.00012 && this.square.props_.slideAmount_ > 0) {
                    this.moveVec_.scaleBy(this.square.props_.slideAmount_);
                } else {
                    this.moveVec_.x = 0;
                    this.moveVec_.y = 0;
                }
                if (this.square && this.square.props_.push_ && !Parameters.data.ignoreIce) {
                    this.moveVec_.x = this.moveVec_.x - this.square.props_.animate_.dx_ * 0.001;
                    this.moveVec_.y = this.moveVec_.y - this.square.props_.animate_.dy_ * 0.001;
                }
                if (_local15) {
                    this.walkTo_follow(this.x_ + param2 * this.moveVec_.x, this.y_ + param2 * this.moveVec_.y);
                } else {
                    this.walkTo(this.x_ + param2 * this.moveVec_.x, this.y_ + param2 * this.moveVec_.y);
                }
            } else if (!super.update(param1, param2)) {
                return false;
            }
            if (this.map_.player_ == this) {
                if (this.square.props_.maxDamage_ > 0 && this.square.lastDamage_ + 500 < param1 && !this.isInvincible && (square.obj_ == null || !this.square.obj_.props_.protectFromGroundDamage_)) {
                    _local3 = map_.gs_.gsc_.getNextDamage(this.square.props_.minDamage_, this.square.props_.maxDamage_);
                    if (this.subtractDamage(_local3, param1)) {
                        return false;
                    }
                    _local16 = new <uint>[ConditionEffect.GROUND_DAMAGE];
                    damage(true, _local3, _local16, hp_ <= _local3, null);
                    this.map_.gs_.gsc_.groundDamage(param1, x_, y_);
                    this.square.lastDamage_ = param1;
                }
            }
            return true;
        }
        
        override protected function makeNameBitmapData(): BitmapData {
            var _local3: StringBuilder = new StaticStringBuilder(name_);
            var _local1: BitmapTextFactory = StaticInjectorContext.getInjector().getInstance(BitmapTextFactory);
            var _local2: BitmapData = _local1.make(_local3, 16, this.getNameColor(), true, NAME_OFFSET_MATRIX, true);
            _local2.draw(FameUtil.numStarsToIcon(this.numStars_, this.starsBg_), RANK_STAR_BG_OFFSET_MATRIX);
            return _local2;
        }
        
        override public function draw(_arg_1: Vector.<GraphicsBitmapFill>, _arg_2: Camera, _arg_3: int): void {
            if (this != map_.player_
                    && !this.starred_
                    && (Parameters.lowCPUMode || Parameters.data.hideLockList))
                return;
            
            super.draw(_arg_1, _arg_2, _arg_3);
            if (this != map_.player_) {
                if (!Parameters.data.alphaOnOthers || this.starred_) {
                    drawName(_arg_1, _arg_2, false);
                }
            } else if (this.breath_ >= 0) {
                this.drawBreathBar(_arg_1, _arg_3);
            }
        }
        
        override protected function getTexture(_arg_1: Camera, _arg_2: int): BitmapData {
            var _local4: int = 0;
            var _local9: Number = NaN;
            var _local10: Number = NaN;
            var _local13: int = 0;
            var _local11: * = null;
            var _local5: * = null;
            var _local8: * = null;
            var _local7: * = null;
            if (this.isShooting || _arg_2 < attackStart_ + this.attackPeriod_) {
                facing_ = attackAngle_;
                _local10 = (_arg_2 - attackStart_) % this.attackPeriod_ / this.attackPeriod_;
                _local13 = 2;
            } else if (moveVec_.x != 0 || moveVec_.y != 0) {
                _local4 = 3.5 / this.getMoveSpeed();
                if (moveVec_.y != 0 || moveVec_.x != 0) {
                    facing_ = Math.atan2(moveVec_.y, moveVec_.x);
                }
                _local10 = _arg_2 % _local4 / _local4;
                _local13 = 1;
            }
            if (this.isHexed()) {
                this.isDefaultAnimatedChar && this.setToRandomAnimatedCharacter();
            } else if (!this.isDefaultAnimatedChar) {
                this.makeSkinTexture();
            }
            if (_arg_1.isHallucinating_) {
                _local5 = new MaskedImage(getHallucinatingTexture(), null);
            } else {
                _local5 = animatedChar_.imageFromFacing(facing_, _arg_1, _local13, _local10);
            }
            var _local3: int = tex1Id_;
            var _local6: int = tex2Id_;
            if (fakeTex1 != -1) {
                _local3 = fakeTex1;
            }
            if (fakeTex2 != -1) {
                _local6 = fakeTex2;
            }
            if (this.nearestMerchant_) {
                _local8 = texturingCache_[this.nearestMerchant_];
                if (_local8 == null) {
                    texturingCache_[this.nearestMerchant_] = new Dictionary();
                } else {
                    _local11 = _local8[_local5];
                }
                _local3 = this.nearestMerchant_.getTex1Id(tex1Id_);
                _local6 = this.nearestMerchant_.getTex2Id(tex2Id_);
            } else {
                _local11 = texturingCache_[_local5];
            }
            if (_local11 == null) {
                _local11 = TextureRedrawer.resize(_local5.image_, _local5.mask_, size_, false, _local3, _local6);
                if (this.nearestMerchant_ != null) {
                    texturingCache_[this.nearestMerchant_][_local5] = _local11;
                } else {
                    texturingCache_[_local5] = _local11;
                }
            }
            if (hp_ < maxHP_ * 0.2) {
                _local9 = Math.abs(Math.sin(_arg_2 * 0.005)) * 10 * 0.1;
                _local7 = new ColorTransform(1, 1, 1, 1, _local9 * 128, -_local9 * 128, -_local9 * 128);
                _local11 = CachingColorTransformer.transformBitmapData(_local11, _local7);
            }
            var _local12: BitmapData = texturingCache_[_local11];
            if (_local12 == null) {
                if (this == this.map_.player_) {
                    if (Parameters.VHS == 1) {
                        _local12 = GlowRedrawer.outlineGlow(_local11, 0xff00);
                    } else if (Parameters.VHS == 2) {
                        _local12 = GlowRedrawer.outlineGlow(_local11, 0xffdd00);
                    } else if (this.hasSupporterFeature(1)) {
                        _local12 = GlowRedrawer.outlineGlow(_local11, 0xcc66ff, 1.4, false, true);
                    } else {
                        _local12 = GlowRedrawer.outlineGlow(_local11, this.legendaryRank_ == -1 ? 0 : 16711680);
                    }
                } else if (this.hasSupporterFeature(1)) {
                    _local12 = GlowRedrawer.outlineGlow(_local11, 0xcc66ff, 1.4, false, true);
                } else {
                    _local12 = GlowRedrawer.outlineGlow(_local11, this.legendaryRank_ == -1 ? 0 : 16711680);
                }
                texturingCache_[_local11] = _local12;
            }
            if (Parameters.data.alphaOnOthers && (this.objectId_ != map_.player_.objectId_ && (!this.starred_ || this.isFellowGuild_ && Parameters.data.showAOGuildies))) {
                _local12 = CachingColorTransformer.alphaBitmapData(_local12, Parameters.data.alphaMan);
            } else if (this.isPaused || this.isStasis || this.isPetrified) {
                _local12 = CachingColorTransformer.filterBitmapData(_local12, PAUSED_FILTER);
            } else if (this.isInvisible) {
                _local12 = CachingColorTransformer.alphaBitmapData(_local12, 0.4);
            }
            return _local12;
        }
        
        override public function getPortrait(): BitmapData {
            var _local1: * = null;
            var _local2: int = 0;
            if (portrait_ == null) {
                _local1 = animatedChar_.imageFromDir(0, 0, 0);
                _local2 = 4 / _local1.image_.width * 100;
                portrait_ = TextureRedrawer.resize(_local1.image_, _local1.mask_, _local2, true, tex1Id_, tex2Id_);
                portrait_ = GlowRedrawer.outlineGlow(portrait_, 0);
            }
            return portrait_;
        }
        
        override public function setAttack(_arg_1: int, _arg_2: Number): void {
            var _local4: XML = ObjectLibrary.xmlLibrary_[_arg_1];
            if (_local4 == null || !("RateOfFire" in _local4)) {
                return;
            }
            var _local3: Number = _local4.RateOfFire;
            this.attackPeriod_ = 1 / this.attackFrequency() * (1 / _local3);
            super.setAttack(_arg_1, _arg_2);
        }
        
        override public function removeFromMap(): void {
            if (Parameters.followingName && Parameters.data.followIntoPortals && this.name_.toUpperCase() == Parameters.followName) {
                for each(var _local1: GameObject in map_.goDict_) {
                    if (_local1 is Portal && this.getDistSquared(x_, y_, _local1.x_, _local1.y_) <= 1) {
                        this.map_.gs_.gsc_.usePortal(_local1.objectId_);
                        break;
                    }
                }
            }
            if (Parameters.followPlayer && objectId_ == Parameters.followPlayer.objectId_) {
                Parameters.followPlayer = null;
            }
            super.removeFromMap();
        }
        
        public function getDistFromSelf(param1: Number, param2: Number): Number {
            var _local3: Number = param1 - this.x_;
            var _local4: Number = param2 - this.y_;
            return Math.sqrt(_local4 * _local4 + _local3 * _local3);
        }
        
        public function getFameBonus(): int {
            var _local1: int = 0;
            var _local3: * = null;
            var _local4: int = 0;
            var _local2: int = 0;
            while (_local2 < 4) {
                if (equipment_ && equipment_.length > _local2) {
                    _local1 = equipment_[_local2];
                    if (_local1 != -1) {
                        _local3 = ObjectLibrary.xmlLibrary_[_local1];
                        if (_local3 != null && _local3.hasOwnProperty("FameBonus")) {
                            _local4 = _local4 + _local3.FameBonus;
                        }
                    }
                }
                _local2++;
            }
            return _local4;
        }
        
        public function calculateStatBoosts(): void {
            var _local1: int = 0;
            var _local6: * = null;
            var _local5: * = null;
            var _local4: int = 0;
            var _local3: int = 0;
            var _local2: int = 0;
            this.maxHPBoost_ = 0;
            this.maxMPBoost_ = 0;
            this.attackBoost_ = 0;
            this.defenseBoost_ = 0;
            this.speedBoost_ = 0;
            this.vitalityBoost_ = 0;
            this.wisdomBoost_ = 0;
            this.dexterityBoost_ = 0;
            //TODO: add exaltations here
            while (_local2 < 4) {
                if (equipment_ && equipment_.length > _local2) {
                    _local1 = equipment_[_local2];
                    if (_local1 != -1) {
                        _local6 = ObjectLibrary.xmlLibrary_[_local1];
                        if (_local6 != null && _local6.hasOwnProperty("ActivateOnEquip")) {
                            var _local9: int = 0;
                            var _local8: * = _local6.ActivateOnEquip;
                            for each(_local5 in _local6.ActivateOnEquip) {
                                if (_local5.toString() == "IncrementStat") {
                                    _local4 = _local5.@stat;
                                    _local3 = _local5.@amount;
                                    var _local7: * = _local4;
                                    switch (_local7) {
                                        case 0:
                                            this.maxHPBoost_ = this.maxHPBoost_ + _local3;
                                            continue;
                                        case 3:
                                            this.maxMPBoost_ = this.maxMPBoost_ + _local3;
                                            continue;
                                        case 20:
                                            this.attackBoost_ = this.attackBoost_ + _local3;
                                            continue;
                                        case 21:
                                            this.defenseBoost_ = this.defenseBoost_ + _local3;
                                            continue;
                                        case 22:
                                            this.speedBoost_ = this.speedBoost_ + _local3;
                                            continue;
                                        case 26:
                                            this.vitalityBoost_ = this.vitalityBoost_ + _local3;
                                            continue;
                                        case 27:
                                            this.wisdomBoost_ = this.wisdomBoost_ + _local3;
                                            continue;
                                        case 28:
                                            this.dexterityBoost_ = this.dexterityBoost_ + _local3;
                                            continue;
                                        default:
                                        
                                    }
                                } else {
                                
                                }
                            }
                        }
                    }
                }
                _local2++;
            }
        }
        
        public function setRelativeMovement(_arg_1: Number, _arg_2: Number, _arg_3: Number): void {
            var _local4: Number = NaN;
            this.rotate_ = _arg_1;
            if (!this.relMoveVec_)
                this.relMoveVec_ = new Point();
            this.relMoveVec_.x = _arg_2;
            this.relMoveVec_.y = _arg_3;
            if (this.isConfused) {
                _local4 = this.relMoveVec_.x;
                this.relMoveVec_.x = -this.relMoveVec_.y;
                this.relMoveVec_.y = -_local4;
                this.rotate_ = -this.rotate_;
            }
        }
        
        public function setControllerMovementXY(_arg_1: Number, _arg_2: Number): void {
            if (!this.conMoveVec)
                this.conMoveVec = new Point();
            this.conMoveVec.x = _arg_1;
            this.conMoveVec.y = _arg_2;
        }
        
        public function setControllerMovementV3D(_arg_1: Vector3D): void {
            if (!this.conMoveVec)
                this.conMoveVec = new Point();
            this.conMoveVec.x = _arg_1.x;
            this.conMoveVec.y = _arg_1.y;
        }
        
        public function setCredits(_arg_1: int): void {
            this.credits_ = _arg_1;
            this.creditsWereChanged.dispatch();
        }
        
        public function setFame(_arg_1: int): void {
            this.fame_ = _arg_1;
            this.fameWasChanged.dispatch();
        }
        
        public function setSupporterFlag(_arg_1: int): void {
            this.supporterFlag = _arg_1;
            this.supporterFlagWasChanged.dispatch();
        }
        
        public function hasSupporterFeature(_arg_1: int): Boolean {
            return (this.supporterFlag & _arg_1) == _arg_1;
        }
        
        public function setTokens(_arg_1: int): void {
            this.tokens_ = _arg_1;
        }
        
        public function setGuildName(_arg_1: String): void {
            var _local5: * = null;
            var _local4: * = null;
            var _local3: Boolean = false;
            this.guildName_ = _arg_1;
            var _local2: Player = map_.player_;
            if (_local2 == this) {
                var _local7: int = 0;
                var _local6: * = map_.goDict_;
                for each(_local5 in map_.goDict_) {
                    _local4 = _local5 as Player;
                    if (_local4 != null && _local4 != this) {
                        _local4.setGuildName(_local4.guildName_);
                    }
                }
            } else {
                _local3 = _local2 && _local2.guildName_ && _local2.guildName_ != "" && _local2.guildName_ == this.guildName_;
                if (_local3 != this.isFellowGuild_) {
                    this.isFellowGuild_ = _local3;
                    nameBitmapData_ = null;
                }
            }
        }
        
        public function isTeleportEligible(_arg_1: Player): Boolean {
            return !(_arg_1.dead_ || _arg_1.isPaused || _arg_1.isInvisible);
        }
        
        public function msUtilTeleport(): int {
            var _local1: int = getTimer();
            return Math.max(0, this.nextTeleportAt_ - _local1);
        }
        
        public function teleportTo(_arg_1: Player): Boolean {
            map_.gs_.gsc_.teleport(_arg_1.objectId_);
            return true;
        }
        
        public function levelUpEffect(_arg_1: String, _arg_2: Boolean = true): void {
            if (_arg_2 && !Parameters.data.noParticlesMaster) {
                this.levelUpParticleEffect();
            }
            var _local3: CharacterStatusText = new CharacterStatusText(this, 0xff00, 2000);
            _local3.setText(_arg_1);
            map_.mapOverlay_.addStatusText(_local3);
        }
        
        public function handleLevelUp(_arg_1: Boolean): void {
            SoundEffectLibrary.play("level_up");
            if (_arg_1) {
                this.levelUpEffect("New Class Unlocked!", false);
                this.levelUpEffect("Level Up!");
            } else {
                this.levelUpEffect("Level Up!");
            }
            if (this == this.map_.player_) {
                this.clientHp = this.maxHP_;
            }
        }
        
        public function levelUpParticleEffect(_arg_1: uint = 4278255360): void {
            map_.addObj(new LevelUpEffect(this, _arg_1, 20), x_, y_);
        }
        
        public function handleExpUp(_arg_1: int): void {
            if (level_ == 20 && !bForceExp()) {
                return;
            }
            var _local2: CharacterStatusText = new CharacterStatusText(this, 0xff00, 1000);
            _local2.setText("+" + _arg_1 + " EXP");
            map_.mapOverlay_.addStatusText(_local2);
        }
        
        public function updateFame(_arg_1: int): void {
            var _local2: CharacterStatusText = new CharacterStatusText(this, 14835456, 2000);
            _local2.setText("+" + _arg_1 + " Fame");
            map_.mapOverlay_.addStatusText(_local2);
        }
        
        public function walkTo(currentX: Number, currentY: Number): Boolean {
            this.modifyMove(currentX, currentY, newP);
            return this.moveTo(newP.x, newP.y);
        }
        
        public function walkTo_follow(currentX: Number, currentY: Number): Boolean {
            var playerDistX: Number = NaN;
            var playerDistY: Number = NaN;
            var distanceX: Number = NaN;
            var distanceY: Number = NaN;
            
            this.modifyMove(currentX, currentY, newP);
            if (Parameters.followingName || Parameters.VHS == 2 || Parameters.fameBot || Parameters.questFollow) {
                if (!this.followLanded && isValidPosition(this.followPos.x, this.followPos.y)) {
                    playerDistX = Math.abs(this.x_ - this.followPos.x);
                    playerDistY = Math.abs(this.y_ - this.followPos.y);
                    distanceX = Math.abs(this.x_ - newP.x);
                    distanceY = Math.abs(this.y_ - newP.y);
                    if (distanceX >= playerDistX && distanceY >= playerDistY) {
                        newP.x = followPos.x;
                        newP.y = followPos.y;
                        this.followLanded = true;
                    }
                }
            }
            return this.moveTo(newP.x, newP.y);
        }
        
        public function modifyMove(currentX: Number, currentY: Number, newPoint: Point): void {
            var _local7: Boolean = false;
            if (this.isParalyzed || this.isPetrified) {
                newPoint.x = x_;
                newPoint.y = y_;
                return;
            }
            var _local6: Number = currentX - x_;
            var _local5: Number = currentY - y_;
            if (_local6 < 0.4 && _local6 > -0.4 && _local5 < 0.4 && _local5 > -0.4) {
                this.modifyStep(currentX, currentY, newPoint);
                return;
            }
            var _local4: Number = 0.4 / Math.max(Math.abs(_local6), Math.abs(_local5));
            var _local8: * = 0;
            newPoint.x = x_;
            newPoint.y = y_;
            while (!_local7) {
                if (_local8 + _local4 >= 1) {
                    _local4 = 1 - _local8;
                    _local7 = true;
                }
                this.modifyStep(newPoint.x + _local6 * _local4, newPoint.y + _local5 * _local4, newPoint);
                _local8 = Number(_local8 + _local4);
            }
        }
        
        public function modifyStep(currentX: Number, currentY: Number, newPoint: Point): void {
            var _local4: Number = NaN;
            var _local9: Number = NaN;
            var _local6: Boolean = x_ % 0.5 == 0 && currentX != x_ || int(x_ / 0.5) != int(currentX / 0.5);
            var _local5: Boolean = y_ % 0.5 == 0 && currentY != y_ || int(y_ / 0.5) != int(currentY / 0.5);
            
            if (!_local6 && !_local5 || this.isValidPosition(currentX, currentY)) {
                newPoint.x = currentX;
                newPoint.y = currentY;
                return;
            }
            if (_local6) {
                _local4 = currentX > x_ ? int(currentX * 2) / 2 : Number(int(x_ * 2) / 2);
                if (int(_local4) > int(x_)) {
                    _local4 = _local4 - 0.01;
                }
            }
            if (_local5) {
                _local9 = currentY > y_ ? int(currentY * 2) / 2 : Number(int(y_ * 2) / 2);
                if (int(_local9) > int(y_)) {
                    _local9 = _local9 - 0.01;
                }
            }
            if (!_local6) {
                newPoint.x = currentX;
                newPoint.y = _local9;
                if (square != null && square.props_.slideAmount_ != 0) {
                    this.resetMoveVector(false);
                }
                return;
            }
            if (!_local5) {
                newPoint.x = _local4;
                newPoint.y = currentY;
                if (square != null && square.props_.slideAmount_ != 0) {
                    this.resetMoveVector(true);
                }
                return;
            }
            var _local8: Number = currentX > x_ ? currentX - _local4 : Number(_local4 - currentX);
            var _local7: Number = currentY > y_ ? currentY - _local9 : Number(_local9 - currentY);
            if (_local8 > _local7) {
                if (this.isValidPosition(currentX, _local9)) {
                    newPoint.x = currentX;
                    newPoint.y = _local9;
                    return;
                }
                if (this.isValidPosition(_local4, currentY)) {
                    newPoint.x = _local4;
                    newPoint.y = currentY;
                    return;
                }
            } else {
                if (this.isValidPosition(_local4, currentY)) {
                    newPoint.x = _local4;
                    newPoint.y = currentY;
                    return;
                }
                if (this.isValidPosition(currentX, _local9)) {
                    newPoint.x = currentX;
                    newPoint.y = _local9;
                    return;
                }
            }
            newPoint.x = _local4;
            newPoint.y = _local9;
        }
        
        public function isValidPosition(_arg_1: Number, _arg_2: Number): Boolean {
            if (Parameters.data.noClip) {
                return true;
            }
            var _local5: Square = map_.getSquare(_arg_1, _arg_2);
            if (square != _local5 && (_local5 == null || !_local5.isWalkable())) {
                return false;
            }
            var _local4: Number = _arg_1 - int(_arg_1);
            var _local3: Number = _arg_2 - int(_arg_2);
            if (_local4 < 0.5) {
                if (this.isFullOccupy(_arg_1 - 1, _arg_2)) {
                    return false;
                }
                if (_local3 < 0.5) {
                    if (this.isFullOccupy(_arg_1, _arg_2 - 1) || this.isFullOccupy(_arg_1 - 1, _arg_2 - 1)) {
                        return false;
                    }
                } else if (_local3 > 0.5) {
                    if (this.isFullOccupy(_arg_1, _arg_2 + 1) || this.isFullOccupy(_arg_1 - 1, _arg_2 + 1)) {
                        return false;
                    }
                }
            } else if (_local4 > 0.5) {
                if (this.isFullOccupy(_arg_1 + 1, _arg_2)) {
                    return false;
                }
                if (_local3 < 0.5) {
                    if (this.isFullOccupy(_arg_1, _arg_2 - 1) || this.isFullOccupy(_arg_1 + 1, _arg_2 - 1)) {
                        return false;
                    }
                } else if (_local3 > 0.5) {
                    if (this.isFullOccupy(_arg_1, _arg_2 + 1) || this.isFullOccupy(_arg_1 + 1, _arg_2 + 1)) {
                        return false;
                    }
                }
            } else if (_local3 < 0.5) {
                if (this.isFullOccupy(_arg_1, _arg_2 - 1)) {
                    return false;
                }
            } else if (_local3 > 0.5) {
                if (this.isFullOccupy(_arg_1, _arg_2 + 1)) {
                    return false;
                }
            }
            return true;
        }
        
        public function isFullOccupy(_arg_1: Number, _arg_2: Number): Boolean {
            var _local3: Square = map_.lookupSquare(_arg_1, _arg_2);
            return _local3 == null || _local3.tileType == 255 || _local3.obj_ != null && _local3.obj_.props_.fullOccupy_;
        }
        
        public function follow(_arg_1: Number, _arg_2: Number): void {
            followVec.x = followPos.x - x_;
            followVec.y = followPos.y - y_;
        }
        
        public function calcFollowPos(): Point {
            var _local11: int = 0;
            var _local4: * = null;
            var _local16: * = null;
            var _local15: * = null;
            var _local1: Point = new Point();
            var _local14: Point = new Point();
            var _local13: Point = new Point();
            var _local5: Point = new Point();
            var _local3: int = -2147483648;
            var _local12: * = -2147483648;
            var _local2: * = 0;
            var _local10: Number = Parameters.data.densityThreshold * Parameters.data.densityThreshold;
            for each(_local16 in this.map_.vulnPlayerDict_) {
                if (_local16 != this) {
                    _local2 = 100000000000;
                    _local11 = 0;
                    _local3 = 0;
                    _local13.x = 0;
                    _local13.y = 0;
                    _local5.x = 0;
                    _local5.y = 0;
                    for each(_local15 in this.map_.vulnPlayerDict_) {
                        if (_local15 != this && _local15 != _local16) {
                            _local4 = _local15 as Player;
                            if (!(_local4.numStars_ < 3 && _local4.currFame_ < 100)) {
                                _local2 = getDistSquared(_local15.x_, _local15.y_, _local16.x_, _local16.y_);
                                if (_local2 < _local10) {
                                    _local3++;
                                    _local11++;
                                    _local13.x = _local13.x + _local15.x_;
                                    _local13.y = _local13.y + _local15.y_;
                                    _local5.x = _local5.x + _local15.moveVec_.x;
                                    _local5.y = _local5.y + _local15.moveVec_.y;
                                }
                            }
                        }
                    }
                    if (_local11 != 0) {
                        _local13.x = _local13.x / _local11;
                        _local13.y = _local13.y / _local11;
                        _local5.x = _local5.x / _local11;
                        _local5.y = _local5.y / _local11;
                        if (_local3 > _local12) {
                            _local12 = _local3;
                            _local1.x = _local13.x;
                            _local1.y = _local13.y;
                            _local14.x = _local5.x;
                            _local14.y = _local5.y;
                        }
                    }
                }
            }
            if (_local12 < 3) {
                Parameters.warnDensity = true;
                return new Point(followPos.x, followPos.y);
            }
            Parameters.warnDensity = true;
            if (_local14.length > 1) {
                _local14.normalize(1);
            }
            _local2 = Parameters.data.trainOffset * 0.01;
            var _local7: Number = _local1.x + _local14.x * (_local10 * _local2) + Parameters.famePoint.x;
            var _local6: Number = _local1.y + _local14.y * (_local10 * _local2) + Parameters.famePoint.y;
            var _local8: Number = _local7 - _local13.x;
            var _local9: Number = _local6 - _local13.y;
            if (_local8 * _local8 + _local9 * _local9 >= Parameters.data.fameDistDelta * Parameters.data.fameDistDelta) {
                _local13.x = _local7;
                _local13.y = _local6;
            } else {
                _local13.x = x_;
                _local13.y = y_;
            }
            return _local13;
        }
        
        public function dungeonMove(): void {
        }
        
        public function teleToClosestPoint(_arg_1: Point): void {
            var _local3: Number = NaN;
            var _local4: Number = Infinity;
            var _local2: int = -1;
            for each(var _local5: GameObject in this.map_.goDict_) {
                if (_local5 is Player && !_local5.isInvisible && !_local5.isPaused) {
                    _local3 = (_local5.x_ - _arg_1.x) * (_local5.x_ - _arg_1.x) + (_local5.y_ - _arg_1.y) * (_local5.y_ - _arg_1.y);
                    if (_local3 < _local4) {
                        _local4 = _local3;
                        _local2 = _local5.objectId_;
                    }
                }
            }
            if (_local2 == this.objectId_) {
                //this.textNotification("You are closest!", 0xffffff, 25 * 60, false);
                return;
            }
            this.map_.gs_.gsc_.teleport(_local2);
            this.textNotification("Teleporting to " + this.map_.goDict_[_local2].name_, 0xffffff, 25 * 60, false);
        }
        
        public function attemptAttackAngle(_arg_1: Number): void {
            if (this.equipment_[0] == -1) {
                return;
            }
            this.shoot(Parameters.data.cameraAngle + _arg_1);
        }
        
        public function attemptAutoAim(_arg_1: Number): void {
            var _local2: int = this.equipment_[0];
            var _local3: int = getTimer();
            if (_local2 != -1) {
                if (Parameters.data.AAOn) {
                    if (!this.shootAutoAimWeaponAngle(_local2, _local3) && this.map_.gs_.mui_.autofire_ && !this.map_.gs_.isSafeMap) {
                        this.shoot(Parameters.data.cameraAngle + _arg_1, _local3);
                    }
                } else if (this.map_.gs_.mui_.autofire_) {
                    this.shoot(Parameters.data.cameraAngle + _arg_1, _local3);
                }
            }
            this.attemptAutoAbility(_arg_1, _local3, this.equipment_[1]);
        }
        
        public function attemptAutoAbility(_arg_1: Number, angle: int = -1, abilityId: int = 0): void {
            if (abilityId == 0) {
                abilityId = this.equipment_[1];
            }
            if (angle == -1) {
            }
            angle = map_.gs_.lastUpdate_;
            if (abilityId != -1 && Parameters.data.AutoAbilityOn && !this.map_.gs_.isSafeMap && Parameters.abi && !Parameters.data.fameBlockAbility && this.mp_ >= this.autoMpPercentNumber) {
                this.shootAutoAimAbilityAngle(abilityId, angle);
            }
        }
        
        public function shootAutoAimWeaponAngle(param1: int, param2: int): Boolean {
            var _local8: Number = NaN;
            var _local9: * = null;
            var _local6: Number = NaN;
            if (this.isStunned_() || this.isPaused_() || this.isPetrified_()) {
                return false;
            }
            var _local10: ObjectProperties = ObjectLibrary.getPropsFromType(param1);
            this.attackPeriod_ = 1 / this.attackFrequency() * (1 / _local10.rateOfFire_);
            if (param2 < attackStart_ + this.attackPeriod_) {
                return false;
            }
            var _local5: Vector3D = new Vector3D(this.x_, this.y_);
            var _local4: Point = this.sToW(this.mousePos_.x, this.mousePos_.y);
            var _local3: Vector3D = new Vector3D(_local4.x, _local4.y);
            var _local7: ProjectileProperties = _local10.projectiles_[0];
            if (this.isUnstable) {
                this.attackStart_ = param2;
                this.attackAngle_ = Math.random() * 6.28318530717959;
                this.doShoot(param2, param1, ObjectLibrary.xmlLibrary_[param1], this.attackAngle_, true, true);
                return true;
            }
            _local8 = _local7.speed_ * this.projectileSpeedMult * (_local7.lifetime_ * this.projectileLifeMult);
            _local9 = this.calcAimAngle(_local7.speed_ * this.projectileSpeedMult, _local8 + Parameters.data.aaDistance, _local5, _local3);
            if (_local9) {
                _local6 = Math.atan2(_local9.y - this.y_, _local9.x - this.x_);
                this.attackStart_ = param2;
                this.attackAngle_ = _local6;
                this.doShoot(this.attackStart_, param1, ObjectLibrary.xmlLibrary_[param1], _local6, true, true);
                return true;
            }
            this.isShooting = false;
            return false;
        }
        
        public function shootAutoAimAbilityAngle(_arg_1: int, _arg_2: int): void {
            var _local7: int = 0;
            var _local4: int = 0;
            var _local8: * = null;
            var _local9: * = null;
            var _local6: XML = ObjectLibrary.xmlLibrary_[_arg_1];
            if (!this.canUseAltWeapon(_arg_2, _local6)) {
                return;
            }
            if (_arg_2 - this.lastAutoAbilityAttempt <= 520) {
                return;
            }
            var _local5: Point = this.sToW(this.mousePos_.x, this.mousePos_.y);
            _arg_2 = getTimer();
            var _local12: * = this.objectType_;
            switch (_local12) {
                case 784:
                    this.priestHeal(_arg_2);
                    this.lastAutoAbilityAttempt = _arg_2;
                    return;
                case 768:
                    var _local10: * = _local6.Activate;
                    var _local11: int = 0;
                    var _local13: * = new XMLList("");
                    if (_local6.Activate.(text() == "Teleport") == "Teleport") {
                        return;
                    }
                case 797:
                case 799:
                    this.useAltWeapon(this.x_, this.y_, 1, _arg_2, true, _local6);
                    this.lastAutoAbilityAttempt = _arg_2;
                    return;
                case 806:
                    if (!this.isNinjaSpeedy) {
                        this.useAltWeapon(this.x_, this.y_, 1, _arg_2, true, _local6);
                        this.lastAutoAbilityAttempt = _arg_2;
                    }
                    return;
                case 801:
                case 800:
                case 802:
                    if (this.necroHeal()) {
                        this.lastAutoAbilityAttempt = _arg_2;
                    }
                    return;
                case 804:
                    var _local14: * = _local6.Activate;
                    var _local15: int = 0;
                    _local10 = new XMLList("");
                    if (_local6.Activate.(text() == "Teleport") == "Teleport") {
                        return;
                    }
                    _local7 = Parameters.data.spamPrismNumber;
                    if (_local7 > 0) {
                        _local4 = 0;
                        for each(var _local3: GameObject in this.map_.goDict_) {
                            if (_local3.props_.isEnemy_ && this.getDistSquared(this.x_, this.y_, _local3.x_, _local3.y_) <= 225) {
                                _local4++;
                                if (_local4 > _local7) {
                                    this.useAltWeapon(this.x_, this.y_, 1, _arg_2, true, _local6);
                                    this.lastAutoAbilityAttempt = _arg_2;
                                    return;
                                }
                            }
                        }
                    }
                    return;
                case 798:
                case 775:
                    _local9 = ObjectLibrary.getPropsFromType(_arg_1).projectiles_[0];
                    if (_local9) {
                        _local9 = ObjectLibrary.getPropsFromType(_arg_1).projectiles_[0];
                        if (this.isUnstable) {
                            _local8 = new Vector3D(Math.random() - 0.5, Math.random() - 0.5);
                        } else {
                            _local8 = this.calcAimAngle(_local9.speed_, _local9.maxProjTravel_, new Vector3D(this.x_, this.y_), new Vector3D(_local5.x, _local5.y), true);
                        }
                        if (_local8) {
                            this.useAltWeapon(_local8.x, _local8.y, 1, _arg_2, true, _local6);
                            lastAutoAbilityAttempt = _arg_2;
                        }
                    }
                    return;
                case 805:
                    if (this.isUnstable) {
                        _local8 = null;
                    } else {
                        _local8 = this.calcAimAngle(NaN, 7, new Vector3D(this.x_, this.y_), new Vector3D(_local5.x, _local5.y));
                    }
                    if (_local8) {
                        this.useAltWeapon(_local8.x, _local8.y, 1, _arg_2, true, _local6);
                        lastAutoAbilityAttempt = _arg_2;
                    }
                    return;
                case 782:
                    if (this.isUnstable) {
                        _local8 = null;
                    } else {
                        _local8 = this.calcAimAngle(NaN, 12, new Vector3D(this.x_, this.y_), new Vector3D(_local5.x, _local5.y));
                    }
                    if (_local8) {
                        this.useAltWeapon(_local8.x, _local8.y, 1, _arg_2, true, _local6);
                        lastAutoAbilityAttempt = _arg_2;
                    }
                    return;
                case 803:
                    if (this.isUnstable) {
                        _local8 = new Vector3D(Math.random() - 0.5, Math.random() - 0.5);
                    } else if (Parameters.data.mysticAAShootGroup) {
                        if (this.necroHeal()) {
                            this.lastAutoAbilityAttempt = _arg_2;
                        }
                    } else {
                        this.useAltWeapon(this.x_, this.y_, 1, _arg_2, true, _local6);
                        lastAutoAbilityAttempt = _arg_2;
                    }
                    return;
                case 785:
                    if (this.isUnstable) {
                        _local8 = null;
                    } else {
                        _local8 = this.calcAimAngle(NaN, getWakiRange(_arg_1), new Vector3D(this.x_, this.y_), new Vector3D(_local5.x, _local5.y));
                    }
                    if (_local8) {
                        this.useAltWeapon(_local8.x, _local8.y, 1, _arg_2, true, _local6);
                        lastAutoAbilityAttempt = _arg_2;
                    }
                    return;
                default:
                    return;
            }
        }
        
        public function getWakiRange(_arg_1: int): Number {
            var _local2: * = _arg_1;
            switch (_local2) {
                case 8994:
                    return 4.6;
                case 9152:
                    return 6.4;
                default:
                    return 4.4;
            }
        }
        
        public function calcAimAngle(_arg_1: Number, _arg_2: Number, _arg_3: Vector3D, _arg_4: Vector3D, _arg_5: Boolean = false): Vector3D {
            var _local24: int = 0;
            var _local19: int = 0;
            var _local14: Boolean = false;
            var _local16: GameObject = null;
            var _local17: * = null;
            _arg_2 = _arg_2 * _arg_2;
            var _local12: Vector3D = new Vector3D();
            var _local13: * = Infinity;
            var _local11: * = Infinity;
            var _local20: * = -2147483648;
            var _local25: * = -2147483648;
            var _local26: int = Parameters.data.AABoundingDist;
            _local26 = _local26 * _local26;
            var _local22: Boolean = Parameters.data.damageIgnored;
            var _local21: Boolean = Parameters.data.autoaimAtInvulnerable;
            var _local9: Boolean = Parameters.data.shootAtWalls;
            var _local6: Boolean = Parameters.data.onlyAimAtExcepted;
            var _local15: Boolean = Parameters.data.AATargetLead;
            var _local10: int = Parameters.data.spellbombHPThreshold;
            var _local7: int = Parameters.data.skullHPThreshold;
            var _local18: Boolean = Parameters.data.BossPriority;
            var _local23: Vector.<GameObject> = new Vector.<GameObject>();
            var _local8: Boolean = true;
            do {
                _local24 = Parameters.data.aimMode;
                if (_local24 == 0) {
                    for each(_local16 in this.map_.vulnEnemyDict_) {
                        _local14 = _local16.props_.boss_ || _local16.props_.customBoss_;
                        if (!(!_local9 && !(_local16 is Character))) {
                            if (!(_local18 && !_local14)) {
                                if (!(_local16.dead_ || _local16.props_.ignored && !_local22 || !_local16.props_.excepted && _local6 || !_local21 && _local16.isInvulnerable)) {
                                    if (isNaN(_arg_1)) {
                                        if (!(_arg_2 == 144 && _local16.maxHP_ < _local10)) {
                                            if (!(_arg_2 == 49 && _local16.maxHP_ < _local7)) {
                                                _local12 = new Vector3D(_local16.tickPosition_.x, _local16.tickPosition_.y);
                                            }
                                        }
                                    } else if (!(_arg_5 && _local16.maxHP_ < _local10)) {
                                        if (_local16.jittery || !_local15) {
                                            _local12 = new Vector3D(_local16.x_, _local16.y_);
                                        } else {
                                            _local12 = this.leadPos(_arg_3, new Vector3D(_local16.x_, _local16.y_), new Vector3D(_local16.moveVec_.x, _local16.moveVec_.y), _arg_1);
                                        }
                                    }
                                    if (_local12) {
                                        _local13 = this.getDistSquared(_local16.x_, _local16.y_, this.x_, this.y_);
                                        if (_local13 <= _arg_2) {
                                            _local13 = this.getDistSquared(_local16.x_, _local16.y_, _arg_4.x, _arg_4.y);
                                            if (_local13 <= _local26) {
                                                if (_local18 && _local14) {
                                                    _local8 = false;
                                                    _local17 = _local12;
                                                } else {
                                                    if (_local13 <= _local11) {
                                                        _local11 = _local13;
                                                        _local17 = _local12;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if (_local24 == 1) {
                    for each(_local16 in this.map_.vulnEnemyDict_) {
                        _local14 = _local16.props_.boss_ || _local16.props_.customBoss_;
                        if (!(!_local9 && !(_local16 is Character))) {
                            if (!(_local18 && !_local14)) {
                                if (!(_local16.dead_ || _local16.props_.ignored && !_local22 || !_local16.props_.excepted && _local6 || !_local21 && _local16.isInvulnerable)) {
                                    if (isNaN(_arg_1)) {
                                        if (!(_arg_2 == 144 && _local16.maxHP_ < _local10)) {
                                            if (!(_arg_2 == 49 && _local16.maxHP_ < _local7)) {
                                                _local12 = new Vector3D(_local16.tickPosition_.x, _local16.tickPosition_.y);
                                            }
                                        }
                                    } else if (_local16.jittery || !_local15) {
                                        _local12 = new Vector3D(_local16.x_, _local16.y_);
                                    } else {
                                        _local12 = this.leadPos(_arg_3, new Vector3D(_local16.x_, _local16.y_), new Vector3D(_local16.moveVec_.x, _local16.moveVec_.y), _arg_1);
                                    }
                                    if (_local12) {
                                        if (_local16.maxHP_ >= _local20) {
                                            if (_local16.maxHP_ == _local20) {
                                                if (_local16.hp_ <= _local25) {
                                                    _local13 = this.getDistSquared(_local16.x_, _local16.y_, this.x_, this.y_);
                                                    if (!(_local16.hp_ == _local25 && _local13 > _local11)) {
                                                        if (_local13 < _arg_2) {
                                                            _local20 = _local16.maxHP_;
                                                            _local25 = _local16.hp_;
                                                            _local17 = _local12;
                                                            _local11 = _local13;
                                                        }
                                                    }
                                                }
                                            }
                                            _local13 = this.getDistSquared(_local16.x_, _local16.y_, this.x_, this.y_);
                                            if (_local13 < _arg_2) {
                                                if (_local18 && _local14) {
                                                    _local8 = false;
                                                    _local17 = _local12;
                                                } else {
                                                    _local20 = _local16.maxHP_;
                                                    _local25 = _local16.hp_;
                                                    _local11 = _local13;
                                                    _local17 = _local12;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if (_local24 == 2) {
                    var _local32: int = 0;
                    var _local31: * = this.map_.vulnEnemyDict_;
                    for each(_local16 in this.map_.vulnEnemyDict_) {
                        _local14 = _local16.props_.boss_ || _local16.props_.customBoss_;
                        if (!(!_local9 && !(_local16 is Character))) {
                            if (!(_local18 && !_local14)) {
                                if (!(_local16.dead_ || _local16.props_.ignored && !_local22 || !_local16.props_.excepted && _local6 || !_local21 && _local16.isInvulnerable)) {
                                    if (isNaN(_arg_1)) {
                                        if (!(_arg_2 == 144 && _local16.maxHP_ < _local10)) {
                                            if (!(_arg_2 == 49 && _local16.maxHP_ < _local7)) {
                                                _local12 = new Vector3D(_local16.tickPosition_.x, _local16.tickPosition_.y);
                                            } else {
                                                continue;
                                            }
                                        } else {
                                            continue;
                                        }
                                    } else if (_local16.jittery || !_local15) {
                                        _local12 = new Vector3D(_local16.x_, _local16.y_);
                                    } else {
                                        _local12 = this.leadPos(_arg_3, new Vector3D(_local16.x_, _local16.y_), new Vector3D(_local16.moveVec_.x, _local16.moveVec_.y), _arg_1);
                                    }
                                    if (_local12) {
                                        _local13 = this.getDistSquared(_local16.x_, _local16.y_, this.x_, this.y_);
                                        if (_local13 < _arg_2) {
                                            if (_local18 && _local14) {
                                                _local8 = false;
                                                _local17 = _local12;
                                                break;
                                            }
                                            if (_local13 < _local11) {
                                                _local11 = _local13;
                                                _local17 = _local12;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if (_local24 == 3) {
                    _local23.length = 0;
                    _local19 = 0;
                    var _local34: int = 0;
                    var _local33: * = this.map_.vulnEnemyDict_;
                    for each(_local16 in this.map_.vulnEnemyDict_) {
                        _local14 = _local16.props_.boss_ || _local16.props_.customBoss_;
                        if (!(!_local9 && !(_local16 is Character))) {
                            if (!(_local18 && !_local14)) {
                                if (!(_local16.dead_ || _local16.props_.ignored && !_local22 || !_local16.props_.excepted && _local6 || !_local21 && _local16.isInvulnerable)) {
                                    if (isNaN(_arg_1)) {
                                        if (!(_arg_2 == 144 && _local16.maxHP_ < _local10)) {
                                            if (!(_arg_2 == 49 && _local16.maxHP_ < _local7)) {
                                                _local12 = new Vector3D(_local16.tickPosition_.x, _local16.tickPosition_.y);
                                            } else {
                                                continue;
                                            }
                                        } else {
                                            continue;
                                        }
                                    } else if (_local16.jittery || !_local15) {
                                        _local12 = new Vector3D(_local16.x_, _local16.y_);
                                    } else {
                                        _local12 = this.leadPos(_arg_3, new Vector3D(_local16.x_, _local16.y_), new Vector3D(_local16.moveVec_.x, _local16.moveVec_.y), _arg_1);
                                    }
                                    if (_local12) {
                                        _local13 = this.getDistSquared(_local16.x_, _local16.y_, this.x_, this.y_);
                                        if (_local13 < _arg_2) {
                                            if (_local18 && _local14) {
                                                _local8 = false;
                                                _local17 = _local12;
                                                break;
                                            }
                                            _local23.push(_local16);
                                            _local19++;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (_local19 != 0) {
                        _local16 = _local23[int(Math.random() * _local19)];
                        if (isNaN(_arg_1)) {
                            _local12 = new Vector3D(_local16.tickPosition_.x, _local16.tickPosition_.y);
                        } else if (_local16.jittery || !_local15) {
                            _local12 = new Vector3D(_local16.x_, _local16.y_);
                        } else {
                            _local12 = this.leadPos(_arg_3, new Vector3D(_local16.x_, _local16.y_), new Vector3D(_local16.moveVec_.x, _local16.moveVec_.y), _arg_1);
                        }
                        _local17 = _local12;
                    }
                }
                if (_local18) {
                    if (_local8) {
                        _local18 = false;
                    }
                } else {
                    _local8 = false;
                }
            }
            while (_local8);
            
            return _local17;
        }
        
        public function leadPos(param1: Vector3D, param2: Vector3D, param3: Vector3D, param4: Number): Vector3D {
            var _local11: Vector3D = param2.subtract(param1);
            var _local5: Number = 2 * (param3.dotProduct(param3) - param4 * param4);
            var _local6: Number = 2 * _local11.dotProduct(param3);
            var _local7: Number = _local11.dotProduct(_local11);
            var _local8: Number = Math.sqrt(_local6 * _local6 - 2 * _local5 * _local7);
            var _local10: Number = (-_local6 + _local8) / _local5;
            var _local9: Number = (-_local6 - _local8) / _local5;
            if (_local10 < _local9 && _local10 >= 0) {
                param3.scaleBy(_local10);
            } else if (_local9 >= 0) {
                param3.scaleBy(_local9);
            } else {
                return null;
            }
            return param2.add(param3);
        }
        
        public function getDist(_arg_1: Number, _arg_2: Number, _arg_3: Number, _arg_4: Number): Number {
            var _local6: Number = _arg_1 - _arg_3;
            var _local5: Number = _arg_2 - _arg_4;
            return Math.sqrt(_local5 * _local5 + _local6 * _local6);
        }
        
        public function getDistSquared(_arg_1: Number, _arg_2: Number, _arg_3: Number, _arg_4: Number): Number {
            var _local6: Number = _arg_1 - _arg_3;
            var _local5: Number = _arg_2 - _arg_4;
            return _local5 * _local5 + _local6 * _local6;
        }
        
        public function getDistObj(_arg_1: GameObject, _arg_2: GameObject): Number {
            var _local4: Number = _arg_1.x_ - _arg_2.x_;
            var _local3: Number = _arg_1.y_ - _arg_2.y_;
            return Math.sqrt(_local3 * _local3 + _local4 * _local4);
        }
        
        public function getDistSquaredObj(_arg_1: GameObject, _arg_2: GameObject): Number {
            var _local4: Number = _arg_1.x_ - _arg_2.x_;
            var _local3: Number = _arg_1.y_ - _arg_2.y_;
            return _local3 * _local3 + _local4 * _local4;
        }
        
        public function necroHeal(): Boolean {
            var _local1: Point = this.getNecroTarget();
            if (_local1) {
                return this.useAltWeapon(_local1.x, _local1.y, 1, -1, true);
            }
            return false;
        }
        
        public function priestHeal(_arg_1: int): void {
            if (this.hp_ <= this.autoHealNumber || this.clientHp <= this.autoHealNumber || this.syncedChp <= this.autoHealNumber) {
                this.useAltWeapon(this.x_, this.y_, 1, _arg_1, true);
            }
        }
        
        public function getNecroTarget(): Point {
            var maxDist: Number = 0;
            var _local1: * = null;
            var _local5: int = -1;
            var _local7: int = Parameters.data.skullHPThreshold;
            var _local2: int = Parameters.data.skullTargets;
            var _local4: Number = ObjectLibrary.xmlLibrary_[this.equipment_[1]].Activate.@radius;
            var _local9: int = 0;
            var _local8: * = map_.vulnEnemyDict_;
            for each(var _local3: GameObject in map_.vulnEnemyDict_) {
                if (!_local3.isInvulnerable && !_local3.isStasis && !_local3.isInvincible && !_local3.isPaused) {
                    if (_local3.maxHP_ >= _local7 && _local3 is Character && this.getDistSquared(_local3.x_, _local3.y_, this.x_, this.y_) <= 225) {
                        _local5 = this.getNumNearbyEnemies(_local3, _local4);
                        if (_local5 > _local2 && _local5 > maxDist) {
                            _local1 = _local3;
                            maxDist = _local5;
                        }
                    }
                }
            }
            if (maxDist < _local2 || _local1 == null) {
                return null;
            }
            return new Point(_local1.x_, _local1.y_);
        }
        
        public function getNumNearbyEnemies(_arg_1: GameObject, _arg_2: int): int {
            var _local4: int = 0;
            var _local5: * = null;
            _arg_2 = _arg_2 * _arg_2;
            var _local3: int = Parameters.data.skullHPThreshold;
            var _local7: int = 0;
            var _local6: * = map_.vulnEnemyDict_;
            for each(_local5 in map_.vulnEnemyDict_) {
                if (_local5.maxHP_ >= _local3 && _local5 is Character && this.getDistSquared(_local5.x_, _local5.y_, _arg_1.x_, _arg_1.y_) <= _arg_2) {
                    _local4++;
                }
            }
            return _local4;
        }
        
        public function autoLoot(_arg_1: int = -1): void {
            var _local4: int = 0;
            var _local2: int = 0;
            var _local3: * = null;
            if (_arg_1 == -1) {
                _arg_1 = getTimer();
            }
            if (_arg_1 - this.map_.gs_.gsc_.lastInvSwapTime <= 500) {
                return;
            }
            if (this.isInventoryFull() && (Parameters.data.autoLootHPPots && healthPotionCount_ == 6) && (Parameters.data.autoLootMPPots && magicPotionCount_ == 6)) {
                return;
            }
            for each(var _local5: GameObject in this.map_.goDict_) {
                if (_local5 is Container && _local5.objectType_ != 1284 && _local5.objectType_ != 31 * 60 && _local5.equipment_ && getDistSquared(this.x_, this.y_, _local5.x_, _local5.y_) <= 1) {
                    _local4 = 0;
                    while (_local4 < 8) {
                        _local2 = _local5.equipment_[_local4];
                        if (_local2 != -1) {
                            _local3 = ObjectLibrary.propsLibrary_[_local2];
                            if (_local3) {
                                if (_local3.desiredLoot_ || Parameters.data.autoLootUpgrades && checkForUpgrade(_local3)) {
                                    pickup(_local5, _local4, _local2);
                                }
                            }
                        }
                        _local4++;
                    }
                    
                }
            }
        }
        
        public function checkForUpgrade(_arg_1: ObjectProperties): Boolean {
            var _local3: int = 0;
            var _local2: int = 0;
            var _local4: * = null;
            if (_arg_1.slotType_ != -2147483648) {
                _local3 = 0;
                while (_local3 < 4) {
                    _local2 = this.slotTypes_[_local3];
                    if (_arg_1.slotType_ == _local2) {
                        if (this.equipment_ && this.equipment_[_local3] == -1) {
                            return true;
                        }
                        _local4 = ObjectLibrary.propsLibrary_[this.equipment_[_local3]];
                        if (_local4 && _local4.tier != -2147483648 && _arg_1.tier > _local4.tier) {
                            return true;
                        }
                    }
                    _local3++;
                }
            }
            return false;
        }
        
        public function drink(_arg_1: GameObject, _arg_2: int, _arg_3: int): void {
            this.map_.gs_.gsc_.useItem_new(_arg_1, _arg_2);
            SoundEffectLibrary.play("use_potion");
        }
        
        public function pickup(param1: GameObject, param2: int, param3: int): void {
            var _local4: int = 0;
            if (param3 == 2594) {
                if (this.healthPotionCount_ == 6) {
                    if (Parameters.data.autoLootHPPotsInv) {
                        _local4 = findItem(this.equipment_, -1, 4, false, !!this.hasBackpack_ ? 20 : 12);
                        if (_local4 != -1) {
                            this.map_.gs_.gsc_.invSwap(this, this, _local4, -1, param1, param2, param1.equipment_[param2]);
                        }
                    }
                } else {
                    this.map_.gs_.gsc_.invSwapRaw(this.x_, this.y_, param1.objectId_, param2, 2594, this.objectId_, 254, -1);
                }
            } else if (param3 == 2595) {
                if (this.magicPotionCount_ == 6) {
                    if (Parameters.data.autoLootMPPotsInv) {
                        _local4 = findItem(this.equipment_, -1, 4, false, !!this.hasBackpack_ ? 20 : 12);
                        if (_local4 == -1) {
                            return;
                        }
                        this.map_.gs_.gsc_.invSwap(this, this, _local4, -1, param1, param2, param1.equipment_[param2]);
                    }
                } else {
                    this.map_.gs_.gsc_.invSwapRaw(this.x_, this.y_, param1.objectId_, param2, 2595, this.objectId_, 255, -1);
                }
            } else {
                _local4 = findItem(this.equipment_, -1, 4, false, !!this.hasBackpack_ ? 20 : 12);
                if (_local4 != -1) {
                    this.map_.gs_.gsc_.invSwap(this, this, _local4, this.equipment_[_local4], param1, param2, param1.equipment_[param2]);
                }
            }
        }
        
        public function findItems(_arg_1: Vector.<int>, _arg_2: Vector.<int>, _arg_3: int = 0): int {
            var _local4: * = 0;
            var _local5: int = _arg_1.length;
            _local4 = _arg_3;
            while (_local4 < _local5) {
                if (_arg_2.indexOf(_arg_1[_local4]) >= 0) {
                    return _local4;
                }
                _local4++;
            }
            return -1;
        }
        
        public function findItem(_arg_1: Vector.<int>, _arg_2: int, _arg_3: int = 0, _arg_4: Boolean = false, _arg_5: int = 8): int {
            var _local6: * = -1;
            if (_arg_4) {
                _local6 = _arg_3;
                while (_local6 < _arg_5) {
                    if (_arg_1[_local6] != _arg_2) {
                        return _local6;
                    }
                    _local6++;
                }
            } else {
                _local6 = _arg_3;
                while (_local6 < _arg_5) {
                    if (_arg_1[_local6] == _arg_2) {
                        return _local6;
                    }
                    _local6++;
                }
            }
            return -1;
        }
        
        public function calcSealHeal(): int {
            var heal: int = 0;
            var dist: Number = NaN;
            var _local2: int = this.equipment_[1];
            var healSqr: Number = this.wisdom < 30 ? 4.5 : Number(4.5 + 0.03 * this.wisdom);
            healSqr = healSqr * healSqr;
            var _local1: XML = ObjectLibrary.xmlLibrary_[_local2];
            if (_local1.Activate[0] == "StatBoostAura" && _local1.useWisModifier) {
                var _local6: * = _local2;
                switch (_local6) {
                    case 8344:
                    case 2854:
                        heal = this.wisdom < 30 ? 75 : Number(75 + 0.5 * this.wisdom);
                        break;
                    case 2645:
                        heal = this.wisdom < 30 ? 55 : Number(55 + 0.366666666666667 * this.wisdom);
                        break;
                    case 2644:
                        heal = this.wisdom < 30 ? 45 : Number(45 + 0.3 * this.wisdom);
                        break;
                    case 2778:
                        heal = this.wisdom < 30 ? 25 : Number(25 + 0.166666666666667 * this.wisdom);
                        break;
                    case 2643:
                        heal = this.wisdom < 30 ? 10 : Number(10 + 0.0666666666666667 * this.wisdom);
                        break;
                    case 9062:
                        heal = this.wisdom < 30 ? 60 : Number(60 + 0.4 * this.wisdom);
                        break;
                    case 0x205b:
                        heal = this.wisdom < 30 ? 95 : 95 + this.wisdom / 2;
                        break;
                    default:
                        return 0;
                }
                dist = getDistSquared(map_.player_.tickPosition_.x, map_.player_.tickPosition_.y,
                        this.moveVec_.x + this.x_, this.moveVec_.y + this.y_);
                if (dist < healSqr)
                    return heal;
            }
            return 0;
        }
        
        public function addSealHealth(_arg_1: int): void {
            this.healBuffer = this.healBuffer + _arg_1;
            this.healBufferTime = getTimer() + 220;
        }
        
        public function calcHealthPercent(): void {
            this.autoHpPotNumber = Parameters.data.autoHPPercent * 0.01 * this.maxHP_;
            this.autoNexusNumber = Parameters.data.AutoNexus * 0.01 * this.maxHP_;
            this.autoHealNumber = Parameters.data.AutoHealPercentage * 0.01 * this.maxHP_;
        }
        
        public function calcManaPercent(): void {
            if (Parameters.data.autoMPPercent < 0) {
                this.autoMpPotNumber = -1;
            } else {
                this.autoMpPotNumber = Parameters.data.autoMPPercent * 0.01 * this.maxMP_;
            }
            if (Parameters.data.AAMinManaPercent < 0) {
                this.autoMpPercentNumber = -1;
            } else {
                this.autoMpPercentNumber = Parameters.data.AAMinManaPercent * 0.01 * this.maxMP_;
            }
        }
        
        public function triggerHealBuffer(): void {
            if (this.healBuffer > 0) {
                this.addHealth(this.healBuffer);
                this.healBuffer = 0;
                this.healBufferTime = 0x7fffffff;
            }
        }
        
        public function maxHpChanged(maxHP: int): void {
            if (maxHP < this.maxHP_)
                if (this.clientHp > this.maxHP_)
                    this.clientHp = this.maxHP_;
        }
        
        public function addHealth(hp: int): void {
            this.clientHp = this.clientHp + hp;
            if (this.clientHp > this.maxHP_)
                this.clientHp = this.maxHP_;
        }
        
        public function subtractDamage(dmg: int, time: int = -1): Boolean {
            if (time == -1)
                time = TimeUtil.getModdedTime();
            if (dmg >= combatTrigger()) {
                this.icMS = TimeUtil.getTrueTime();
            }
            this.clientHp = this.clientHp - dmg;
            this.syncedChp = this.syncedChp - dmg;
            return this.checkHealth(time);
        }
        
        public function checkHealth(time: int = -1): Boolean {
            var _local4: Boolean = false;
            var _local5: int = 0;
            var _local2: int = 0;
            var _local3: int = 0;
            if (!this.map_.gs_.isSafeMap) {
                if (Parameters.data.AutoNexus == 0 || Parameters.suicideMode) {
                    return false;
                }
                if (this.clientHp <= this.autoNexusNumber || this.hp_ <= this.autoNexusNumber || this.syncedChp <= this.autoNexusNumber) {
                    this.map_.gs_.gsc_.disconnect();
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "You were saved at " + this.clientHp + " health"));
                    this.map_.gs_.dispatchEvent(Parameters.reconNexus);
                    return true;
                }
                if (!Parameters.data.fameBlockThirsty && !this.isSick && this.autoHpPotNumber != 0 && (this.hp_ <= this.autoHpPotNumber || this.clientHp <= this.autoHpPotNumber || this.syncedChp <= this.autoHpPotNumber) && time - this.lastHpPotTime > Parameters.data.autohpPotDelay) {
                    _local4 = false;
                    _local5 = !!this.hasBackpack_ ? 20 : 12;
                    _local3 = 4;
                    while (_local3 < _local5) {
                        _local2 = this.equipment_[_local3];
                        if (_local2 == 2594 || _local2 == 1799) {
                            if (time == -1) {
                                time = getTimer();
                            }
                            this.map_.gs_.gsc_.useItem(time, this.objectId_, _local3, _local2, this.x_, this.y_, 1);
                            _local4 = true;
                            break;
                        }
                        _local3++;
                    }
                    if (!_local4 && this.healthPotionCount_ > 0) {
                        this.map_.gs_.mui_.useBuyPotionSignal.dispatch(hpPotionVO);
                        _local4 = true;
                    }
                    if (_local4) {
                        if (time == -1) {
                            time = getTimer();
                        }
                        this.lastHpPotTime = time;
                    }
                }
            }
            return false;
        }
        
        public function checkMana(_arg_1: int = -1): void {
            var _local2: int = 0;
            var _local3: * = null;
            if (!this.map_.gs_.isSafeMap) {
                if (_arg_1 == -1) {
                    _arg_1 = getTimer();
                }
                if (this.autoMpPotNumber == 0 || Parameters.data.fameBlockThirsty || this.isQuiet_() || _arg_1 - lastMpPotTime < Parameters.data.autompPotDelay) {
                    return;
                }
                if (this.autoMpPotNumber == -1) {
                    _local2 = equipment_[1];
                    if (_local2 == -1) {
                        return;
                    }
                    _local3 = ObjectLibrary.xmlLibrary_[_local2];
                    if (this.mp_ > _local3.MpCost) {
                        return;
                    }
                    lookForMpPotAndDrink(_arg_1);
                } else if (this.mp_ <= this.autoMpPotNumber) {
                    lookForMpPotAndDrink(_arg_1);
                }
            }
        }
        
        public function onMove(): void {
            var _local1: Square = null;
            if (map_) {
                _local1 = map_.getSquare(x_, y_);
                if (_local1.props_.sinking_) {
                    sinkLevel = Math.min(sinkLevel + 1, 18);
                    this.moveMultiplier_ = 0.1 + (1 - sinkLevel / 18) * (_local1.props_.speed_ - 0.1);
                } else {
                    sinkLevel = 0;
                    this.moveMultiplier_ = _local1.props_.speed_;
                }
            }
        }
        
        public function attackFrequency(): Number {
            if (this.isDazed) {
                return 0.0015;
            }
            var _local1: Number = 0.0015 + this.dexterity_ * 0.0133333333333333 * 0.0065;
            if (this.isBerserk) {
                _local1 = _local1 * 1.5;
            }
            return _local1;
        }
        
        public function canUseAltWeapon(_arg_1: int = -1, _arg_2: XML = null): Boolean {
            if (_arg_1 == -1) {
                _arg_1 = getTimer();
            }
            if (map_ == null) {
                return false;
            }
            if (Parameters.data.fameBlockAbility) {
                return false;
            }
            if (this.isQuiet_()) {
                return false;
            }
            if (this.isSilenced) {
                return false;
            }
            if (this.isPaused) {
                return false;
            }
            if (_arg_1 < this.nextAltAttack_) {
                return false;
            }
            var _local3: int = equipment_[1];
            if (_local3 == -1) {
                return false;
            }
            if (_arg_2 == null) {
                _arg_2 = ObjectLibrary.xmlLibrary_[_local3];
            }
            if (_arg_2.Activate == "Shoot" && this.isStunned) {
                return false;
            }
            if (_arg_2.MpCost > this.mp_) {
                return false;
            }
            return true;
        }
        
        public function getFamePortrait(_arg_1: int): BitmapData {
            var _local2: * = null;
            if (this.famePortrait_ == null) {
                _local2 = animatedChar_.imageFromDir(0, 0, 0);
                _arg_1 = 4 / _local2.image_.width * _arg_1;
                this.famePortrait_ = TextureRedrawer.resize(_local2.image_, _local2.mask_, _arg_1, true, tex1Id_, tex2Id_);
                this.famePortrait_ = GlowRedrawer.outlineGlow(this.famePortrait_, 0);
            }
            return this.famePortrait_;
        }
        
        public function useAltWeapon(param1: Number, param2: Number, param3: int, param4: int = -1, param5: Boolean = false, param6: XML = null): Boolean {
            var _local26: int = 0;
            var _local15: int = 0;
            var _local24: * = null;
            var _local21: Number = NaN;
            var _local17: Number = NaN;
            var _local13: * = null;
            var _local27: Number = NaN;
            var _local14: int = 0;
            var _local18: Boolean = false;
            var _local16: Boolean = false;
            var _local10: Boolean = false;
            var _local25: * = null;
            var _local9: Number = NaN;
            var _local7: Number = NaN;
            var _local12: * = null;
            var _local20: * = null;
            var _local19: Number = NaN;
            var _local23: Number = NaN;
            var _local22: * = null;
            var _local11: * = null;
            if (param4 == -1) {
                param4 = getTimer();
            }
            if (map_ == null || this.isPaused) {
                return false;
            }
            if (Parameters.data.fameBlockAbility) {
                return false;
            }
            var _local8: int = equipment_[1];
            if (_local8 == -1) {
                return false;
            }
            if (param6 == null) {
                param6 = ObjectLibrary.xmlLibrary_[_local8];
            }
            if (param6 == null || !("Usable" in param6)) {
                return false;
            }
            if (this.isQuiet) {
                SoundEffectLibrary.play("error");
                return false;
            }
            if (this.isSilenced) {
                SoundEffectLibrary.play("error");
                return false;
            }
            if (param6.Activate == "Shoot" && this.isStunned) {
                SoundEffectLibrary.play("error");
                return false;
            }
            if (param3 == 1) {
                var _local29: int = 0;
                var _local28: * = param6.Activate;
                for each(_local11 in param6.Activate) {
                    _local25 = _local11.toString();
                    if (_local25 == "TeleportLimit") {
                        _local21 = _local11.@maxDistance;
                        _local13 = new Point(x_ + _local21 * Math.cos(_local17), y_ + _local21 * Math.sin(_local17));
                        if (!Parameters.data.bypassTpPositionCheck) {
                            if (!this.isValidPosition(_local13.x, _local13.y)) {
                                SoundEffectLibrary.play("error");
                                return false;
                            }
                        }
                    }
                    if (_local25 == "Teleport" || _local25 == "ObjectToss") {
                        _local16 = true;
                        _local10 = true;
                    }
                    if (_local25 == "BulletNova" || _local25 == "PoisonGrenade" || _local25 == "VampireBlast" || _local25 == "Trap" || _local25 == "BoostRange" || _local25 == "StasisBlast") {
                        _local16 = true;
                    }
                    if (_local25 == "Shoot") {
                        _local18 = true;
                    }
                    if (_local25 == "BulletCreate") {
                        _local17 = Math.atan2(param2 - y_, param1 - x_);
                        _local9 = Math.sqrt(param1 * param1 + param2 * param2) / 50;
                        _local7 = Math.max(this.getAttribute(_local11, "minDistance", 0), Math.min(this.getAttribute(_local11, "maxDistance", 4.4), _local9));
                        _local12 = new Point(x_ + _local7 * Math.cos(_local17), y_ + _local7 * Math.sin(_local17));
                        _local20 = ObjectLibrary.propsLibrary_[_local8].projectiles_[0];
                        _local19 = _local20.speed_ * _local20.lifetime_ / 20000;
                        _local23 = _local17 + this.getAttribute(_local11, "offsetAngle", 90) * 0.0174532925199433;
                        _local22 = new Point(_local12.x + _local19 * Math.cos(_local23 + 3.14159265358979), _local12.y + _local19 * Math.sin(_local23 + 3.14159265358979));
                        if (this.isFullOccupy(_local22.x + 0.5, _local22.y + 0.5)) {
                            SoundEffectLibrary.play("error");
                            return false;
                        }
                    }
                }
            }
            if (param5) {
                _local24 = new Point(param1, param2);
                _local17 = Math.atan2(param2 - y_, param1 - x_);
            } else {
                _local17 = Parameters.data.cameraAngle + Math.atan2(param2, param1);
                if (_local16) {
                    _local24 = sToW(param1, param2);
                } else {
                    _local21 = Math.sqrt(param1 * param1 + param2 * param2) * 0.02;
                    _local24 = new Point(x_ + _local21 * Math.cos(_local17), y_ + _local21 * Math.sin(_local17));
                }
            }
            if (objectType_ == 804 || _local8 == 2650 && _local10) {
                if (_local24 == null) {
                    SoundEffectLibrary.play("error");
                    return false;
                }
                if (!Parameters.data.bypassTpPositionCheck) {
                    if (!isValidPosition(_local24.x, _local24.y)) {
                        SoundEffectLibrary.play("error");
                        return false;
                    }
                }
            }
            if (param3 == 1) {
                if (param4 < this.nextAltAttack_) {
                    SoundEffectLibrary.play("error");
                    return false;
                }
                _local26 = param6.MpCost;
                if (_local26 > this.mp_) {
                    SoundEffectLibrary.play("no_mana");
                    return false;
                }
                _local15 = 520;
                if ("Cooldown" in param6) {
                    _local15 = param6.Cooldown * 1000;
                }
                this.nextAltAttack_ = param4 + _local15;
                this.mpZeroed_ = false;
                if (_local24) {
                    map_.gs_.gsc_.useItem(param4, objectId_, 1, _local8, _local24.x, _local24.y, param3);
                } else {
                    map_.gs_.gsc_.useItem(param4, objectId_, 1, _local8, x_, y_, param3);
                }
                if (_local18) {
                    this.doShoot(param4, _local8, param6, _local17, false, false);
                }
            } else if ("MultiPhase" in param6) {
                map_.gs_.gsc_.useItem(param4, objectId_, 1, _local8, _local24.x, _local24.y, param3);
                _local26 = param6.MpEndCost;
                if (_local26 <= this.mp_ && !this.mpZeroed_ && !map_.isPetYard && !map_.isQuestRoom) {
                    this.doShoot(param4, _local8, param6, _local17, false, false);
                }
            }
            return true;
        }
        
        public function getAttribute(_arg_1: XML, _arg_2: String, _arg_3: Number = 0): Number {
            return !!_arg_1.hasOwnProperty("@" + _arg_2) ? _arg_1[_arg_2] : _arg_3;
        }
        
        public function isHexed(): Boolean {
            return (condition_[0] & 134217728) != 0;
        }
        
        public function isInventoryFull(): Boolean {
            var _local1: int = 0;
            if (equipment_ == null) {
                return false;
            }
            var _local2: uint = equipment_.length;
            _local1 = 4;
            while (_local1 < _local2) {
                if (equipment_[_local1] == -1) {
                    return false;
                }
                _local1++;
            }
            return true;
        }
        
        public function nextAvailableInventorySlot(): int {
            var _local1: int = 0;
            var _local2: uint = !!this.hasBackpack_ ? equipment_.length : equipment_.length - 8;
            _local1 = 4;
            while (_local1 < _local2) {
                if (equipment_[_local1] <= 0) {
                    return _local1;
                }
                _local1++;
            }
            return -1;
        }
        
        public function numberOfAvailableSlots(): int {
            var _local3: int = 0;
            var _local2: int = 0;
            var _local1: uint = !!this.hasBackpack_ ? equipment_.length : equipment_.length - 8;
            _local3 = 4;
            while (_local3 < _local1) {
                if (equipment_[_local3] <= 0) {
                    _local2++;
                }
                _local3++;
            }
            return _local2;
        }
        
        public function swapInventoryIndex(_arg_1: String): int {
            var _local3: * = 0;
            var _local2: int = 0;
            var _local4: * = 0;
            if (!this.hasBackpack_) {
                return -1;
            }
            if (_arg_1 == "Backpack") {
                _local2 = 4;
                _local4 = 12;
            } else {
                _local2 = 12;
                _local4 = uint(equipment_.length);
            }
            _local3 = _local2;
            while (_local3 < _local4) {
                if (equipment_[_local3] <= 0) {
                    return _local3;
                }
                _local3++;
            }
            return -1;
        }
        
        public function getPotionCount(_arg_1: int): int {
            switch (int(_arg_1) - 2594) {
                case 0:
                    return this.healthPotionCount_;
                case 1:
                    return this.magicPotionCount_;
            }
            
            return 0;
        }
        
        public function getTex1(): int {
            return tex1Id_;
        }
        
        public function getTex2(): int {
            return tex2Id_;
        }
        
        public function getClosestBag(_arg_1: Boolean): Container {
            var _local2: Number = NaN;
            var _local5: * = null;
            var _local4: * = null;
            var _local3: * = Infinity;
            var _local7: int = 0;
            var _local6: * = map_.goDict_;
            for each(_local4 in map_.goDict_) {
                if (_local4 is Container) {
                    _local2 = getDistSquared(_local4.x_, _local4.y_, x_, y_);
                    if (_local2 < _local3) {
                        if (_arg_1) {
                            if (_local2 <= 1) {
                                _local5 = _local4;
                            }
                        } else {
                            _local5 = _local4;
                        }
                        _local3 = _local2;
                    }
                }
            }
            return _local5 as Container;
        }
        
        public function getClosestPortal(_arg_1: Boolean): Portal {
            var _local2: Number = NaN;
            var _local5: * = null;
            var _local4: * = null;
            var _local3: * = Infinity;
            var _local7: int = 0;
            var _local6: * = map_.goDict_;
            for each(_local4 in map_.goDict_) {
                if (_local4 is Portal) {
                    _local2 = getDistSquared(_local4.x_, _local4.y_, x_, y_);
                    if (_local2 < _local3) {
                        if (_arg_1) {
                            if (_local2 <= 1) {
                                _local5 = _local4;
                            }
                        } else {
                            _local5 = _local4;
                        }
                        _local3 = _local2;
                    }
                }
            }
            return _local5 as Portal;
        }
        
        public function getClosestChest(_arg_1: Boolean): Container {
            var _local5: Number = NaN;
            var _local2: * = null;
            var _local4: * = null;
            var _local3: * = Infinity;
            var _local7: int = 0;
            var _local6: * = map_.goDict_;
            for each(_local4 in map_.goDict_) {
                if (_local4.objectType_ == 1284) {
                    _local5 = getDistSquared(_local4.x_, _local4.y_, x_, y_);
                    if (_local5 < _local3) {
                        if (_arg_1) {
                            if (_local5 <= 1) {
                                _local2 = _local4;
                            }
                        } else {
                            _local2 = _local4;
                        }
                        _local3 = _local5;
                    }
                }
            }
            return _local2 as Container;
        }
        
        public function sToW(_arg_1: Number, _arg_2: Number): Point {
            var _local4: Number = Parameters.data.cameraAngle;
            var _local7: Number = Math.cos(_local4);
            var _local3: Number = Math.sin(_local4);
            _arg_1 = _arg_1 / 50;
            _arg_2 = _arg_2 / 50;
            var _local6: Number = _arg_1 * _local7 - _arg_2 * _local3;
            var _local5: Number = _arg_1 * _local3 + _arg_2 * _local7;
            return new Point(this.x_ + _local6, this.y_ + _local5);
        }
        
        public function wToS_opti(_arg_1: Number, _arg_2: Number): Point {
            var _local4: Number = Parameters.data.cameraAngle;
            var _local3: Number = Math.cos(_local4);
            _local4 = Math.sin(_local4);
            var _local5: Point = new Point(_arg_1 - x_, _arg_2 - y_);
            _arg_1 = (_local5.x * _local3 + _local5.y * _local4) * 50.5;
            _arg_2 = (_local5.y * _local3 - _local5.x * _local4) * 50.5;
            _local5.x = _arg_1;
            _local5.y = _arg_2;
            return _local5;
        }
        
        public function handleTradePotsCommand(_arg_1: Text): void {
            var _local12: int = 0;
            if (MoreStringUtil.countCharInString(_arg_1.text_, ".") != 7) {
                return;
            }
            if (!this.map_.goDict_[_arg_1.objectId_]) {
                return;
            }
            var _local10: Player = this.map_.goDict_[_arg_1.objectId_] as Player;
            if (getDistSquared(this.x_, this.y_, _local10.x_, _local10.y_) > 0.01) {
                return;
            }
            var _local11: Array = _arg_1.text_.substring(2).split(".");
            var _local8: int = _local11[0];
            var _local3: int = _local11[1];
            var _local4: int = _local11[2];
            var _local6: int = _local11[3];
            var _local7: int = _local11[4];
            var _local13: int = _local11[5];
            var _local9: int = _local11[6];
            var _local2: int = _local11[7];
            var _local5: Vector.<Boolean> = new <Boolean>[false, false, false, false, false, false, false, false, false, false, false, false];
            if (_local8 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(0, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local3 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(2, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local4 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(1, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local6 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(3, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local7 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(4, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local13 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(5, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local9 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(6, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local2 > 0) {
                _local12 = 4;
                while (_local12 < 12) {
                    if (isPotId(7, this.equipment_[_local12])) {
                        _local5[_local12] = true;
                    }
                    _local12++;
                }
            }
            if (_local5.indexOf(true) > -1) {
                this.addTextLine.dispatch(ChatMessage.make("Potions", "We have a potion " + _local10.name_ + " needs!"));
                this.map_.gs_.gsc_.playerText("/trade " + _arg_1.name_);
                Parameters.givingPotions = true;
                Parameters.potionsToTrade = _local5;
                Parameters.recvrName = _arg_1.name_;
                return;
            }
            this.addTextLine.dispatch(ChatMessage.make("Potions", "We have nothing they need"));
        }
        
        public function isPotId(_arg_1: int, _arg_2: int): Boolean {
            switch (int(_arg_1)) {
                case 0:
                    return _arg_2 == 2591 || _arg_2 == 5465 || _arg_2 == 9064;
                case 1:
                    return _arg_2 == 2592 || _arg_2 == 5466 || _arg_2 == 9065;
                case 2:
                    return _arg_2 == 2593 || _arg_2 == 5467 || _arg_2 == 9066;
                case 3:
                    return _arg_2 == 2636 || _arg_2 == 5470 || _arg_2 == 9069;
                case 4:
                    return _arg_2 == 2612 || _arg_2 == 5468 || _arg_2 == 9067;
                case 5:
                    return _arg_2 == 2613 || _arg_2 == 5469 || _arg_2 == 9068;
                case 6:
                    return _arg_2 == 2793 || _arg_2 == 5471 || _arg_2 == 9070;
                case 7:
                    return _arg_2 == 2794 || _arg_2 == 5472 || _arg_2 == 9071;
            }
            
            return false;
        }
        
        public function getPotType(_arg_1: int): int {
            if (_arg_1 == 2591 || _arg_1 == 5465 || _arg_1 == 9064) {
                return 0;
            }
            if (_arg_1 == 2592 || _arg_1 == 5466 || _arg_1 == 9065) {
                return 1;
            }
            if (_arg_1 == 2593 || _arg_1 == 5467 || _arg_1 == 9066) {
                return 2;
            }
            if (_arg_1 == 2636 || _arg_1 == 5470 || _arg_1 == 9069) {
                return 3;
            }
            if (_arg_1 == 2612 || _arg_1 == 5468 || _arg_1 == 9067) {
                return 4;
            }
            if (_arg_1 == 2613 || _arg_1 == 5469 || _arg_1 == 9068) {
                return 5;
            }
            if (_arg_1 == 2793 || _arg_1 == 5471 || _arg_1 == 9070) {
                return 6;
            }
            if (_arg_1 == 2794 || _arg_1 == 5472 || _arg_1 == 9071) {
                return 7;
            }
            return -1;
        }
        
        public function shouldDrink(_arg_1: int): Boolean {
            if (_arg_1 == 0) {
                return attackMax_ - (attack_ - attackBoost_) > 0;
            }
            if (_arg_1 == 1) {
                return defenseMax_ - (defense_ - defenseBoost_) > 0;
            }
            if (_arg_1 == 2) {
                return speedMax_ - (speed_ - speedBoost_) > 0;
            }
            if (_arg_1 == 3) {
                return dexterityMax_ - (dexterity_ - dexterityBoost_) > 0;
            }
            if (_arg_1 == 4) {
                return vitalityMax_ - (vitality_ - vitalityBoost_) > 0;
            }
            if (_arg_1 == 5) {
                return wisdomMax_ - (wisdom - wisdomBoost_) > 0;
            }
            if (_arg_1 == 6) {
                return Math.ceil((maxHPMax_ - (maxHP_ - maxHPBoost_)) * 0.2) > 0;
            }
            if (_arg_1 == 7) {
                return Math.ceil((maxMPMax_ - (maxMP_ - maxMPBoost_)) * 0.2) > 0;
            }
            return false;
        }
        
        public function textNotification(message: String, color: int = 16777215, lifetime: int = 1000, effect: Boolean = false): void {
            if (effect)
                map_.addObj(new LevelUpEffect(this, color | 2130706432, 20), x_, y_);
            
            var messageText: CharacterStatusText = new CharacterStatusText(this, color, lifetime);
            messageText.setText(message);
            map_.mapOverlay_.addStatusText(messageText);
        }
        
        public function rgbToDecimal(color: Array): int {
            var r: int = color[0];
            var g: int = color[1];
            var b: int = color[2];
            
            var result: int = (r << 16) + (g << 8) + b;
            return result;
        }
        
        public function sbAssist(_arg_1: int, _arg_2: int): void {
            var _local5: Number = NaN;
            var _local9: * = null;
            var _local7: int = this.equipment_[1];
            if (_local7 == -1) {
                return;
            }
            var _local4: XML = ObjectLibrary.xmlLibrary_[_local7];
            for each(var _local10: XML in _local4.Activate) {
                if (_local10.toString() == "Teleport") {
                    this.useAltWeapon(_arg_1, _arg_2, 1, -1, false);
                    return;
                }
            }
            var _local6: Point = sToW(_arg_1, _arg_2);
            var _local3: * = Infinity;
            for each(var _local8: GameObject in map_.vulnEnemyDict_) {
                _local5 = getDistSquared(_local8.x_, _local8.y_, _local6.x, _local6.y);
                if (_local5 < _local3) {
                    _local3 = _local5;
                    _local9 = _local8;
                }
            }
            if (_local3 <= 25) {
                this.useAltWeapon(_local9.x_, _local9.y_, 1, -1, true);
            } else {
                this.useAltWeapon(_arg_1, _arg_2, 1, -1, false);
            }
        }
        
        public function jump(): void {
        }
        
        protected function drawBreathBar(gfx: Vector.<GraphicsBitmapFill>, time: int): void {
            if (this.breathBarFill == null || this.breathBarBackFill == null) {
                this.breathBarFill = new GraphicsBitmapFill();
                this.breathBarBackFill = new GraphicsBitmapFill();
            }
            
            var color: uint = 0x111111;
            if (this.breath_ <= 20)
                color = MoreColorUtil.lerpColor(0x111111, 0xff0000,
                        Math.abs(Math.sin(time / 300)) * ((20 - this.breath_) / 20));
            
            this.breathBarBackFill.bitmapData = TextureRedrawer.redrawSolidSquare(color, 42, 7, -1);
            var posX: int = posS_[0];
            var posY: int = posS_[1];
            this.breathBarBackFillMatrix.identity();
            this.breathBarBackFillMatrix.translate(posX - 20 - 5 - 1, posY + 9 - 1);
            this.breathBarBackFill.matrix = this.breathBarBackFillMatrix;
            gfx.push(this.breathBarBackFill);
            if (this.breath_ > 0) {
                var width: int = this.breath_ * 0.4;
                this.breathBarFill.bitmapData = TextureRedrawer.redrawSolidSquare(0x26CAFF, width, 5, -1);
                this.breathBarFillMatrix.identity();
                this.breathBarFillMatrix.translate(posX - 20 - 5, posY + 9);
                this.breathBarFill.matrix = this.breathBarFillMatrix;
                gfx.push(this.breathBarFill);
            }
        }
        
        private function bForceExp(): Boolean {
            return Parameters.data.forceEXP == 1 || Parameters.data.forceEXP == 2 && map_.player_ == this;
        }
        
        private function getNearbyMerchant(): Merchant {
            var _local1: * = null;
            var _local3: * = null;
            var _local4: int = x_ - x_ > 0.5 ? 1 : -1;
            var _local2: int = y_ - y_ > 0.5 ? 1 : -1;
            var _local6: int = 0;
            var _local5: * = NEARBY;
            for each(_local1 in NEARBY) {
                this.ip_.x_ = x_ + _local4 * _local1.x;
                this.ip_.y_ = y_ + _local2 * _local1.y;
                _local3 = map_.merchLookup_[this.ip_];
                if (_local3) {
                    return this.getDistSquared(_local3.x_, _local3.y_, x_, y_) < 1 ? _local3 : null;
                }
            }
            return null;
        }
        
        private function resetMoveVector(_arg_1: Boolean): void {
            moveVec_.scaleBy(-0.5);
            if (_arg_1) {
                moveVec_.y = moveVec_.y * -1;
            } else {
                moveVec_.x = moveVec_.x * -1;
            }
        }
        
        private function calcHealth(_arg_1: int): void {
            var multiplier: Number = _arg_1 * 0.001;
            var _local5: Number = 1 + 0.12 * this.vitality_ * (this.icMS != -1 ? 1 : 2);
            var drowning: Boolean = this.map_.isTrench && this.breath_ == 0;
            
            if (!this.isSick && !this.isBleeding_()) {
                this.hpLog = this.hpLog + _local5 * multiplier;
                if (this.isHealing_()) {
                    this.hpLog = this.hpLog + 20 * multiplier;
                }
            } else if (this.isBleeding_()) {
                this.hpLog = this.hpLog - 20 * multiplier;
            }
            if (drowning) {
                this.hpLog = this.hpLog - Parameters.drownDamagePerSec * multiplier;
            }
            var oldHP: int = this.hpLog;
            var newHP: Number = this.hpLog - oldHP;
            this.hpLog = newHP;
            this.clientHp = this.clientHp + oldHP;
            if (this.clientHp > this.maxHP_) {
                this.clientHp = this.maxHP_;
            }
        }
        
        private function lookForMpPotAndDrink(_arg_1: int): void {
            var _local2: int = 0;
            var _local3: int = 0;
            var _local4: Boolean = false;
            var _local5: int = !!this.hasBackpack_ ? 20 : 12;
            _local3 = 4;
            while (_local3 < _local5) {
                _local2 = this.equipment_[_local3];
                if (_local2 == 0xa23 || _local2 == 0xc1a) {
                    this.map_.gs_.gsc_.useItem(_arg_1, this.objectId_, _local3, _local2, this.x_, this.y_, 1);
                    _local4 = true;
                    break;
                }
                _local3++;
            }
            if (!_local4 && this.magicPotionCount_ > 0) {
                this.map_.gs_.mui_.useBuyPotionSignal.dispatch(mpPotionVO);
                _local4 = true;
            }
            if (_local4) {
                this.lastMpPotTime = _arg_1;
            }
        }
        
        private function numStarsToImage(_arg_1: int): Sprite {
            var _local3: uint = ObjectLibrary.playerChars_.length;
            var _local2: Sprite = new StarGraphic();
            if (_arg_1 < _local3) {
                _local2.transform.colorTransform = lightBlueCT;
            } else if (_arg_1 < _local3 * 2) {
                _local2.transform.colorTransform = darkBlueCT;
            } else if (_arg_1 < _local3 * 3) {
                _local2.transform.colorTransform = redCT;
            } else if (_arg_1 < _local3 * 4) {
                _local2.transform.colorTransform = orangeCT;
            } else if (_arg_1 < _local3 * 5) {
                _local2.transform.colorTransform = yellowCT;
            }
            return _local2;
        }
        
        private function getNameColor(): uint {
            return PlayerUtil.getPlayerNameColor(this);
        }
        
        private function getMoveSpeed(): Number {
            var _local1: Number = NaN;
            if (this.isSlowed) {
                return 0.004 * this.moveMultiplier_;
            }
            _local1 = 0.004 + this.speed_ * 0.0133333333333333 * 0.0056;
            if (this.isSpeedy || this.isNinjaSpeedy) {
                _local1 = _local1 * 1.5;
            }
            return _local1 * this.moveMultiplier_ * (this.isWalking ? 0.5 : 1);
        }
        
        private function attackMultiplier(): Number {
            if (this.isWeak) {
                return 0.5;
            }
            var _local1: Number = 0.5 + this.attack_ * 0.0133333333333333 * 1.5;
            if (this.isDamaging) {
                _local1 = _local1 * 1.5;
            }
            return _local1;
        }
        
        private function makeSkinTexture(): void {
            var _local1: MaskedImage = this.skin.imageFromAngle(0, 0, 0);
            animatedChar_ = this.skin;
            texture = _local1.image_;
            mask_ = _local1.mask_;
            this.isDefaultAnimatedChar = true;
        }
        
        private function setToRandomAnimatedCharacter(): void {
            var _local4: Vector.<XML> = ObjectLibrary.hexTransforms_;
            var _local2: uint = Math.floor(Math.random() * _local4.length);
            var _local1: int = _local4[_local2].@type;
            var _local3: TextureData = ObjectLibrary.typeToTextureData_[_local1];
            texture = _local3.texture_;
            mask_ = _local3.mask_;
            animatedChar_ = _local3.animatedChar_;
            this.isDefaultAnimatedChar = false;
        }
        
        private function shoot(_arg_1: Number, _arg_2: int = -1): void {
            if (map_ == null || this.isStunned_() || this.isPaused_() || this.isPetrified_()) {
                return;
            }
            var _local4: int = equipment_[0];
            if (_local4 == -1) {
                this.addTextLine.dispatch(ChatMessage.make("*Error*", "player.noWeaponEquipped"));
                return;
            }
            var _local3: XML = ObjectLibrary.xmlLibrary_[_local4];
            if (_arg_2 == -1) {
                _arg_2 = getTimer();
            }
            var _local5: Number = _local3.RateOfFire;
            this.attackPeriod_ = 1 / this.attackFrequency() * (1 / _local5);
            if (_arg_2 < attackStart_ + this.attackPeriod_) {
                return;
            }
            attackAngle_ = _arg_1;
            attackStart_ = _arg_2;
            this.doShoot(attackStart_, _local4, _local3, attackAngle_, true, true);
        }
        
        private function doShoot(param1: int, param2: int, param3: XML, param4: Number, param5: Boolean, param6: Boolean): void {
            var _local9: * = 0;
            var _local13: * = null;
            var _local18: int = 0;
            var _local11: int = 0;
            var _local12: Number = NaN;
            var _local7: int = 0;
            var _local14: int = 0;
            var _local15: int = "NumProjectiles" in param3 ? int(param3.NumProjectiles) : 1;
            var _local19: Number = ("ArcGap" in param3 ? Number(param3.ArcGap) : 11.25) * 0.0174532925199433;
            var _local16: Number = _local19 * (_local15 - 1);
            var _local17: Number = param4 - _local16 * 0.5;
            var _local8: Number = !!param6 ? this.projectileLifeMult : 1;
            var _local10: Number = !!param6 ? this.projectileSpeedMult : 1;
            if (!isNaN(param4)) {
                this.isShooting = param5;
            }
            if (param2 == 580 && Parameters.data.cultiststaffDisable) {
                _local17 = _local17 + 3.14159265358979;
            }
            _local14 = 0;
            while (_local14 < _local15) {
                _local9 = uint(getBulletId());
                if (param2 == 8608 && Parameters.data.ethDisable) {
                    _local17 = _local17 + (_local9 % 2 != 0 ? 0.0436332312998582 : -0.0436332312998582);
                } else if (param2 == 588 && Parameters.data.offsetVoidBow) {
                    _local17 = _local17 + (_local9 % 2 != 0 ? 0.06 : -0.06);
                } else if (param2 == 596 && Parameters.data.offsetColossus) {
                    _local17 = _local17 + (_local9 % 2 != 0 ? Parameters.data.coloOffset : -Parameters.data.coloOffset);
                } else if (param2 == 30053 && Parameters.data.offsetCelestialBlade) {
                    _local17 = _local17 + (_local9 % 2 != 0 ? 0.12 : -0.12);
                }
                _local13 = FreeList.newObject(Projectile) as Projectile;
                if (param5 && this.projectileIdSetOverrideNew != "") {
                    _local13.reset(param2, 0, objectId_, _local9, _local17, param1, this.projectileIdSetOverrideNew, this.projectileIdSetOverrideOld, _local8, _local10);
                } else {
                    _local13.reset(param2, 0, objectId_, _local9, _local17, param1, "", "", _local8, _local10);
                }
                _local18 = _local13.projProps_.minDamage_;
                _local11 = _local13.projProps_.maxDamage_;
                _local12 = !!param5 ? Number(this.attackMultiplier()) : 1;
                _local7 = map_.gs_.gsc_.getNextDamage(_local18, _local11) * _local12;
                if (param1 > map_.gs_.moveRecords_.lastClearTime_ + 10 * 60) {
                    _local7 = 0;
                }
                _local13.setDamage(_local7);
                if (_local14 == 0 && _local13.sound_) {
                    SoundEffectLibrary.play(_local13.sound_, 0.75, false);
                }
                map_.addObj(_local13, x_ + Math.cos(param4) * 0.3, y_ + Math.sin(param4) * 0.3);
                map_.gs_.gsc_.playerShoot(param1, _local13);
                _local17 = _local17 + _local19;
                _local14++;
            }
        }
    }
}