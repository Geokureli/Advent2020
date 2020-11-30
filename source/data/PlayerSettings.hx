package data;

import props.Player;

class PlayerSettings
{
    public static var user:PlayerSettings;
    
    public var skin:Int;
    
    public function new(skin = 0)
    {
        this.skin = skin;
    }
    
    public function applyTo(player:Player)
    {
        #if USE_RIG
        #else
        player.setSkin(skin);
        #end
    }
}