package props;

import data.PlayerSettings;
import data.Skins;
import states.OgmoState;

import flixel.math.FlxPoint;

typedef NpcValues = { skin:String, ?username:String };

class Npc extends GhostPlayer implements IOgmoPath
{
    public var username(default, null):String;
    public var ogmoPath:OgmoPath = null;
    public var moveTimer = 0.0;
    public function new(x = 0.0, y = 0.0, skin:String, username:String)
    {
        this.username = username;
        var skinId = Skins.getIdByName(skin);
        var name = username != null ? username : Skins.getData(skinId).proper;
        
        super('npc:$name', name, x, y, new PlayerSettings(skinId));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (targetPos == null && ogmoPath != null && ogmoPath.length > 0)
        {
            if (moveTimer < 1)
                moveTimer += elapsed;
            else
            {
                moveTimer = 0;
                var pos = ogmoPath.shift();
                setTargetPos(FlxPoint.weak(pos.x + 16, pos.y));
                ogmoPath.push(pos);
            }
        }
    }
    
    static public function fromEntity(data:OgmoEntityData<NpcValues>, ?skin:String, ?username:String)
    {
        if (skin == null && data.values != null && data.values.skin != "" && data.values.skin != null)
            skin = data.values.skin;
        
        if (username == null && data.values != null && data.values.username != "" && data.values.username != null)
            username = data.values.username;
        
        var npc = new Npc(data.x + data.originX, data.y + data.originY - 40, skin, username);
        
        if (data.flippedX == true)
        {
            npc.facing = RIGHT;
            npc.state.flipped = true;
        }
        
        if (data.nodes != null)
        {
            data.nodes.push({x:data.x, y:data.y});
            data.nodes.setObjectPath(npc);
        }
        
        return npc;
    }
}