package data;

import data.Content;
import data.Order;
import props.Player;

class PlayerSettings
{
    public static var user:PlayerSettings;
    
    public var skin:Int;
    public var instrument:InstrumentType;
    public var order:Order;
    
    public function new(skin = 0, instrument = null, order = null)
    {
        this.skin = skin;
        this.instrument = instrument;
        this.order = order;
    }
    
    public function applyTo(player:Player)
    {
        player.setSkin(skin);
        player.state.order = order;
    }
    
    static public function fromSave()
    {
        return new PlayerSettings(Save.getSkin(), Save.getInstrument(), Save.getOrder());
    }
}