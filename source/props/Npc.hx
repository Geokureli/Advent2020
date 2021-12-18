package props;

import data.PlayerSettings;
import data.Skins;
import states.OgmoState;

import flixel.math.FlxPoint;

typedef NpcValues = { skin:String, ?name:String, isUser:Bool };

class Npc extends GhostPlayer implements IOgmoPath
{
    public var ogmoPath:OgmoPath = null;
    public var moveTimer = 0.0;
    public var stillTime = 1.0;
    public function new(x = 0.0, y = 0.0, skin:String, name:String)
    {
        var skinId = Skins.getIdByName(skin);
        if (name == null)
            name = Skins.getData(skinId).proper;
        
        super('npc:$name', name, x, y, new PlayerSettings(skinId));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateAI(elapsed);
    }
    
    function updateAI(elapsed:Float)
    {
        if (isAtTarget())
        {
            if (moveTimer < stillTime)
                moveTimer += elapsed;
            else
            {
                moveTimer = 0;
                startNewPath();
            }
        }
    }
    
    function isAtTarget()
    {
        return targetPos == null && ogmoPath != null && ogmoPath.length > 0;
    }
    
    function cancelPath(startNew = true)
    {
        targetPos = null;
        if (startNew)
            startNewPath();
    }
    
    function startNewPath()
    {
        var pos = ogmoPath.shift();
        setTargetPos(FlxPoint.weak(pos.x + 16, pos.y));
        ogmoPath.push(pos);
    }
    
    inline static public function fromEntity(data, ?skin, ?name, isUser = false)
    {
        return factory(Npc.new, data, skin, name, isUser);
    }
    
    static function factory<T:Npc>
        ( constructor:(Float, Float, String, String)->T
        , data:OgmoEntityData<NpcValues>
        , ?skin:String
        , ?name:String
        , isUser = false
        )
    {
        if (skin == null && data.values != null && data.values.skin != "" && data.values.skin != null)
            skin = data.values.skin;
        
        if (name == null && data.values != null && data.values.name != "" && data.values.name != null)
            name = data.values.name;
        
        var npc = constructor(data.x + data.originX, data.y + data.originY - 40, skin, name);
        
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