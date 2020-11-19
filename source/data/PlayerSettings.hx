package data;

import props.Player;

class PlayerSettings
{
    public static var user:PlayerSettings;
    
    public var color:Int;
    
    public function new(color = 0xFFFFFF)
    {
        this.color = color;
    }
    
    public function applyTo(player:Player)
    {
        player.rig.color = color;
    }
}