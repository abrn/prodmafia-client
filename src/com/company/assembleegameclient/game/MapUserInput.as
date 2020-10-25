package com.company.assembleegameclient.game {
import com.company.assembleegameclient.game.events.ReconnectEvent;
import com.company.assembleegameclient.objects.GameObject;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.sound.SoundEffectLibrary;
import com.company.assembleegameclient.ui.options.Options;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.assembleegameclient.util.redrawers.GlowRedrawer;
import com.company.util.PointUtil;

import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.system.Capabilities;
import flash.utils.getTimer;

import io.decagames.rotmg.social.SocialPopupView;
import io.decagames.rotmg.ui.popups.signals.CloseAllPopupsSignal;
import io.decagames.rotmg.ui.popups.signals.ClosePopupByClassSignal;
import io.decagames.rotmg.ui.popups.signals.ShowPopupSignal;

import kabam.rotmg.application.api.ApplicationSetup;
import kabam.rotmg.chat.control.ParseChatMessageSignal;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.core.view.Layers;
import kabam.rotmg.dialogs.control.CloseDialogsSignal;
import kabam.rotmg.dialogs.control.OpenDialogSignal;
import kabam.rotmg.game.model.PotionInventoryModel;
import kabam.rotmg.game.model.UseBuyPotionVO;
import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.game.signals.ExitGameSignal;
import kabam.rotmg.game.signals.GiftStatusUpdateSignal;
import kabam.rotmg.game.signals.SetTextBoxVisibilitySignal;
import kabam.rotmg.game.signals.UseBuyPotionSignal;
import kabam.rotmg.game.view.components.StatsTabHotKeyInputSignal;
import kabam.rotmg.minimap.control.MiniMapZoomSignal;
import kabam.rotmg.ui.model.TabStripModel;
import kabam.rotmg.ui.signals.ToggleRealmQuestsDisplaySignal;

import net.hires.debug.Stats;

import org.swiftsuspenders.Injector;

public class MapUserInput {
    public static var stats_:Stats = new Stats();

    public static function addIgnore(_arg_1:int):String {
        var _local2:* = null;
        for each(var _local3:int in Parameters.data.AAIgnore) {
            if (_local3 == _arg_1) {
                return _arg_1 + " already exists in Ignore list";
            }
        }
        if (_arg_1 in ObjectLibrary.propsLibrary_) {
            Parameters.data.AAIgnore.push(_arg_1);
            _local2 = ObjectLibrary.propsLibrary_[_arg_1];
            _local2.ignored = true;
            return "Successfully added " + _arg_1 + " to Ignore list";
        }
        return "Failed to add " + _arg_1 + " to Ignore list (no known object with this itemType)";
    }

    public static function remIgnore(_arg_1:int):String {
        var _local4:int = 0;
        var _local2:* = null;
        var _local3:uint = Parameters.data.AAIgnore.length;
        _local4 = 0;
        while (_local4 < _local3) {
            if (Parameters.data.AAIgnore[_local4] == _arg_1) {
                Parameters.data.AAIgnore.splice(_local4, 1);
                if (_arg_1 in ObjectLibrary.propsLibrary_) {
                    _local2 = ObjectLibrary.propsLibrary_[_arg_1];
                    _local2.ignored = false;
                }
                return "Successfully removed " + _arg_1 + " from Ignore list";
            }
            _local4++;
        }
        return _arg_1 + " not found in Ignore list";
    }

    public function MapUserInput(_arg_1:GameSprite) {
        super();
        this.gs_ = _arg_1;
        this.gs_.addEventListener("addedToStage", this.onAddedToStage, false, 0, true);
        this.gs_.addEventListener("removedFromStage", this.onRemovedFromStage, false, 0, true);
        var _local3:Injector = StaticInjectorContext.getInjector();
        this.giftStatusUpdateSignal = _local3.getInstance(GiftStatusUpdateSignal);
        this.addTextLine = _local3.getInstance(AddTextLineSignal);
        this.setTextBoxVisibility = _local3.getInstance(SetTextBoxVisibilitySignal);
        this.miniMapZoom = _local3.getInstance(MiniMapZoomSignal);
        this.useBuyPotionSignal = _local3.getInstance(UseBuyPotionSignal);
        this.potionInventoryModel = _local3.getInstance(PotionInventoryModel);
        this.tabStripModel = _local3.getInstance(TabStripModel);
        this.layers = _local3.getInstance(Layers);
        this.statsTabHotKeyInputSignal = _local3.getInstance(StatsTabHotKeyInputSignal);
        this.toggleRealmQuestsDisplaySignal = _local3.getInstance(ToggleRealmQuestsDisplaySignal);
        this.exitGame = _local3.getInstance(ExitGameSignal);
        this.openDialogSignal = _local3.getInstance(OpenDialogSignal);
        this.closeDialogSignal = _local3.getInstance(CloseDialogsSignal);
        this.closePopupByClassSignal = _local3.getInstance(ClosePopupByClassSignal);
        var _local2:ApplicationSetup = _local3.getInstance(ApplicationSetup);
        this.areFKeysAvailable = _local2.areDeveloperHotkeysEnabled();
        this.pcmc = _local3.getInstance(ParseChatMessageSignal);
    }
    public var gs_:GameSprite;
    public var mouseDown_:Boolean = false;
    public var autofire_:Boolean = false;
    public var held:Boolean = false;
    public var heldX:int = 0;
    public var heldY:int = 0;
    public var heldAngle:Number = 0;
    public var useBuyPotionSignal:UseBuyPotionSignal;
    [Inject]
    public var pcmc:ParseChatMessageSignal;
    private var moveLeft_:Boolean = false;
    private var moveRight_:Boolean = false;
    private var moveUp_:Boolean = false;
    private var moveDown_:Boolean = false;
    private var isWalking:Boolean = false;
    private var rotateLeft_:Boolean = false;
    private var rotateRight_:Boolean = false;
    private var specialKeyDown_:Boolean = false;
    private var enablePlayerInput_:Boolean = true;
    private var giftStatusUpdateSignal:GiftStatusUpdateSignal;
    private var addTextLine:AddTextLineSignal;
    private var setTextBoxVisibility:SetTextBoxVisibilitySignal;
    private var statsTabHotKeyInputSignal:StatsTabHotKeyInputSignal;
    private var toggleRealmQuestsDisplaySignal:ToggleRealmQuestsDisplaySignal;
    private var miniMapZoom:MiniMapZoomSignal;
    private var potionInventoryModel:PotionInventoryModel;
    private var openDialogSignal:OpenDialogSignal;
    private var closeDialogSignal:CloseDialogsSignal;
    private var closePopupByClassSignal:ClosePopupByClassSignal;
    private var tabStripModel:TabStripModel;
    private var layers:Layers;
    private var exitGame:ExitGameSignal;
    private var areFKeysAvailable:Boolean;
    private var isFriendsListOpen:Boolean;

    public function clearInput():void {
        this.moveLeft_ = false;
        this.moveRight_ = false;
        this.moveUp_ = false;
        this.moveDown_ = false;
        this.isWalking = false;
        this.rotateLeft_ = false;
        this.rotateRight_ = false;
        this.mouseDown_ = false;
        this.autofire_ = false;
        if (gs_.map.player_) {
            gs_.map.player_.setControllerMovementXY(0, 0);
        }
        this.setPlayerMovement();
    }

    public function setEnablePlayerInput(_arg_1:Boolean):void {
        if (this.enablePlayerInput_ != _arg_1) {
            this.enablePlayerInput_ = _arg_1;
            this.clearInput();
        }
    }

    public function useHPPot(_arg_1:Player):void {
        var _local2:int = 0;
        if (_arg_1.hp_ != _arg_1.maxHP_) {
            if (_arg_1.healthPotionCount_ == 0 && !Parameters.data.fameBlockThirsty) {
                _local2 = _arg_1.findItems(_arg_1.equipment_, Parameters.hpPotions, 4);
                if (_local2 != -1) {
                    this.gs_.gsc_.useItem(getTimer(), _arg_1.objectId_, _local2, _arg_1.equipment_[_local2], _arg_1.x_, _arg_1.y_, 1);
                }
            } else {
                this.useBuyPotionSignal.dispatch(new UseBuyPotionVO(2594, UseBuyPotionVO.CONTEXTBUY));
            }
        }
    }

    public function useMPPot(_arg_1:Player):void {
        var _local2:int = 0;
        if (_arg_1.mp_ != _arg_1.maxMP_) {
            if (_arg_1.magicPotionCount_ == 0 && !Parameters.data.fameBlockThirsty) {
                _local2 = _arg_1.findItems(_arg_1.equipment_, Parameters.mpPotions, 4);
                if (_local2 != -1) {
                    this.gs_.gsc_.useItem(getTimer(), _arg_1.objectId_, _local2, _arg_1.equipment_[_local2], _arg_1.x_, _arg_1.y_, 1);
                }
            } else {
                this.useBuyPotionSignal.dispatch(new UseBuyPotionVO(2595, UseBuyPotionVO.CONTEXTBUY));
            }
        }
    }

    public function teleQuest(_arg_1:Player):void {
        var _local3:* = NaN;
        var _local6:int = 0;
        var _local7:Number = NaN;
        var _local5:* = null;
        var _local2:int = gs_.map.quest_.objectId_;
        if (_local2 > 0) {
            _local5 = gs_.map.quest_.getObject(_local2);
            if (_local5) {
                _local3 = Infinity;
                _local6 = -1;
                for each(var _local4:GameObject in this.gs_.map.goDict_) {
                    if (_local4 is Player && !_local4.isInvisible && !_local4.isPaused) {
                        _local7 = (_local4.x_ - _local5.x_) * (_local4.x_ - _local5.x_) + (_local4.y_ - _local5.y_) * (_local4.y_ - _local5.y_);
                        if (_local7 < _local3) {
                            _local3 = _local7;
                            _local6 = _local4.objectId_;
                        }
                    }
                }
                if (_local6 == _arg_1.objectId_) {
                    _arg_1.textNotification("You are closest!", 0xffffff, 25 * 60, false);
                } else {
                    this.gs_.gsc_.teleport(_local6);
                    _arg_1.textNotification("Teleporting to " + this.gs_.map.goDict_[_local6].name_, 0xffffff, 25 * 60, false);
                }
            }
        } else {
            _arg_1.textNotification("You have no quest!", 0xffffff, 25 * 60, false);
        }
    }

    public function findKeys():void {
        var _local5:int = 0;
        var _local7:int = 0;
        var _local6:* = null;
        var _local3:* = null;
        var _local2:String = "";
        for each(var _local1:GameObject in this.gs_.map.goDict_) {
            if (_local1 is Player) {
                _local5 = 0;
                while (_local5 < 20) {
                    _local7 = _local1.equipment_[_local5];
                    _local6 = ObjectLibrary.xmlLibrary_[_local7];
                    if (_local6 && "Consumable" in _local6) {
                        for each(var _local4:XML in _local6.Activate) {
                            _local3 = _local4.toString();
                            if (_local3 == "Create" || _local3 == "UnlockPortal" || _local3 == "CreatePortal") {
                                _local2 = _local2 + (_local1.name_ + " has " + _local6.@id + "\n");
                            }
                        }
                    }
                    _local5++;
                }

            }
        }
        this.gs_.map.player_.textNotification(_local2, 16762889, 100 * 60, false);
    }

    public function selectAimMode():void {
        var modeStr:String = "";
        var mode:int = (Parameters.data.aimMode + 1) % 4;
        switch (mode) {
            case 0:
                modeStr = "AimMode: Mouse";
                break;
            case 1:
                modeStr = "AimMode: Health";
                break;
            case 2:
                modeStr = "AimMode: Closest";
                break;
            case 3:
                modeStr = "AimMode: Random";
        }
        if (this.gs_ && this.gs_.map && this.gs_.map.player_) {
            this.gs_.map.player_.textNotification(modeStr, 0xffffff, 2000, false);
        }
        Parameters.data.aimMode = mode;
    }

    private function fixJoystick(_arg_1:Vector3D):Vector3D {
        var _local2:Number = _arg_1.length;
        if (_local2 < 0.2) {
            _arg_1.x = 0;
            _arg_1.y = 0;
        } else {
            _arg_1.normalize();
            _arg_1.scaleBy((_local2 - 0.2) / 0.8);
        }
        return _arg_1;
    }

    private function setPlayerMovement():void {
        var _local1:Player = this.gs_.map.player_;
        if (_local1) {
            if (this.enablePlayerInput_) {
                _local1.setRelativeMovement((!!this.rotateRight_ ? 1 : 0) - (!!this.rotateLeft_ ? 1 : 0), (!!this.moveRight_ ? 1 : 0) - (!!this.moveLeft_ ? 1 : 0), (!!this.moveDown_ ? 1 : 0) - (!!this.moveUp_ ? 1 : 0));
            } else {
                _local1.setRelativeMovement(0, 0, 0);
            }
            _local1.isWalking = this.isWalking;
        }
    }

    private function useItem(_arg_1:int):void {
        if (Parameters.data.fixTabHotkeys && this.tabStripModel.currentSelection == "Backpack") {
            _arg_1 = _arg_1 + 8;
        }
        this.gs_.gsc_.useItem_new(this.gs_.map.player_, _arg_1);
    }

    private function swapTooSoon():Boolean {
        var _local1:int = getTimer();
        if (this.gs_.gsc_.lastInvSwapTime + 500 > _local1) {
            SoundEffectLibrary.play("error");
            return true;
        }
        this.gs_.gsc_.lastInvSwapTime = _local1;
        return false;
    }

    private function togglePerformanceStats():void {
        if (Parameters.data.liteMonitor) {
            if (this.gs_.stats) {
                this.gs_.stats.visible = false;
                this.gs_.stats = null;
            } else {
                this.gs_.addStats();
                this.gs_.statsStart = getTimer();
                this.gs_.stage.dispatchEvent(new Event("resize"));
            }
        } else if (this.gs_.contains(stats_)) {
            this.gs_.removeChild(stats_);
            this.gs_.removeChild(this.gs_.gsc_.jitterWatcher_);
            this.gs_.gsc_.disableJitterWatcher();
        } else {
            this.gs_.addChild(stats_);
            this.gs_.gsc_.enableJitterWatcher();
            this.gs_.gsc_.jitterWatcher_.y = stats_.height;
            this.gs_.addChild(this.gs_.gsc_.jitterWatcher_);
        }
        Parameters.data.perfStats = !Parameters.data.perfStats;
        Parameters.save();
    }

    public function onMiddleClick(_arg_1:MouseEvent):void {
        var _local4:* = NaN;
        var _local5:Number = NaN;
        var _local2:* = null;
        var _local3:* = null;
        if (this.gs_.map) {
            _local2 = this.gs_.map.player_.sToW(this.gs_.map.mouseX, this.gs_.map.mouseY);
            _local4 = Infinity;
            for each(var _local6:GameObject in this.gs_.map.goDict_) {
                if (_local6.props_.isEnemy_) {
                    _local5 = PointUtil.distanceSquaredXY(_local6.x_, _local6.y_, _local2.x, _local2.y);
                    if (_local5 < _local4) {
                        _local4 = _local5;
                        _local3 = _local6;
                    }
                }
            }
            if (_local3) {
                this.gs_.map.quest_.setObject(_local3.objectId_);
            }
        }
    }

    public function onRightMouseDown_forWorld(_arg_1:MouseEvent):void {
        if (Parameters.data.rightClickOption == "Quest") {
            Parameters.questFollow = true;
        } else if (Parameters.data.rightClickOption == "Ability") {
            this.gs_.map.player_.sbAssist(this.gs_.map.mouseX, this.gs_.map.mouseY);
        } else if (Parameters.data.rightClickOption == "Camera") {
            held = true;
            heldX = WebMain.STAGE.mouseX;
            heldY = WebMain.STAGE.mouseY;
            heldAngle = Parameters.data.cameraAngle;
        }
    }

    public function onRightMouseUp_forWorld(_arg_1:MouseEvent):void {
        Parameters.questFollow = false;
        held = false;
    }

    public function onRightMouseDown(_arg_1:MouseEvent):void {
    }

    public function onRightMouseUp(_arg_1:MouseEvent):void {
    }

    public function onMouseDown(_arg_1:MouseEvent):void {
        var _local4:Number = NaN;
        var _local6:int = 0;
        var _local3:* = null;
        var _local2:Number = NaN;
        var _local5:Number = NaN;
        var _local7:Player = this.gs_.map.player_;
        this.mouseDown_ = true;
        if (_local7 == null) {
            return;
        }
        if (!this.enablePlayerInput_) {
            return;
        }
        if (_arg_1.shiftKey) {
            _local6 = _local7.equipment_[1];
            if (_local6 == -1) {
                return;
            }
            _local3 = ObjectLibrary.xmlLibrary_[_local6];
            if (_local3 == null || "EndMpCost" in _local3) {
                return;
            }
            if (_local7.isUnstable) {
                _local2 = Math.random() * 600 - this.gs_.map.x;
                _local5 = Math.random() * 600 - this.gs_.map.y;
            } else {
                _local2 = this.gs_.map.mouseX;
                _local5 = this.gs_.map.mouseY;
            }
            if (_arg_1.currentTarget == _arg_1.target || _arg_1.target == this.gs_ || _arg_1.target == this.gs_.map.mapHitArea) {
                _local7.useAltWeapon(_local2, _local5, 1);
            }
            return;
        }
        if (_arg_1.currentTarget == _arg_1.target || _arg_1.target == this.gs_.map || _arg_1.target == this.gs_ || _arg_1.currentTarget == this.gs_.chatBox_.list || _arg_1.target == this.gs_.map.mapHitArea) {
            _local4 = Math.atan2(this.gs_.map.mouseY, this.gs_.map.mouseX);
        } else {
            return;
        }
        if (_local7.isUnstable) {
            _local7.attemptAttackAngle(Math.random() * 6.28318530717959);
        } else {
            _local7.attemptAttackAngle(_local4);
        }
    }

    public function onMouseUp(_arg_1:MouseEvent):void {
        this.mouseDown_ = false;
        var _local2:Player = this.gs_.map.player_;
        if (_local2 == null) {
            return;
        }
        _local2.isShooting = false;
    }

    private function onAddedToStage(_arg_1:Event):void {
        var _local2:Stage = this.gs_.stage;
        _local2.addEventListener("activate", this.onActivate, false, 0, true);
        _local2.addEventListener("deactivate", this.onDeactivate, false, 0, true);
        _local2.addEventListener("keyDown", this.onKeyDown, false, 0, true);
        _local2.addEventListener("keyUp", this.onKeyUp, false, 0, true);
        _local2.addEventListener("mouseWheel", this.onMouseWheel, false, 0, true);
        _local2.addEventListener("mouseDown", this.onMouseDown, false, 0, true);
        _local2.addEventListener("mouseUp", this.onMouseUp, false, 0, true);
        _local2.addEventListener("rightMouseDown", this.onRightMouseDown_forWorld, false, 0, true);
        _local2.addEventListener("rightMouseUp", this.onRightMouseUp_forWorld, false, 0, true);
        _local2.addEventListener("enterFrame", this.onEnterFrame, false, 0, true);
        _local2.addEventListener("rightMouseDown", this.onRightMouseDown, false, 0, true);
        _local2.addEventListener("rightMouseUp", this.onRightMouseUp, false, 0, true);
    }

    private function onRemovedFromStage(_arg_1:Event):void {
        var _local2:Stage = this.gs_.stage;
        _local2.removeEventListener("activate", this.onActivate);
        _local2.removeEventListener("deactivate", this.onDeactivate);
        _local2.removeEventListener("keyDown", this.onKeyDown);
        _local2.removeEventListener("keyUp", this.onKeyUp);
        _local2.removeEventListener("mouseWheel", this.onMouseWheel);
        _local2.removeEventListener("mouseDown", this.onMouseDown);
        _local2.removeEventListener("mouseUp", this.onMouseUp);
        _local2.removeEventListener("rightMouseDown", this.onRightMouseDown_forWorld);
        _local2.removeEventListener("rightMouseUp", this.onRightMouseUp_forWorld);
        _local2.removeEventListener("enterFrame", this.onEnterFrame);
        _local2.removeEventListener("rightMouseDown", this.onRightMouseDown);
        _local2.removeEventListener("rightMouseUp", this.onRightMouseUp);
    }

    private function onActivate(_arg_1:Event):void {
    }

    private function onDeactivate(_arg_1:Event):void {
        this.clearInput();
    }

    private function onMouseWheel(_arg_1:MouseEvent):void {
        if (_arg_1.delta > 0) {
            this.miniMapZoom.dispatch("IN");
        } else {
            this.miniMapZoom.dispatch("OUT");
        }
    }

    private function onEnterFrame(_arg_1:Event):void {
        var _local2:Number = NaN;
        var _local3:Player = this.gs_.map.player_;
        if (_local3) {
            _local3.mousePos_.x = this.gs_.map.mouseX;
            _local3.mousePos_.y = this.gs_.map.mouseY;
            if (this.enablePlayerInput_) {
                if (this.mouseDown_) {
                    if (!_local3.isUnstable) {
                        _local2 = Math.atan2(this.gs_.map.mouseY, this.gs_.map.mouseX);
                        _local3.attemptAttackAngle(_local2);
                        _local3.attemptAutoAbility(_local2);
                    } else {
                        _local2 = Math.random() * 6.28318530717959;
                        _local3.attemptAttackAngle(_local2);
                        _local3.attemptAutoAbility(_local2);
                    }
                } else if (Parameters.data.AAOn || this.autofire_ || Parameters.data.AutoAbilityOn) {
                    if (!_local3.isUnstable) {
                        _local2 = Math.atan2(this.gs_.map.mouseY, this.gs_.map.mouseX);
                        _local3.attemptAutoAim(_local2);
                    } else {
                        _local3.attemptAutoAim(Math.random() * 6.28318530717959);
                    }
                }
            }
        }
    }

    private function onKeyDown(_arg_1:KeyboardEvent) : void {
        var _local17:Number = NaN;
        var _local22:Number = NaN;
        var _local3:Boolean = false;
        var _local12:int = 0;
        var _local8:* = NaN;
        var _local10:Number = NaN;
        var _local16:int = 0;
        var _local4:* = undefined;
        var _local9:* = undefined;
        var _local13:* = null;
        var _local7:* = null;
        var _local11:* = null;
        var _local18:* = null;
        var _local2:* = null;
        var _local21:* = null;
        var _local20:Stage = this.gs_.stage;
        var _local15:uint = _arg_1.keyCode;
        if (_local20.focus) {
            return;
        }
        var _local14:Player = this.gs_.map.player_;
        if (_local15 == Parameters.data.noclipKey) {
            Parameters.data.blockMove = !Parameters.data.blockMove;
            Parameters.save();
            this.gs_.map.player_.levelUpEffect(Parameters.data.blockMove ?
                    "No Clip: ON" : "No Clip: OFF");
        } else if (_local15 == Parameters.data.walkKey) {
            this.isWalking = true;
        } else if (_local15 == Parameters.data.moveUp) {
            this.moveUp_ = true;
        } else if (_local15 == Parameters.data.moveDown) {
            this.moveDown_ = true;
        } else if (_local15 == Parameters.data.moveLeft) {
            this.moveLeft_ = true;
        } else if (_local15 == Parameters.data.moveRight) {
            this.moveRight_ = true;
        } else if (_local15 == Parameters.data.rotateLeft) {
            if (Parameters.data.allowRotation) {
                this.rotateLeft_ = true;
            }
        } else if (_local15 == Parameters.data.rotateRight) {
            if (Parameters.data.allowRotation) {
                this.rotateRight_ = true;
            }
        } else if (_local15 == Parameters.data.resetToDefaultCameraAngle) {
            Parameters.data.cameraAngle = Parameters.data.defaultCameraAngle;
            Parameters.save();
            this.gs_.camera_.nonPPMatrix_ = new Matrix3D();
            this.gs_.camera_.nonPPMatrix_.appendScale(50, 50, 50);
        } else if (_local15 == Parameters.data.useSpecial) {
            if (_local14) {
                if (!this.specialKeyDown_) {
                    if (_local14.isUnstable) {
                        _local17 = Math.random() * 600 - _local20.width * 0.5;
                        _local22 = Math.random() * 600 - _local20.height * 0.5;
                    } else {
                        _local17 = this.gs_.map.mouseX;
                        _local22 = this.gs_.map.mouseY;
                    }
                    _local3 = _local14.useAltWeapon(_local17, _local22, 1);
                    if (_local3) {
                        this.specialKeyDown_ = true;
                    }
                }
            }
        } else if (_local15 == Parameters.data.autofireToggle) {
            if (_local14) {
                _local4 = !this.autofire_;
                this.autofire_ = _local4;
                _local14.isShooting = _local4;
            }
        } else if (_local15 == Parameters.data.escapeToNexus || _local15 == Parameters.data.escapeToNexus2) {
            if (_local14) {
                this.gs_.gsc_.disconnect();
                this.gs_.dispatchEvent(Parameters.reconNexus);
            }
            Parameters.data.needsRandomRealm = false;
            Parameters.save();
            StaticInjectorContext.getInjector().getInstance(CloseAllPopupsSignal).dispatch();
        } else if (_local15 == Parameters.data.useInvSlot1) {
            this.useItem(4);
        } else if (_local15 == Parameters.data.useInvSlot2) {
            this.useItem(5);
        } else if (_local15 == Parameters.data.useInvSlot3) {
            this.useItem(6);
        } else if (_local15 == Parameters.data.useInvSlot4) {
            this.useItem(7);
        } else if (_local15 == Parameters.data.useInvSlot5) {
            this.useItem(8);
        } else if (_local15 == Parameters.data.useInvSlot6) {
            this.useItem(9);
        } else if (_local15 == Parameters.data.useInvSlot7) {
            this.useItem(10);
        } else if (_local15 == Parameters.data.useInvSlot8) {
            this.useItem(11);
        } else if (_local15 == Parameters.data.useHealthPotion) {
            _local14 = this.gs_.map.player_;
            if (_local14) {
                useHPPot(_local14);
            }
        } else if (_local15 == Parameters.data.useMagicPotion) {
            _local14 = this.gs_.map.player_;
            if (_local14) {
                useMPPot(_local14);
            }
        } else if (_local15 == Parameters.data.toggleHPBar) {
            Parameters.data.HPBar = Parameters.data.HPBar != 0 ? 0 : 1;
        } else if (_local15 == Parameters.data.toggleProjectiles) {
            Parameters.data.disableAllyShoot = Parameters.data.disableAllyShoot != 0 ? 0 : 1;
        } else if (_local15 == Parameters.data.miniMapZoomOut) {
            this.miniMapZoom.dispatch("OUT");
        } else if (_local15 == Parameters.data.miniMapZoomIn) {
            this.miniMapZoom.dispatch("IN");
        } else if (_local15 == Parameters.data.togglePerformanceStats) {
            this.togglePerformanceStats();
        } else if (_local15 == Parameters.data.toggleMasterParticles) {
            Parameters.data.noParticlesMaster = !Parameters.data.noParticlesMaster;
        } else if (_local15 == Parameters.data.friendList) {
            this.isFriendsListOpen = !this.isFriendsListOpen;
            if (this.isFriendsListOpen) {
                _local13 = StaticInjectorContext.getInjector().getInstance(ShowPopupSignal);
                _local13.dispatch(new SocialPopupView());
            } else {
                this.closeDialogSignal.dispatch();
                this.closePopupByClassSignal.dispatch(SocialPopupView);
            }
        } else if (_local15 == Parameters.data.options) {
            this.clearInput();
            this.layers.overlay.addChild(new Options(this.gs_));
        } else if (_local15 == Parameters.data.TombCycleKey) {
            var _local23:* = Parameters.data.TombCycleBoss;
            switch (_local23) {
                case 3368:
                default:
                    addIgnore(3366);
                    addIgnore(32692);
                    addIgnore(3367);
                    addIgnore(32693);
                    remIgnore(3368);
                    remIgnore(32694);
                    _local14.textNotification("Bes", 16771743, 25 * 60, true);
                    Parameters.data.TombCycleBoss = 3366;
                    break;
                case 3366:
                    addIgnore(3367);
                    addIgnore(32693);
                    addIgnore(3368);
                    addIgnore(32694);
                    remIgnore(3366);
                    remIgnore(32692);
                    _local14.textNotification("Nut", 10481407, 25 * 60, true);
                    Parameters.data.TombCycleBoss = 3367;
                    break;
                case 3367:
                    addIgnore(3368);
                    addIgnore(32694);
                    addIgnore(3366);
                    addIgnore(32692);
                    remIgnore(3367);
                    remIgnore(32693);
                    _local14.textNotification("Geb", 11665311, 25 * 60, true);
                    Parameters.data.TombCycleBoss = 3368;
            }
            Parameters.save();
        } else if (_local15 == Parameters.data.anchorTeleport) {
            this.gs_.gsc_.playerText("/teleport " + Parameters.data.anchorName);
        } else if (_local15 == Parameters.data.toggleCentering) {
            Parameters.data.centerOnPlayer = !Parameters.data.centerOnPlayer;
            Parameters.save();
        } else if (_local15 == Parameters.data.toggleFullscreen) {
            if (Capabilities.playerType == "Desktop") {
                Parameters.data.fullscreenMode = !Parameters.data.fullscreenMode;
                Parameters.save();
                _local20.displayState = !!Parameters.data.fullscreenMode ? "fullScreenInteractive" : "normal";
            }
        } else if (_local15 == Parameters.data.toggleRealmQuestDisplay) {
            this.toggleRealmQuestsDisplaySignal.dispatch();
        } else if (_local15 == Parameters.data.switchTabs) {
            this.statsTabHotKeyInputSignal.dispatch();
        } else if (_local15 == Parameters.data.AutoAbilityHotkey) {
            Parameters.data.AutoAbilityOn = !Parameters.data.AutoAbilityOn;
            _local14.textNotification(!!Parameters.data.AutoAbilityOn ? "AutoAbility enabled" : "AutoAbility disabled", 0xffffff, 2000, false);
        } else if (_local15 != Parameters.data.ignoreSpeedyKey) { //!=
            if (_local15 == Parameters.data.AAHotkey) {
                Parameters.data.AAOn = !Parameters.data.AAOn;
                if (!mouseDown_ && !Parameters.data.AAOn) {
                    _local14.isShooting = false;
                }
                _local14.textNotification(!!Parameters.data.AAOn ? "AutoAim enabled" : "AutoAim disabled", 0xffffff, 2000, false);
            } else if (_local15 == Parameters.data.AAModeHotkey) {
                this.selectAimMode();
            } else if (_local15 == Parameters.data.AutoLootHotkey) {
                Parameters.data.AutoLootOn = !Parameters.data.AutoLootOn;
                _local14.textNotification(!!Parameters.data.AutoLootOn ? "AutoLoot enabled" : "AutoLoot disabled", 0xffffff, 2000, false);
            } else if (_local15 == Parameters.data.Cam45DegInc) {
                Parameters.data.cameraAngle = Parameters.data.cameraAngle - 0.785398163397448;
                Parameters.save();
            } else if (_local15 == Parameters.data.Cam45DegDec) {
                Parameters.data.cameraAngle = Parameters.data.cameraAngle + 0.785398163397448;
                Parameters.save();
            } else if (_local15 == Parameters.data.resetClientHP) {
                _local14.clientHp = _local14.hp_;
            } else if (_local15 == Parameters.data.QuestTeleport) {
                if (_local14) {
                    teleQuest(_local14);
                }
            } else if (_local15 == Parameters.data.TextPause) {
                this.gs_.gsc_.playerText("/pause");
            } else if (_local15 == Parameters.data.TextThessal) {
                this.gs_.gsc_.playerText("He lives and reigns and conquers the world");
            } else if (_local15 == Parameters.data.TextDraconis) {
                this.gs_.gsc_.playerText("black");
            } else if (_local15 == Parameters.data.TextCem) {
                this.gs_.gsc_.playerText("ready");
            } else if (_local15 == Parameters.data.addMoveRecPoint) {
                Parameters.VHSRecord.push(new Point(_local14.x_, _local14.y_));
                Parameters.VHSRecordLength = Parameters.VHSRecord.length;
                _local14.textNotification("Saved " + _local14.x_ + "," + _local14.y_, 0xb00000, 800);
            } else if (_local15 == Parameters.data.SelfTPHotkey) {
                this.gs_.gsc_.teleport(_local14.objectId_);
            } else if (_local15 != Parameters.data.syncFollowHotkey) {
                if (_local15 != Parameters.data.syncLeadHotkey) {
                    if (_local15 != Parameters.data.requestPuriHotkey) {
                        if (_local15 == Parameters.data.TogglePlayerFollow) {
                            Parameters.followingName = !Parameters.followingName;
                            _local14.textNotification(!!Parameters.followingName ? "Following: on" : "Following: off", 0xffff00);
                        } else if (_local15 == Parameters.data.PassesCoverHotkey) {
                            Parameters.data.PassesCover = !Parameters.data.PassesCover;
                            _local14.textNotification(!!Parameters.data.PassesCover ? "Projectile Noclip on" : "Projectile Noclip off");
                        } else if (_local15 == Parameters.data.LowCPUModeHotKey) {
                            Parameters.lowCPUMode = !Parameters.lowCPUMode;
                            _local14.textNotification(!!Parameters.lowCPUMode ? "Low CPU on" : "Low CPU off");
                        } else if (_local15 == Parameters.data.ReconRealm) {
                            if (!Parameters.lockRecon) {
                                if (Parameters.reconRealm) {
                                    Parameters.reconRealm.charId_ = this.gs_.gsc_.charId_;
                                    Parameters.reconRealm.createCharacter_ = false;
                                    this.gs_.dispatchEvent(Parameters.reconRealm);
                                } else {
                                    _local7 = new ReconnectEvent(this.gs_.gsc_.server_, -3, false, this.gs_.gsc_.charId_, 0, null, false);
                                    Parameters.reconRealm = _local7;
                                    this.gs_.dispatchEvent(Parameters.reconRealm);
                                }
                            }
                            StaticInjectorContext.getInjector().getInstance(CloseAllPopupsSignal).dispatch();
                        } else if (_local15 == Parameters.data.RandomRealm) {
                            if (!Parameters.lockRecon) {
                                _local11 = new ReconnectEvent(Parameters.reconNexus.server_, -3, false, this.gs_.gsc_.charId_, -1, null, false);
                                this.gs_.dispatchEvent(_local11);
                            }
                            StaticInjectorContext.getInjector().getInstance(CloseAllPopupsSignal).dispatch();
                        } else if (_local15 == Parameters.data.DrinkAllHotkey) {
                            _local18 = _local14.getClosestBag(true);
                            if (_local18) {
                                _local12 = getTimer();
                                _local8 = Number(_local14.x_);
                                _local10 = _local14.y_;
                                _local16 = 0;
                                while (_local16 < 8) {
                                    if (_local18.equipment_[_local16] != -1) {
                                        gs_.gsc_.useItem(_local12, _local18.objectId_, _local16, _local18.equipment_[_local16], _local8, _local10, 1);
                                    }
                                    _local16++;
                                }
                            }
                        } else if (_local15 == Parameters.data.tradeNearestPlayerKey) {
                            _local8 = Infinity;
                            for each(var _local5:GameObject in this.gs_.map.goDict_) {
                                if (_local5 is Player && (_local5 as Player).nameChosen_ && _local14 != _local5) {
                                    _local10 = _local14.getDistSquared(_local14.x_, _local14.y_, _local5.x_, _local5.y_);
                                    if (_local10 < _local8) {
                                        _local2 = _local5;
                                        _local8 = _local10;
                                    }
                                }
                            }
                            if (_local2) {
                                this.gs_.gsc_.requestTrade(_local2.name_);
                            }
                        } else if (_local15 == Parameters.data.FindKeys) {
                            findKeys();
                        } else if (_local15 == Parameters.data.famebotToggleHotkey) {
                            Parameters.fameBotWatchingPortal = false;
                            Parameters.fameBot = !Parameters.fameBot;
                            if (Parameters.fameBot) {
                                if (Parameters.fpmStart == -1) {
                                    Parameters.fpmStart = getTimer();
                                    Parameters.fpmGain = 0;
                                }
                                _local14.textNotification("Famebot On", 0xffb000);
                            } else {
                                _local14.textNotification("Famebot Off", 0xffb000);
                            }
                        } else if (_local15 == Parameters.data.sayCustom1) {
                            if (Parameters.data.customMessage1.length > 0) {
                                pcmc.dispatch(Parameters.data.customMessage1);
                            }
                        } else if (_local15 == Parameters.data.sayCustom2) {
                            if (Parameters.data.customMessage2.length > 0) {
                                pcmc.dispatch(Parameters.data.customMessage2);
                            }
                        } else if (_local15 == Parameters.data.sayCustom3) {
                            if (Parameters.data.customMessage3.length > 0) {
                                pcmc.dispatch(Parameters.data.customMessage3);
                            }
                        } else if (_local15 == Parameters.data.sayCustom4) {
                            if (Parameters.data.customMessage4.length > 0) {
                                pcmc.dispatch(Parameters.data.customMessage4);
                            }
                        } else if (_local15 == Parameters.data.aimAtQuest) {
                            if (this.gs_.map.quest_.objectId_ >= 0) {
                                _local21 = this.gs_.map.goDict_[this.gs_.map.quest_.objectId_];
                                Parameters.data.cameraAngle = Math.atan2(_local14.y_ - _local21.y_, _local14.x_ - _local21.x_) - 1.5707963267949;
                                Parameters.save();
                            }
                        }
                    }
                }
            }
        }
        this.setPlayerMovement();
    }

    private function onKeyUp(_arg_1:KeyboardEvent):void {
        var _local2:Number = NaN;
        var _local3:Number = NaN;
        var _local4:* = _arg_1.keyCode;
        switch (_local4) {
            case Parameters.data.walkKey:
                this.isWalking = false;
                break;
            case Parameters.data.moveUp:
                this.moveUp_ = false;
                break;
            case Parameters.data.moveDown:
                this.moveDown_ = false;
                break;
            case Parameters.data.moveLeft:
                this.moveLeft_ = false;
                break;
            case Parameters.data.moveRight:
                this.moveRight_ = false;
                break;
            case Parameters.data.rotateLeft:
                this.rotateLeft_ = false;
                break;
            case Parameters.data.rotateRight:
                this.rotateRight_ = false;
                break;
            case Parameters.data.useSpecial:
                if (this.specialKeyDown_) {
                    this.specialKeyDown_ = false;
                    if (this.gs_.map.player_.isUnstable) {
                        _local2 = Math.random() * 600 - this.gs_.map.x;
                        _local3 = Math.random() * 600 - this.gs_.map.y;
                    } else {
                        _local2 = this.gs_.map.mouseX;
                        _local3 = this.gs_.map.mouseY;
                    }
                    this.gs_.map.player_.useAltWeapon(this.gs_.map.mouseX, this.gs_.map.mouseY, 2);
                    break;
                }
        }
        this.setPlayerMovement();
    }
}
}
