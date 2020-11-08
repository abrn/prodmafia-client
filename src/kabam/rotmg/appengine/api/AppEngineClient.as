package kabam.rotmg.appengine.api {
    import org.osflash.signals.OnceSignal;
    
    public interface AppEngineClient {
        function get complete(): OnceSignal;
        
        function setDataFormat(_arg_1: String): void;
        
        function setSendEncrypted(_arg_1: Boolean): void;
        
        function setMaxRetries(_arg_1: int): void;
        
        function sendRequest(url: String, params: Object, unknown: Boolean = false): void;
        
        function requestInProgress(): Boolean;
    }
}