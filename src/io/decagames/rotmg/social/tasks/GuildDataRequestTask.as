package io.decagames.rotmg.social.tasks {
import kabam.lib.tasks.BaseTask;
import kabam.rotmg.account.core.Account;
import kabam.rotmg.appengine.api.AppEngineClient;

public class GuildDataRequestTask extends BaseTask implements ISocialTask {


    public function GuildDataRequestTask() {
        super();
    }
    [Inject]
    public var client:AppEngineClient;
    [Inject]
    public var account:Account;

    private var _requestURL:String;

    public function get requestURL():String {
        return this._requestURL;
    }

    public function set requestURL(_arg_1:String):void {
        this._requestURL = _arg_1;
    }

    private var _xml:XML;

    public function get xml():XML {
        return this._xml;
    }

    public function set xml(_arg_1:XML):void {
        this._xml = _arg_1;
    }

    override protected function startTask():void {
        this.client.setMaxRetries(8);
        this.client.complete.addOnce(this.onComplete);
        this.client.sendRequest(this._requestURL, this.account.getCredentials());
    }

    private function onComplete(_arg_1:Boolean, _arg_2:*):void {
        if (_arg_1) {
            this._xml = new XML(_arg_2);
            completeTask(true);
        } else {
            completeTask(false, _arg_2);
        }
    }
}
}