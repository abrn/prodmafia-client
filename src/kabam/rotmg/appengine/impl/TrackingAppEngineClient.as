package kabam.rotmg.appengine.impl {
import com.company.assembleegameclient.parameters.Parameters;

import flash.utils.getTimer;

import kabam.rotmg.appengine.api.AppEngineClient;
import kabam.rotmg.core.service.TrackingData;
import kabam.rotmg.core.signals.TrackEventSignal;

import org.osflash.signals.OnceSignal;

public class TrackingAppEngineClient implements AppEngineClient {


    public function TrackingAppEngineClient() {
        super();
    }
    [Inject]
    public var track:TrackEventSignal;
    [Inject]
    public var wrapped:SimpleAppEngineClient;
    private var target:String;
    private var time:int;

    public function get complete():OnceSignal {
        return this.wrapped.complete;
    }

    public function setDataFormat(_arg_1:String):void {
        this.wrapped.setDataFormat(_arg_1);
    }

    public function setSendEncrypted(_arg_1:Boolean):void {
        this.wrapped.setSendEncrypted(_arg_1);
    }

    public function setMaxRetries(_arg_1:int):void {
        this.wrapped.setMaxRetries(_arg_1);
    }

    public function sendRequest(_arg_1:String, _arg_2:Object):void {
        this.target = _arg_1;
        this.time = getTimer();
        this.wrapped.complete.addOnce(this.trackResponse);
        this.wrapped.sendRequest(_arg_1, _arg_2);
    }

    public function requestInProgress():Boolean {
        return false;
    }

    private function trackResponse(_arg_1:Boolean, _arg_2:*):void {
        var _local3:TrackingData = new TrackingData();
        _local3.category = "AppEngineResponseTime";
        _local3.action = this.target;
        _local3.value = getTimer() - this.time;
    }
}
}
