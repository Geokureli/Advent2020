package utils;

class MultiCallback
{
    public var callback:()->Void;
    public var logId:String = null;
    public var length(default, null) = 0;
    public var numRemaining(default, null) = 0;
    
    var unfired = new Map<String, ()->Void>();
    var fired = new Array<String>();
    
    public function new (callback:()->Void, logId:String = null)
    {
        this.callback = callback;
        this.logId = logId;
    }
    
    public function add(id = "untitled")
    {
        id = '$length:$id';
        length++;
        numRemaining++;
        var func:()->Void = null;
        func = function ()
        {
            if (unfired.exists(id))
            {
                unfired.remove(id);
                fired.push(id);
                numRemaining--;
                
                if (logId != null)
                    trace('fired $logId - $id');
                
                if (numRemaining == 0)
                    callback();
            }
        }
        unfired[id] = func;
        return func;
    }
    
    public function getFired() return fired.copy();
    public function getUnfired() return [for (id in unfired) id];
}