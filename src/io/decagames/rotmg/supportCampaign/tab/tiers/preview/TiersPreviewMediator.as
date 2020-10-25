package io.decagames.rotmg.supportCampaign.tab.tiers.preview {
import com.company.assembleegameclient.ui.tooltip.TextToolTip;
import com.company.assembleegameclient.ui.tooltip.ToolTip;

import flash.display.DisplayObject;
import flash.events.Event;

import io.decagames.rotmg.shop.PurchaseInProgressModal;
import io.decagames.rotmg.supportCampaign.data.SupporterCampaignModel;
import io.decagames.rotmg.supportCampaign.signals.TierSelectedSignal;
import io.decagames.rotmg.supportCampaign.tab.tiers.popups.ClaimCompleteModal;
import io.decagames.rotmg.ui.buttons.BaseButton;
import io.decagames.rotmg.ui.imageLoader.ImageLoader;
import io.decagames.rotmg.ui.popups.modal.error.ErrorModal;
import io.decagames.rotmg.ui.popups.signals.ClosePopupSignal;
import io.decagames.rotmg.ui.popups.signals.ShowPopupSignal;

import kabam.rotmg.account.core.Account;
import kabam.rotmg.appengine.api.AppEngineClient;
import kabam.rotmg.core.signals.HideTooltipsSignal;
import kabam.rotmg.core.signals.ShowTooltipSignal;
import kabam.rotmg.text.view.stringBuilder.LineBuilder;
import kabam.rotmg.tooltips.HoverTooltipDelegate;

import robotlegs.bender.bundles.mvcs.Mediator;

public class TiersPreviewMediator extends Mediator {


    public function TiersPreviewMediator() {
        super();
    }
    [Inject]
    public var view:TiersPreview;
    [Inject]
    public var selectedSignal:TierSelectedSignal;
    [Inject]
    public var model:SupporterCampaignModel;
    [Inject]
    public var showPopupSignal:ShowPopupSignal;
    [Inject]
    public var account:Account;
    [Inject]
    public var client:AppEngineClient;
    [Inject]
    public var closePopupSignal:ClosePopupSignal;
    [Inject]
    public var showTooltipSignal:ShowTooltipSignal;
    [Inject]
    public var hideTooltipSignal:HideTooltipsSignal;
    private var displayedTier:int;
    private var inProgressModal:PurchaseInProgressModal;
    private var toolTip:ToolTip;
    private var hoverTooltipDelegate:HoverTooltipDelegate;
    private var _imageLoader:ImageLoader;
    private var _currentTierRank:int;

    override public function initialize():void {
        this.toolTip = new TextToolTip(0x363636, 1, "", "You must claim previous Tiers rewards first!", 200);
        this.hoverTooltipDelegate = new HoverTooltipDelegate();
        this.hoverTooltipDelegate.setShowToolTipSignal(this.showTooltipSignal);
        this.hoverTooltipDelegate.setHideToolTipsSignal(this.hideTooltipSignal);
        this.hoverTooltipDelegate.tooltip = this.toolTip;
        this.onTierSelected(this.view.startTier);
        this.displayedTier = this.model.nextClaimableTier;
        this.setArrowState();
        this.view.leftArrow.clickSignal.add(this.onLeftClick);
        this.view.rightArrow.clickSignal.add(this.onRightClick);
        this.selectedSignal.add(this.onTierSelected);
        this.view.claimButton.clickSignal.add(this.onClaimClick);
        this.checkClaimedTiers();
    }

    override public function destroy():void {
        this.view.leftArrow.clickSignal.remove(this.onLeftClick);
        this.view.rightArrow.clickSignal.remove(this.onRightClick);
        this.selectedSignal.remove(this.onTierSelected);
    }

    private function onClaimClick(_arg_1:BaseButton):void {
        if (this.model.claimed < this.model.rank) {
            this.inProgressModal = new PurchaseInProgressModal();
            this.showPopupSignal.dispatch(this.inProgressModal);
            this.sendClaimRequest();
        }
    }

    private function sendClaimRequest():void {
        var _local1:Object = this.account.getCredentials();
        this.client.sendRequest("/supportCampaign/claim", _local1);
        this.client.complete.addOnce(this.onClaimRequestComplete);
    }

    private function onClaimRequestComplete(_arg_1:Boolean, _arg_2:*):void {
        var _local5:* = null;
        var _local3:* = null;
        var _local7:* = null;
        var _local4:* = _arg_1;
        var _local6:* = _arg_2;
        this.closePopupSignal.dispatch(this.inProgressModal);
        if (_local4) {
            try {
                _local5 = new XML(_local6);
                this.model.parseUpdateData(_local5);
            } catch (e:Error) {
                showPopupSignal.dispatch(new ErrorModal(5 * 60, "Campaign Error", "General campaign error."));
                return;
            }
            this.showPopupSignal.dispatch(new ClaimCompleteModal());
            return;
        }
        try {
            _local3 = new XML(_local6);
            _local7 = LineBuilder.getLocalizedStringFromKey(_local3.toString(), {});
            this.showPopupSignal.dispatch(new ErrorModal(5 * 60, "Campaign Error", _local7 == "" ? _local3.toString() : _local7));

        } catch (e:Error) {
            showPopupSignal.dispatch(new ErrorModal(5 * 60, "Campaign Error", "General campaign error."));

        }
    }

    private function onTierSelected(_arg_1:int):void {
        this.displayedTier = _arg_1;
        this.view.rightArrow.disabled = false;
        this.view.rightArrow.alpha = 1;
        this.view.leftArrow.disabled = false;
        this.view.leftArrow.alpha = 1;
        if (this.displayedTier == 1) {
            this.view.leftArrow.disabled = true;
            this.view.leftArrow.alpha = 0.2;
        }
        if (this.displayedTier == this.model.ranks.length) {
            this.view.rightArrow.disabled = true;
            this.view.rightArrow.alpha = 0.2;
        }
        this.showTier(_arg_1);
        this.view.selectAnimation();
        this.checkClaimedTiers();
    }

    private function showTier(_arg_1:int):void {
        this.disableArrows(true);
        this._currentTierRank = _arg_1;
        var _local2:String = this.model.getCampaignPictureUrlByRank(this._currentTierRank);
        var _local3:DisplayObject = this.model.getCampaignImageByUrl(_local2);
        if (_local3) {
            this.disableArrows(false);
            this.setArrowState();
            this.view.showTier(_arg_1, this.model.rank, this.model.claimed, _local3);
        } else {
            this._imageLoader = new ImageLoader();
            this._imageLoader.loadImage(_local2, this.onCampaignTierImageLoaded);
        }
    }

    private function onLeftClick(_arg_1:BaseButton):void {
        this.displayedTier--;
        this.view.rightArrow.disabled = false;
        this.view.rightArrow.alpha = 1;
        this.setArrowState();
        this.showTier(this.displayedTier);
        this.view.selectAnimation();
        this.checkClaimedTiers();
        this.selectedSignal.dispatch(this.displayedTier);
    }

    private function onRightClick(_arg_1:BaseButton):void {
        this.displayedTier++;
        this.view.leftArrow.disabled = false;
        this.view.leftArrow.alpha = 1;
        this.setArrowState();
        this.showTier(this.displayedTier);
        this.view.selectAnimation();
        this.checkClaimedTiers();
        this.selectedSignal.dispatch(this.displayedTier);
    }

    private function setArrowState():void {
        if (this.displayedTier <= 1) {
            this.displayedTier = 1;
        }
        if (this.displayedTier == 1) {
            this.view.leftArrow.disabled = true;
            this.view.leftArrow.alpha = 0.2;
        }
        if (this.displayedTier > this.model.ranks.length) {
            this.displayedTier = this.model.ranks.length;
        }
        if (this.displayedTier == this.model.ranks.length) {
            this.view.rightArrow.disabled = true;
            this.view.rightArrow.alpha = 0.2;
        }
    }

    private function disableArrows(_arg_1:Boolean):void {
        this.view.leftArrow.disabled = _arg_1;
        this.view.leftArrow.alpha = !_arg_1 ? 1 : 0.2;
        this.view.rightArrow.disabled = _arg_1;
        this.view.rightArrow.alpha = !_arg_1 ? 1 : 0.2;
    }

    private function checkClaimedTiers():void {
        if (this.displayedTier - this.model.claimed > 1) {
            this.view.claimButton.disabled = true;
            this.hoverTooltipDelegate.setDisplayObject(this.view.claimButton);
        } else {
            this.view.claimButton.disabled = false;
            this.hoverTooltipDelegate.removeDisplayObject();
        }
    }

    private function onCampaignTierImageLoaded(_arg_1:Event):void {
        this._imageLoader.removeLoaderListeners();
        var _local2:DisplayObject = this._imageLoader.loader;
        this.model.addCampaignImageByUrl(this.model.getCampaignPictureUrlByRank(this._currentTierRank), _local2);
        this.disableArrows(false);
        this.setArrowState();
        this.view.showTier(this._currentTierRank, this.model.rank, this.model.claimed, _local2);
    }
}
}