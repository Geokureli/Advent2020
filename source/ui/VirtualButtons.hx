package ui;

import flixel.ui.FlxVirtualPad;

class VirtualButtons extends FlxVirtualPad
{
    static var _instance:VirtualButtons;
    static public var instance(get, null):VirtualButtons;
    
    public var enabled = true;
    
    public function new()
    {
        super(FULL, A_B);
    }
    
    override function destroy()
    {
        // super.destroy();
    }
    
    static public function getEnabled():Bool;
    {
        return _instance != null && _instance.enabled;
    }
    
    static function get_instance()
    {
        if (_instance == null)
            _instance = new VirtualPad();
        
        return _instance;
    }
}