package props;

import states.OgmoState;
import states.rooms.RoomState;
import utils.DebugLine;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxVector;

class CafeTable extends FlxSpriteGroup
{
    public var node(default, null):OgmoPosData = null;
    public var needsService(default, null) = false;
    
    var placemats = new FlxTypedGroup<Placemat>();
    
    var center:FlxVector;
    
    public function new (x, y, center:FlxVector)
    {
        this.center = center;
        super(x, y);
        
        #if debug
        ignoreDrawDebug = true;
        #end
    }
    
    public function checkServiceNeeds()
    {
        needsService = false;
        for (placemat in placemats)
        {
            placemat.checkServiceNeeds();
            if (placemat.needsService)
                needsService = true;
        }
    }
    
    public function addPlacemat(placemat:Placemat)
    {
        placemat.x -= x;
        placemat.y -= y;
        add(placemat);
        placemats.add(placemat);
    }
    
    inline public function contains(sprite:FlxSprite)
    {
        return members.contains(sprite);
    }
    
    public function getClosestNode(path:OgmoPath)
    {
        var v = FlxVector.get();
        var shortestSquared = Math.POSITIVE_INFINITY;
        for (node in path)
        {
            v.set(node.x - center.x, node.y - center.y);
            if (shortestSquared > v.lengthSquared)
            {
                shortestSquared = v.lengthSquared;
                this.node = node;
            }
        }
        v.put();
        
        #if debug
        var line = new DebugLine();
        add(line);
        line.camera = Std.downcast(FlxG.state, RoomState).debugCamera;
        line.set(center.x, center.y, node.x, node.y);
        #end
        
        return this.node;
    }
    
    public function onWaiterReach(waiter:Waiter)
    {
        for (placemat in placemats)
        {
            if (placemat.needsService)
                placemat.service(waiter);
        }
    }
    
    static public function fromDecal(bottom:OgmoDecal)
    {
        var center = FlxVector.get
            ( bottom.x + bottom.width - (bottom.frameWidth) / 2
            , bottom.y + bottom.height - (bottom.frameHeight) / 2
            );
        var table = new CafeTable(bottom.x, bottom.y, center);
        bottom.x -= table.x;
        bottom.y -= table.y;
        table.add(bottom);
        return table;
    }
    
    static public function fromPlacemats(list:Array<Placemat>)
    {
        var l = Math.POSITIVE_INFINITY;
        var t = Math.POSITIVE_INFINITY;
        var r = Math.NEGATIVE_INFINITY;
        var b = Math.NEGATIVE_INFINITY;
        
        for (placemat in list)
        {
            if (l > placemat.x)
                l = placemat.x;
            
            if (r < placemat.x + placemat.width)
                r = placemat.x + placemat.width;
            
            if (t > placemat.y)
                t = placemat.y;
            
            if (b < placemat.y + placemat.height)
                b = placemat.y + placemat.height;
        }
        
        var table = new CafeTable(l, t, FlxVector.get((l + r) / 2, (t + b) / 2));
        for (placemat in list)
            table.addPlacemat(placemat);
        
        return table;
    }
}