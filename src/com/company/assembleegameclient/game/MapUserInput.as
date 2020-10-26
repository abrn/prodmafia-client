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

        public static function addIgnore(playerId:int):String {
            var _loplayerObjectcal2:* = null;
            for each (var _local3:int in Parameters.data.AAIgnore) {
                if (_local3 == playerId) {
                    return playerId + " already exists in Ignore list";
                }
            }
            if (playerId in ObjectLibrary.propsLibrary_) {
                Parameters.data.AAIgnore.push(playerId);
                playerObject = ObjectLibrary.propsLibrary_[playerId];
                playerObject.ignored = true;
                return "Successfully added " + playerId + " to Ignore list";
            }
            return "Failed to add " + playerId + " to Ignore list (no known object with this itemType)";
        }

        public static function remIgnore(playerId:int):String {
            var counter:int = 0;
            var playerObject:* = null;
            var ignoreLen:uint = Parameters.data.AAIgnore.length;
            counter = 0;
            while (counter < ignoreLen) {
                if (Parameters.data.AAIgnore[counter] == playerId) {
                    Parameters.data.AAIgnore.splice(counter, 1);
                    if (playerId in ObjectLibrary.propsLibrary_) {
                        playerObject = ObjectLibrary.propsLibrary_[playerId];
                        playerObject.ignored = false;
                    }
                    return "Successfully removed " + playerId + " from Ignore list";
                }
                counter++;
            }
            return playerId + " not found in Ignore list";
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

        public function setEnablePlayerInput(toggle:Boolean):void {
            if (this.enablePlayerInput_ != toggle) {
                this.enablePlayerInput_ = toggle;
                this.clearInput();
            }
        }

        public function useHPPot(currentPlayer:Player):void {
            var potionSlotId:int = 0;
            if (currentPlayer.hp_ != currentPlayer.maxHP_) {
                if (currentPlayer.healthPotionCount_ == 0 && !Parameters.data.fameBlockThirsty) {
                    potionSlotId = currentPlayer.findItems(currentPlayer.equipment_, Parameters.hpPotions, 4);
                    if (potionSlotId != -1) {
                        this.gs_.gsc_.useItem(getTimer(), currentPlayer.objectId_, potionSlotId, currentPlayer.equipment_[potionSlotId], currentPlayer.x_, currentPlayer.y_, 1);
                    }
                } else {
                    this.useBuyPotionSignal.dispatch(new UseBuyPotionVO(2594, UseBuyPotionVO.CONTEXTBUY));
                }
            }
        }

        public function useMPPot(currentPlayer:Player):void {
            var potionSlotId:int = 0;
            if (currentPlayer.mp_ != currentPlayer.maxMP_) {
                if (currentPlayer.magicPotionCount_ == 0 && !Parameters.data.fameBlockThirsty) {
                    potionSlotId = currentPlayer.findItems(currentPlayer.equipment_, Parameters.mpPotions, 4);
                    if (potionSlotId != -1) {
                        this.gs_.gsc_.useItem(getTimer(), currentPlayer.objectId_, potionSlotId, currentPlayer.equipment_[potionSlotId], currentPlayer.x_, currentPlayer.y_, 1);
                    }
                } else {
                    this.useBuyPotionSignal.dispatch(new UseBuyPotionVO(2595, UseBuyPotionVO.CONTEXTBUY));
                }
            }
        }

        public function teleQuest(currentPlayer:Player):void {
            var infinity:* = NaN;
            var closestPlayer:int = 0;
            var distance:Number = NaN;
            var questOject:* = null;
            var questObjectId:int = gs_.map.quest_.objectId_;
            if (questObjectId > 0) {
                questOject = gs_.map.quest_.getObject(questObjectId);
                if (questOject) {
                    infinity = Infinity;
                    closestPlayer = -1;
                    for each (var realmObject:GameObject in this.gs_.map.goDict_) {
                        if (realmObject is Player && !realmObject.isInvisible && !realmObject.isPaused) {
                            distance = (realmObject.x_ - questOject.x_) * (realmObject.x_ - questOject.x_) + (realmObject.y_ - questOject.y_) * (realmObject.y_ - questOject.y_);
                            if (distance < infinity) {
                                infinity = distance;
                                closestPlayer = realmObject.objectId_;
                            }
                        }
                    }
                    if (closestPlayer == currentPlayer.objectId_) {
                        currentPlayer.textNotification("You are closest!", 0xffffff, 25 * 60, false);
                    } else {
                        this.gs_.gsc_.teleport(closestPlayer);
                        currentPlayer.textNotification("Teleporting to " + this.gs_.map.goDict_[closestPlayer].name_, 0xffffff, 25 * 60, false);
                    }
                }
            } else {
                currentPlayer.textNotification("You have no quest!", 0xffffff, 25 * 60, false);
            }
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
            var currentPlayer:Player = this.gs_.map.player_;
            if (currentPlayer) {
                if (this.enablePlayerInput_) {
                    currentPlayer.setRelativeMovement((!!this.rotateRight_ ? 1 : 0) - (!!this.rotateLeft_ ? 1 : 0), (!!this.moveRight_ ? 1 : 0) - (!!this.moveLeft_ ? 1 : 0), (!!this.moveDown_ ? 1 : 0) - (!!this.moveUp_ ? 1 : 0));
                } else {
                    currentPlayer.setRelativeMovement(0, 0, 0);
                }
                currentPlayer.isWalking = this.isWalking;
            }
        }

        private function useItem(slotId:int):void {
            if (Parameters.data.fixTabHotkeys && this.tabStripModel.currentSelection == "Backpack") {
                slotId = slotId + 8;
            }
            this.gs_.gsc_.useItem_new(this.gs_.map.player_, slotId);
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
                for each (var _local6:GameObject in this.gs_.map.goDict_) {
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
            var abilityId:int = 0;
            var abilityXML:* = null;
            var posX:Number = NaN;
            var poxY:Number = NaN;
            var currentPlayer:Player = this.gs_.map.player_;
            this.mouseDown_ = true;
            if (currentPlayer == null) {
                return;
            }
            if (!this.enablePlayerInput_) {
                return;
            }
            if (_arg_1.shiftKey) {
                abilityId = currentPlayer.equipment_[1];
                if (abilityId == -1) {
                    return;
                }
                abilityXML = ObjectLibrary.xmlLibrary_[abilityId];
                if (abilityXML == null || "EndMpCost" in abilityXML) {
                    return;
                }
                if (currentPlayer.isUnstable) {
                    posX = Math.random() * 600 - this.gs_.map.x;
                    poxY = Math.random() * 600 - this.gs_.map.y;
                } else {
                    posX = this.gs_.map.mouseX;
                    poxY = this.gs_.map.mouseY;
                }
                if (_arg_1.target.name == null) {
                    currentPlayer.useAltWeapon(posX, poxY, 1)
                }
                return;
            }
            if (_arg_1.currentTarget == _arg_1.target || _arg_1.target == this.gs_.map || _arg_1.target == this.gs_ || _arg_1.currentTarget == this.gs_.chatBox_.list || _arg_1.target == this.gs_.map.mapHitArea) {
                _local4 = Math.atan2(this.gs_.map.mouseY, this.gs_.map.mouseX);
            } else {
                return;
            }
            if (_arg_1.target.name == null) {
                if (currentPlayer.isUnstable) {
                    currentPlayer.attemptAttackAngle(Math.random() * 6.28318530717959);
                } else {
                    currentPlayer.attemptAttackAngle(_local4);
                }
            }
        }

        public function onMouseUp(_arg_1:MouseEvent):void {
            this.mouseDown_ = false;
            var currentPlayer:Player = this.gs_.map.player_;
            if (currentPlayer == null) {
                return;
            }
            currentPlayer.isShooting = false;
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
            var angle:Number = NaN;
            var currentPlayer:Player = this.gs_.map.player_;
            if (currentPlayer) 
            {
                currentPlayer.mousePos_.x = this.gs_.map.mouseX;
                currentPlayer.mousePos_.y = this.gs_.map.mouseY;
                if (this.enablePlayerInput_) 
                {
                    if (this.mouseDown_) 
                    {
                        if (!currentPlayer.isUnstable) 
                        {
                            shotAngle = Math.atan2(this.gs_.map.mouseY, this.gs_.map.mouseX);
                            currentPlayer.attemptAttackshotAngle(shotAngle);
                            currentPlayer.attemptAutoAbility(shotAngle);
                        } 
                        else
                        {
                            shotAngle = Math.random() * 6.28318530717959;
                            currentPlayer.attemptAttackshotAngle(shotAngle);
                            currentPlayer.attemptAutoAbility(shotAngle);
                        }
                    } 
                    else if (Parameters.data.AAOn || this.autofire_ || Parameters.data.AutoAbilityOn) 
                    {
                        if (!currentPlayer.isUnstable) {
                            shotAngle = Math.atan2(this.gs_.map.mouseY, this.gs_.map.mouseX);
                            currentPlayer.attemptAutoAim(shotAngle);
                        } else {
                            currentPlayer.attemptAutoAim(Math.random() * 6.28318530717959);
                        }
                    }
                }
            }
        }

        private function onKeyDown(_arg_1:KeyboardEvent):void {
            var posX:Number = NaN;
            var posY:Number = NaN;
            var canUseAbility:Boolean = false;
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
            var keyCode:uint = _arg_1.keyCode;
            if (_local20.focus) {
                return;
            }
            var currentPlayer:Player = this.gs_.map.player_;
            if (keyCode == Parameters.data.noclipKey) {
                Parameters.data.blockMove = !Parameters.data.blockMove;
                Parameters.save();
                this.gs_.map.player_.levelUpEffect(Parameters.data.blockMove ? "No Clip: ON" : "No Clip: OFF");
            } 
            else if (keyCode == Parameters.data.walkKey) 
            {
                this.isWalking = true;
            } 
            else if (keyCode == Parameters.data.moveUp) 
            {
                this.moveUp_ = true;
            } 
            else if (keyCode == Parameters.data.moveDown) 
            {
                this.moveDown_ = true;
            } 
            else if (keyCode == Parameters.data.moveLeft) 
            {
                this.moveLeft_ = true;
            } 
            else if (keyCode == Parameters.data.moveRight)
            {
                this.moveRight_ = true;
            } 
            else if (keyCode == Parameters.data.rotateLeft) 
            {
                if (Parameters.data.allowRotation) {
                    this.rotateLeft_ = true;
                }
            } 
            else if (keyCode == Parameters.data.rotateRight) 
            {
                if (Parameters.data.allowRotation) {
                    this.rotateRight_ = true;
                }
            }
            else if (keyCode == Parameters.data.resetToDefaultCameraAngle) 
            {
                Parameters.data.cameraAngle = Parameters.data.defaultCameraAngle;
                Parameters.save();
                this.gs_.camera_.nonPPMatrix_ = new Matrix3D();
                this.gs_.camera_.nonPPMatrix_.appendScale(50, 50, 50);
            } 
            else if (keyCode == Parameters.data.useSpecial) 
            {
                if (currentPlayer) 
                {
                    if (!this.specialKeyDown_) 
                    {
                        if (currentPlayer.isUnstable) 
                        {
                            posX = Math.random() * 600 - _local20.width * 0.5;
                            posY = Math.random() * 600 - _local20.height * 0.5;
                        } 
                        else 
                        {
                            posX = this.gs_.map.mouseX;
                            posY = this.gs_.map.mouseY;
                        }
                        canUseAbility = currentPlayer.useAltWeapon(posX, posY, 1);
                        if (canUseAbility) 
                        {
                            this.specialKeyDown_ = true;
                        }
                    }
                }
            } 
            else if (keyCode == Parameters.data.autofireToggle)
            {
                if (currentPlayer) 
                {
                    _local4 = !this.autofire_;
                    this.autofire_ = _local4;
                    currentPlayer.isShooting = _local4;
                }
            } 
            else if (keyCode == Parameters.data.escapeToNexus || keyCode == Parameters.data.escapeToNexus2) 
            {
                if (currentPlayer) 
                {
                    this.gs_.gsc_.disconnect();
                    this.gs_.dispatchEvent(Parameters.reconNexus);
                }
                Parameters.save();
                StaticInjectorContext.getInjector().getInstance(CloseAllPopupsSignal).dispatch();
            } 
            else if (keyCode == Parameters.data.useInvSlot1) {
                this.useItem(4);
            } 
            else if (keyCode == Parameters.data.useInvSlot2) {
                this.useItem(5);
            } 
            else if (keyCode == Parameters.data.useInvSlot3) {
                this.useItem(6);
            } 
            else if (keyCode == Parameters.data.useInvSlot4) {
                this.useItem(7);
            } 
            else if (keyCode == Parameters.data.useInvSlot5) {
                this.useItem(8);
            } 
            else if (keyCode == Parameters.data.useInvSlot6) {
                this.useItem(9);
            } 
            else if (keyCode == Parameters.data.useInvSlot7) {
                this.useItem(10);
            } 
            else if (keyCode == Parameters.data.useInvSlot8) {
                this.useItem(11);
            } 
            else if (keyCode == Parameters.data.useHealthPotion) {
                currentPlayer = this.gs_.map.player_;
                if (currentPlayer) {
                    useHPPot(currentPlayer);
                }
            } 
            else if (keyCode == Parameters.data.useMagicPotion) {
                currentPlayer = this.gs_.map.player_;
                if (currentPlayer) {
                    useMPPot(currentPlayer);
                }
            } 
            else if (keyCode == Parameters.data.toggleHPBar) {
                Parameters.data.HPBar = Parameters.data.HPBar != 0 ? 0 : 1;
            } 
            else if (keyCode == Parameters.data.toggleProjectiles) {
                Parameters.data.disableAllyShoot = Parameters.data.disableAllyShoot != 0 ? 0 : 1;
            } 
            else if (keyCode == Parameters.data.miniMapZoomOut) {
                this.miniMapZoom.dispatch("OUT");
            } 
            else if (keyCode == Parameters.data.miniMapZoomIn) {
                this.miniMapZoom.dispatch("IN");
            } 
            else if (keyCode == Parameters.data.togglePerformanceStats) {
                this.togglePerformanceStats();
            } 
            else if (keyCode == Parameters.data.toggleMasterParticles) {
                Parameters.data.noParticlesMaster = !Parameters.data.noParticlesMaster;
            } 
            else if (keyCode == Parameters.data.friendList) {
                this.isFriendsListOpen = !this.isFriendsListOpen;
                if (this.isFriendsListOpen) {
                    _local13 = StaticInjectorContext.getInjector().getInstance(ShowPopupSignal);
                    _local13.dispatch(new SocialPopupView());
                } else {
                    this.closeDialogSignal.dispatch();
                    this.closePopupByClassSignal.dispatch(SocialPopupView);
                }
            } 
            else if (keyCode == Parameters.data.options) {
                this.clearInput();
                this.layers.overlay.addChild(new Options(this.gs_));
            } 
            lse if (keyCode == Parameters.data.TombCycleKey) {
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
                        currentPlayer.textNotification("Bes", 16771743, 25 * 60, true);
                        Parameters.data.TombCycleBoss = 3366;
                        break;
                    case 3366:
                        addIgnore(3367);
                        addIgnore(32693);
                        addIgnore(3368);
                        addIgnore(32694);
                        remIgnore(3366);
                        remIgnore(32692);
                        currentPlayer.textNotification("Nut", 10481407, 25 * 60, true);
                        Parameters.data.TombCycleBoss = 3367;
                        break;
                    case 3367:
                        addIgnore(3368);
                        addIgnore(32694);
                        addIgnore(3366);
                        addIgnore(32692);
                        remIgnore(3367);
                        remIgnore(32693);
                        currentPlayer.textNotification("Geb", 11665311, 25 * 60, true);
                        Parameters.data.TombCycleBoss = 3368;
                }
                Parameters.save();
            } 
            else if (keyCode == Parameters.data.anchorTeleport)
            {
                this.gs_.gsc_.playerText("/teleport " + Parameters.data.anchorName);
            } 
            else if (keyCode == Parameters.data.toggleCentering) 
            {
                Parameters.data.centerOnPlayer = !Parameters.data.centerOnPlayer;
                Parameters.save();
            } 
            else if (keyCode == Parameters.data.toggleFullscreen) 
            {
                if (Capabilities.playerType == "Desktop") {
                    Parameters.data.fullscreenMode = !Parameters.data.fullscreenMode;
                    Parameters.save();
                    _local20.displayState = !!Parameters.data.fullscreenMode ? "fullScreenInteractive" : "normal";
                }
            } 
            else if (keyCode == Parameters.data.toggleRealmQuestDisplay) 
            {
                this.toggleRealmQuestsDisplaySignal.dispatch();
            } 
            else if (keyCode == Parameters.data.switchTabs) 
            {
                this.statsTabHotKeyInputSignal.dispatch();
            } 
            else if (keyCode == Parameters.data.AutoAbilityHotkey) 
            {
                Parameters.data.AutoAbilityOn = !Parameters.data.AutoAbilityOn;
                currentPlayer.textNotification(!!Parameters.data.AutoAbilityOn ? "AutoAbility enabled" : "AutoAbility disabled", 0xffffff, 2000, false);
            } 
            else if (keyCode != Parameters.data.ignoreSpeedyKey) 
            {
                if (keyCode == Parameters.data.AAHotkey) {
                    Parameters.data.AAOn = !Parameters.data.AAOn;
                    if (!mouseDown_ && !Parameters.data.AAOn) {
                        currentPlayer.isShooting = false;
                    }
                    currentPlayer.textNotification(!!Parameters.data.AAOn ? "AutoAim enabled" : "AutoAim disabled", 0xffffff, 2000, false);
                }
                else if (keyCode == Parameters.data.AAModeHotkey) {
                    this.selectAimMode();
                } 
                else if (keyCode == Parameters.data.AutoLootHotkey) 
                {
                    Parameters.data.AutoLootOn = !Parameters.data.AutoLootOn;
                    currentPlayer.textNotification(!!Parameters.data.AutoLootOn ? "AutoLoot enabled" : "AutoLoot disabled", 0xffffff, 2000, false);
                } 
                else if (keyCode == Parameters.data.Cam45DegInc) 
                {
                    Parameters.data.cameraAngle = Parameters.data.cameraAngle - 0.785398163397448;
                    Parameters.save();
                } 
                else if (keyCode == Parameters.data.Cam45DegDec) 
                {
                    Parameters.data.cameraAngle = Parameters.data.cameraAngle + 0.785398163397448;
                    Parameters.save();
                } 
                else if (keyCode == Parameters.data.resetClientHP) 
                {
                    currentPlayer.clientHp = currentPlayer.hp_;
                } 
                else if (keyCode == Parameters.data.QuestTeleport) 
                {
                    if (currentPlayer) {
                        teleQuest(currentPlayer);
                    }
                } 
                else if (keyCode == Parameters.data.TextPause) 
                {
                    this.gs_.gsc_.playerText("/pause");
                } 
                else if (keyCode == Parameters.data.TextThessal) 
                {
                    this.gs_.gsc_.playerText("He lives and reigns and conquers the world");
                } 
                else if (keyCode == Parameters.data.TextCem)
                {
                    this.gs_.gsc_.playerText("ready");
                } 
                else if (keyCode == Parameters.data.addMoveRecPoint) 
                {
                    Parameters.VHSRecord.push(new Point(currentPlayer.x_, currentPlayer.y_));
                    Parameters.VHSRecordLength = Parameters.VHSRecord.length;
                    currentPlayer.textNotification("Saved " + currentPlayer.x_ + "," + currentPlayer.y_, 0xb00000, 800);
                } 
                else if (keyCode == Parameters.data.SelfTPHotkey) 
                {
                    this.gs_.gsc_.teleport(currentPlayer.objectId_);
                } 
                else if (keyCode != Parameters.data.syncFollowHotkey) 
                {
                    if (keyCode != Parameters.data.syncLeadHotkey) 
                    {
                        if (keyCode != Parameters.data.requestPuriHotkey) 
                        {
                            if (keyCode == Parameters.data.TogglePlayerFollow) 
                            {
                                Parameters.followingName = !Parameters.followingName;
                                if (!!Parameters.followingName) {
                                    currentPlayer.textNotification("Following player on", 0x0dff00);
                                } else {
                                    currentPlayer.textNotification("Following player off", 0xff0000);
                                }
                            } 
                            else if (keyCode == Parameters.data.PassesCoverHotkey) 
                            {
                                Parameters.data.PassesCover = !Parameters.data.PassesCover;
                                if (!!Parameters.data.PassesCover) {
                                    currentPlayer.textNotification("Projectile noclip on", 0x0dff00);
                                } else {
                                    currentPlayer.textNotification("Projectile noclip off", 0xff0000);
                                }
                            } 
                            else if (keyCode == Parameters.data.LowCPUModeHotKey) 
                            {
                                Parameters.lowCPUMode = !Parameters.lowCPUMode;
                                currentPlayer.textNotification(!!Parameters.lowCPUMode ? "Low CPU on" : "Low CPU off");
                            } 
                            else if (keyCode == Parameters.data.ReconRealm) 
                            {
                                if (!Parameters.lockRecon) 
                                {
                                    if (Parameters.reconRealm) 
                                    {
                                        Parameters.reconRealm.charId_ = this.gs_.gsc_.charId_;
                                        Parameters.reconRealm.createCharacter_ = false;
                                        this.gs_.dispatchEvent(Parameters.reconRealm);
                                    } 
                                    else 
                                    {
                                        _local7 = new ReconnectEvent(this.gs_.gsc_.server_, -3, false, this.gs_.gsc_.charId_, 0, null, false);
                                        Parameters.reconRealm = _local7;
                                        this.gs_.dispatchEvent(Parameters.reconRealm);
                                    }
                                }
                                StaticInjectorContext.getInjector().getInstance(CloseAllPopupsSignal).dispatch();
                            } 
                            else if (keyCode == Parameters.data.DrinkAllHotkey) 
                            {
                                bagObject = currentPlayer.getClosestBag(true);
                                if (bagObject) 
                                {
                                    currentTime = getTimer();
                                    posX = Number(currentPlayer.x_);
                                    posY = currentPlayer.y_;
                                    counter = 0;
                                    while (counter < 8) 
                                    {
                                        if (bagObject.equipment_[counter] != -1)
                                        {
                                            gs_.gsc_.useItem(currentTime, bagObject.objectId_, counter, bagObject.equipment_[counter], posX, posY, 1);
                                        }
                                        counter++;
                                    }
                                }
                            } 
                            else if (keyCode == Parameters.data.tradeNearestPlayerKey) 
                            {
                                infinity = Infinity;
                                for each (var obj:GameObject in this.gs_.map.goDict_) 
                                {
                                    if (obj is Player && (obj as Player).nameChosen_ && currentPlayer != obj) 
                                    {
                                        distance = currentPlayer.getDistSquared(currentPlayer.x_, currentPlayer.y_, obj.x_, obj.y_);
                                        if (distance < infinity) 
                                        {
                                            nearestPlayer = obj;
                                            infinity = distance;
                                        }
                                    }
                                }
                                if (nearestPlayer) 
                                {
                                    this.gs_.gsc_.requestTrade(nearestPlayer.name_);
                                }
                            } 
                            else if (keyCode == Parameters.data.sayCustom1) 
                            {
                                if (Parameters.data.customMessage1.length > 0) 
                                {
                                    pcmc.dispatch(Parameters.data.customMessage1);
                                }
                            } 
                            else if (keyCode == Parameters.data.sayCustom2) 
                            {
                                if (Parameters.data.customMessage2.length > 0) 
                                {
                                    pcmc.dispatch(Parameters.data.customMessage2);
                                }
                            } 
                            else if (keyCode == Parameters.data.sayCustom3) 
                            {
                                if (Parameters.data.customMessage3.length > 0) 
                                {
                                    pcmc.dispatch(Parameters.data.customMessage3);
                                }
                            } 
                            else if (keyCode == Parameters.data.sayCustom4) 
                            {
                                if (Parameters.data.customMessage4.length > 0) 
                                {
                                    pcmc.dispatch(Parameters.data.customMessage4);
                                }
                            } 
                            else if (keyCode == Parameters.data.aimAtQuest) 
                            {
                                if (this.gs_.map.quest_.objectId_ >= 0) 
                                {
                                    questObject = this.gs_.map.goDict_[this.gs_.map.quest_.objectId_];
                                    Parameters.data.cameraAngle = Math.atan2(currentPlayer.y_ - questObject.y_, currentPlayer.x_ - questObject.x_) - 1.5707963267949;
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
