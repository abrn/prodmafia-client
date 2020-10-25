package kabam.rotmg.chat.control {
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.game.events.ReconnectEvent;
import com.company.assembleegameclient.objects.GameObject;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.parameters.Parameters;

import flash.events.Event;
import flash.utils.Dictionary;
import flash.utils.getTimer;

import kabam.rotmg.account.core.Account;
import kabam.rotmg.appengine.api.AppEngineClient;

import kabam.rotmg.chat.model.ChatMessage;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.game.model.GameInitData;
import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.game.signals.PlayGameSignal;
import kabam.rotmg.servers.api.Server;
import kabam.rotmg.ui.model.HUDModel;
import kabam.rotmg.ui.signals.EnterGameSignal;

public class ParseChatMessageCommand {
    [Inject]
    public var data:String;
    [Inject]
    public var hudModel:HUDModel;
    [Inject]
    public var addTextLine:AddTextLineSignal;
    [Inject]
    public var enterGame:EnterGameSignal;
    [Inject]
    public var playGame:PlayGameSignal;
    [Inject]
    public var account:Account;

    public function ParseChatMessageCommand() {
        super();
    }

    public function execute() : void {
        var go:GameObject;
        var split:Array = this.data.split(" ");
        // casting is to string is unnecessary, but allows for fast usage search of toLowerCase(),
        // should it ever be needed
        var command:String = (split[0] as String).toLowerCase();
        var fpsText:String = "", fpsParam:String = "";
        switch (command) {
            case "/h":
            case "/help":
                if (split.length == 1)
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "helpCommand"));
                else
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Invalid syntax! This command does not use any arguments."));
                return;
            case "/c":
            case "/class":
            case "/classes":
                if (split.length == 1) {
                    var objDict:Dictionary = new Dictionary();
                    var playerCount:int = 0;
                    for each (go in this.hudModel.gameSprite.map.goDict_)
                        if (go.props_.isPlayer_) {
                            objDict[go.objectType_] = objDict[go.objectType_] != undefined ?
                                    objDict[go.objectType_] + 1 : 1;
                            playerCount++;
                        }

                    var text:String = "";
                    for (var objType:int in objDict)
                        text += (" " + ObjectLibrary.typeToDisplayId_[objType] + ": " + objDict[objType]);

                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Classes online (" + playerCount + "):" + text));
                } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Invalid syntax! This command does not use any arguments."));
                return;
            case "/chatlength":
            case "/cl":
                if (split.length == 2) {
                    var len:int = parseInt(split[1]);
                    if (!isNaN(len)) {
                        Parameters.data.chatLength = parseInt(split[1]);
                        Parameters.save();
                        this.hudModel.gameSprite.chatBox_.model.setVisibleItemCount();
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Chat length set to: " + Parameters.data.chatLength));
                    } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                            "Incorrect length! Make sure you are providing an integer number. (no fractions)"));
                } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Incorrect arguments! Syntax: /cl <integer>"));

                return;
            // as3 doesn't have ref vars and the alternative is ugly, so gonna be using a bit of goto
            case "/bgfps":
                fpsText = "Background FPS";
                fpsParam = "bgFPS";
                goto FPSCommand;
                return;
            case "/fgfps":
                fpsText = "Foreground FPS";
                fpsParam = "fgFPS";
                goto FPSCommand;
                return;
            case "/fps":
                fpsText = "FPS Cap";
                fpsParam = "customFPS";
                goto FPSCommand;
                return;
            case "/ip":
                if (split.length == 1) {
                    var server:Server = this.hudModel.gameSprite.gsc_.server_;
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            server.name + ": " + server.address));
                } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Invalid syntax! This command does not use any arguments."));
                return;
            case "/goto":
                if (Parameters.data.shownGotoWarning) {
                    if (split.length == 2) {
                        // todo: regex verify the ip
                        Parameters.enteringRealm = true;
                        this.jumpToIP(split[1]);
                    } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /goto <ip>"));
                } else {
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                            "WARNING! /goto can be used to steal your account information, " +
                            "meaning you should only use it on IPs you trust." +
                            "Re-send the message for it to register."));
                    Parameters.data.shownGotoWarning = true;
                }
                return;
            case "/conn":
                if (!Parameters.data.replaceCon)
                    break; // breaking so the playertext sends
                goto ConCommand;
                return;
            case "/con":
                if (Parameters.data.replaceCon)
                    break; // breaking so the playertext sends
                goto ConCommand;
                return;
            case "/pos":
            case "/loc":
                if (split.length == 1) {
                    var player:Player = this.hudModel.gameSprite.map.player_;
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Your location is x='" + player.x_ + "', y='" + player.y_ + "'"));
                } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Invalid syntax! This command does not use any arguments."));
                return;
            case "/mapscale":
            case "/mscale":
            case "/ms":
                switch (split.length) {
                    case 1:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Your current Map Scale is: " + Parameters.data.mscale));
                        break;
                    case 2:
                        var mscale:Number = parseFloat(split[1]);
                        if (!isNaN(mscale)) {
                            Parameters.data.mscale = mscale;
                            Parameters.save();
                            Parameters.root.dispatchEvent(new Event(Event.RESIZE));
                            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                    "Map Scale set to: " + Parameters.data.mscale));
                        } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect length! Make sure you are providing a number."));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /ms <float>"));
                        break;
                }
                return;
            case "/ao":
            case "/ta":
            case "/togglealpha":
                if (split.length == 1) {
                    Parameters.data.alphaOnOthers = !Parameters.data.alphaOnOthers;
                    Parameters.save();
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Player Transparency: " + (Parameters.data.alphaOnOthers ? "ON" : "OFF")));
                } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Invalid syntax! This command does not use any arguments."));
                return;
            case "/alpha":
                switch (split.length) {
                    case 2:
                        var alpha:Number = parseFloat(split[1]);
                        if (!isNaN(alpha)) {
                            Parameters.data.alphaMan = alpha;
                            Parameters.save();
                            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                    "Player Transparency value set to: " + Parameters.data.alphaMan));
                        } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect length! Make sure you are providing a number."));
                        break;
                    case 1:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Your current Player Transparency value is: " + Parameters.data.alphaMan));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /alpha <float>"));
                        break;
                }
                return;
            case "/setmsg1":
            case "/setmsg2":
            case "/setmsg3":
            case "/setmsg4":
                var msgId:int = parseInt(command.charAt(7)); // this should never be NaN, so no checks
                if (split.length > 1) {
                    Parameters.data["customMessage" + msgId] = this.data.substring(9);
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Message #" + msgId + " set to: " + Parameters.data["customMessage" + msgId]));
                } else
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Your current Message #" + msgId + " is: '" + Parameters.data["customMessage" + msgId] + "'"));
                return;
            case "/follow":
                switch (split.length) {
                    case 2:
                        // again, unnecessary but useful for code highlighting/better searching (toUpperCase)
                        // also very minor performance benefit as the object is casted to string once not 3 times
                        var name:String = split[1] as String;
                        Parameters.followName = name;
                        for each (go in this.hudModel.gameSprite.map.goDict_)
                            if (go is Player && go.name_.toUpperCase() == name.toUpperCase()) {
                                Parameters.followPlayer = go;
                                Parameters.followName = name.toUpperCase();
                                Parameters.followingName = true;
                            }
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Now following: " + Parameters.followName));
                        break;
                    case 1:
                        Parameters.followingName = false;
                        Parameters.followName = "";
                        Parameters.followPlayer = null
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "No longer following: " + Parameters.followName));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /follow <string>"));
                        break;
                }
                return;
            case "/suicide":
                if (split.length == 1) {
                    Parameters.suicideMode = !Parameters.suicideMode;
                    Parameters.suicideAT = getTimer();
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Suicide Mode: " + (Parameters.suicideMode ? "ON" : "OFF")));
                } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Invalid syntax! This command does not use any arguments."));
                return;
            case "/spd":
            case "/setspd":
                switch (split.length) {
                    case 2:
                        var speed:int = parseInt(split[1]);
                        if (!isNaN(speed)) {
                            this.hudModel.gameSprite.map.player_.speed_ = speed;
                            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                    "Speed set to: " + speed));
                        } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect length! Make sure you are providing an integer number. (no fractions)"));
                        break;
                    case 1:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Your current Speed is: " + this.hudModel.gameSprite.map.player_.speed_));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /speed <integer>"));
                        break;
                }
                return;
            case "/fakelag":
                switch (split.length) {
                    case 2:
                        var lagMS:int = parseInt(split[1]);
                        if (!isNaN(lagMS)) {
                            Parameters.data.fakeLag = lagMS;
                            Parameters.save();
                            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                    "Fake Lag set to: " + lagMS + " ms"));
                        } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect length! Make sure you are providing an integer number. (no fractions)"));
                        break;
                    case 1:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Your current Fake Lag is: " + Parameters.data.fakeLag));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /fakelag <integer>"));
                        break;
                }
                return;
            case "/recondelay":
                switch (split.length) {
                    case 2:
                        var reconDelay:int = parseInt(split[1]);
                        if (!isNaN(reconDelay)) {
                            Parameters.data.reconnectDelay = reconDelay;
                            Parameters.save();
                            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                    "Reconnect Delay set to: " + reconDelay + " ms"));
                        } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect length! Make sure you are providing an integer number. (no fractions)"));
                        break;
                    case 1:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Your current Reconnect Delay is: " + Parameters.data.reconnectDelay));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /recondelay <integer>"));
                        break;
                }
                return;
            case "/renderdist":
                switch (split.length) {
                    case 2:
                        var renderDist:int = parseInt(split[1]);
                        if (!isNaN(renderDist)) {
                            Parameters.data.renderDistance = renderDist;
                            Parameters.save();
                            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                    "Render Distance set to: " + renderDist + " tiles"));
                        } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect length! Make sure you are providing an integer number. (no fractions)"));
                        break;
                    case 1:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                "Your current Render Distance is: " + Parameters.data.renderDistance));
                        break;
                    default:
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                                "Incorrect arguments! Syntax: /renderdist <integer>"));
                        break;
                }
                return;
            default:
                this.hudModel.gameSprite.gsc_.playerText(this.data);
                return;
        }
        FPSCommand: {
            switch (split.length) {
                case 1:
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                            "Your " + fpsText + " is: " + Parameters.data[fpsParam]));
                    break;
                case 2:
                    var fps:int = parseInt(split[1]);
                    if (!isNaN(fps)) {
                        Parameters.data[fpsParam] = parseInt(split[1]);
                        Parameters.save();
                        if (fpsParam == "customFPS")
                            WebMain.STAGE.frameRate = Parameters.data[fpsParam];
                        this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME,
                                fpsText + " set to: " + Parameters.data[fpsParam]));
                    } else this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                            "Incorrect length! Make sure you are providing an integer number. (no fractions)"));
                    break;
                default:
                    this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                            "Incorrect arguments! Syntax: " + command + " <integer>"));
            }
            return;
        }
        ConCommand: {
            // noinspection UnreachableCodeJS, JSUnusedAssignment
            if (split.length <= 1 || split.length >= 6) {
                var cmd:String = Parameters.data.replaceCon ? "/conn" : "/con";
                this.addTextLine.dispatch(ChatMessage.make(Parameters.ERROR_CHAT_NAME,
                        "Usage: " + cmd + " <server> <character> <realm> <bazaar>"));
                return;
            }

            var charId:int = -1;
            var serverStr:String = "";
            var realmName:String = "";
            var bazSide:String = "";
            // noinspection JSUnusedAssignment
            for each (var argument:String in split) {
                argument = argument.toLowerCase();
                if (isServer(argument))
                    serverStr = argument;

                charId = isChar(argument);

                if (isRealmName(argument))
                    realmName = argument;

                if (argument == "left" || argument == "right")
                    bazSide = argument;
            }

            if (realmName != "") {
                Parameters.realmJoining = true;
                Parameters.realmName = realmName;
            }

            if (bazSide != "") {
                Parameters.bazaarJoining = true;
                Parameters.bazaarLR = bazSide;
                Parameters.bazaarDist = Math.random() * 10;
                if (serverStr == "" && this.hudModel.gameSprite.map.isNexus)
                    return;
            }

            jumpToServer(serverStr, charId);
            //noinspection UnnecessaryReturnStatementJS
            return;
        }

        /*if (text == "/mystic") {
            text = "Mystics in train: ";
            var _local61:int = 0;
            var _local60:* = hudModel.gameSprite.map.goDict_;
            for each(_local4 in hudModel.gameSprite.map.goDict_) {
                if (_local4.objectType_ == 803) {
                    text = text + (_local4.name_ + ", ");
                }
            }
            text = text.substring(0, text.length - 2);
            this.addTextLine.dispatch(ChatMessage.make("", text));
            text = "Mystics with > 0 and < max MP: ";
            var _local63:int = 0;
            var _local62:* = hudModel.gameSprite.map.goDict_;
            for each(_local4 in hudModel.gameSprite.map.goDict_) {
                if (_local4.objectType_ == 803) {
                    _local1 = _local4 as Player;
                    if (_local1.mp_ > 0 && _local1.mp_ < _local1.maxMP_) {
                        text = text + (_local4.name_ + ", ");
                    }
                }
            }
            text = text.substring(0, text.length - 2);
            this.addTextLine.dispatch(ChatMessage.make("", text));
            text = "Mystics stasised: ";
            _local9 = getTimer();
            var _local65:int = 0;
            var _local64:* = Parameters.mystics;
            for each(var _local19 in Parameters.mystics) {
                split = _local19.split(" ");
                text = text + (split[0] + " stasised " + (_local9 - split[1] * 1) / 1000 + " seconds ago, ");
            }
            text = text.substring(0, text.length - 2);
            this.addTextLine.dispatch(ChatMessage.make("", text));
        } else if (text == "/fpm" || text == "/fame") {
            _local9 = getTimer() - Parameters.fpmStart;
            _local30 = Math.round(Parameters.fpmGain / _local9 * 60000 * 100) / 100;
            this.hudModel.gameSprite.map.player_.textNotification(Parameters.fpmGain + " fame\n" + Math.floor(_local9 / 60000 * 10) / 10 + " minutes\n" + _local30 + " fame/min", 14835456, 50 * 60);
        } else if (text == "/fpmclear") {
            Parameters.fpmStart = getTimer();
            Parameters.fpmGain = 0;
        } else*/
    }

    public function jumpToServer(_arg_1:String, _arg_2:int = -1):void {
        var _local5:Boolean = false;
        var _local6:* = null;
        if (_arg_2 != -1 && _arg_1 == "") {
            _local5 = true;
        }
        if (_arg_2 == -1) {
            _arg_2 = this.hudModel.gameSprite.gsc_.charId_;
        }
        if (_arg_1 == "") {
            _arg_1 = Parameters.data.preferredServer;
        }
        _arg_1 = _arg_1.toLowerCase();
        var _local3:Boolean = this.hudModel.gameSprite.map && this.hudModel.gameSprite.map.player_;
        var _local4:String = Server.serverAbbreviations[_arg_1];
        if (_local4 == null && !_local5) {
            if (_local3) {
                this.hudModel.gameSprite.map.player_.addTextLine.dispatch(ChatMessage.make("*Error*", "Invalid server " + _arg_1));
            }
        } else {
            if (Parameters.data.preferredServer == _local4 && !_local5) {
                if (_local3) {
                    this.hudModel.gameSprite.map.player_.addTextLine.dispatch(ChatMessage.make("", "Already in " + _local4 + ", joining anyways"));
                }
            }
            if (_local4 && !_local5) {
                Parameters.data.preferredServer = _local4;
            }
            Parameters.save();
            this.enterGame.dispatch();
            _local6 = new GameInitData();
            _local6.createCharacter = false;
            _local6.charId = _arg_2;
            _local6.isNewGame = true;
            if (Parameters.reconNexus) {
                Parameters.reconNexus.server_ = _local6.server;
            }
            if (Parameters.reconVault) {
                Parameters.reconVault.server_ = _local6.server;
            }
            if (Parameters.reconDaily) {
                Parameters.reconDaily.server_ = _local6.server;
            }
            this.playGame.dispatch(_local6);
        }
    }

    public function jumpToIP(ip:String) : void {
        this.enterGame.dispatch();
        var gameInit:GameInitData = new GameInitData();
        gameInit.server = new Server();
        gameInit.server.port = 2050;
        gameInit.server.setName(ip);
        gameInit.server.address = ip;
        gameInit.createCharacter = false;
        gameInit.charId = this.hudModel.gameSprite.gsc_.charId_;
        gameInit.isNewGame = true;
        this.playGame.dispatch(gameInit);
    }

    private static function isServer(serverName:String) : Boolean {
        for (var key:String in Server.serverAbbreviations)
            if (key == serverName)
                return true;

        return false;
    }

    private static function isChar(charName:String) : int {
        var _local4:int = 0;
        var _local2:* = null;
        var _local5:* = null;
        var _local3:int = -1;
        _local4 = 0;
        while (_local4 < Parameters.charNames.length) {
            _local2 = charName;
            _local5 = Parameters.charNames[_local4];
            if (_local2.substr(_local2.length - 1, 1) == "2" && _local5.substr(_local5.length - 1, 1) == "2") {
                if (_local5.substring(0, _local2.length - 1) == _local2.substr(0, _local2.length - 1)) {
                    _local3 = Parameters.charIds[_local4];
                    break;
                }
            } else if (_local5.substring(0, _local2.length) == _local2) {
                _local3 = Parameters.charIds[_local4];
                break;
            }
            _local4++;
        }
        if (_local3 > 0) {
            return _local3;
        }
        return -1;
    }

    private static function isRealmName(realmName:String) : Boolean {
        var realmNames:Vector.<String> = new <String>["pirate", "deathmage", "spectre", "titan",
            "gorgon", "kraken", "satyr", "drake", "chimera", "dragon",
            "wyrm", "hydra", "leviathan", "minotaur", "mummy", "reaper",
            "phoenix", "giant", "unicorn", "harpy", "gargoyle", "snake",
            "cube", "goblin", "hobbit", "skeleton", "scorpion", "bat",
            "ghost", "slime", "lich", "orc", "imp", "spider", "demon",
            "blob", "golem", "sprite", "flayer", "ogre", "djinn",
            "cyclops", "beholder", "medusa"];

        return realmNames.indexOf(realmName) != -1;
    }
}
}