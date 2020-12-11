package data;

import data.Content;
import props.Player;

class PlayerSettings
{
    public static var user:PlayerSettings;
    
    public var skin:Int;
    public var instrument:InstrumentType;
    
    public function new(skin = 0, instrument = null)
    {
        this.skin = skin;
    }
    
    public function applyTo(player:Player)
    {
        player.setSkin(skin);
    }
    
    static public function fromSave()
    {
        return new PlayerSettings(Save.getSkin(), Save.getInstrument());
    }
}