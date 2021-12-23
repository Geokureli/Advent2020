package props;

import data.PlayerSettings;
import flixel.util.FlxSignal;
import flixel.FlxG;
import flixel.math.FlxPoint;

class Waiter extends Npc
{
    public var onServe(default, null) = new FlxTypedSignal<(Placemat)->Void>();
    public var onBus(default, null) = new FlxTypedSignal<(Placemat)->Void>();
    public var onRefill(default, null) = new FlxTypedSignal<(Placemat)->Void>();
    
    public var targetTable:CafeTable = null;
    public var notif:Notif;
    
    public function new(x = 0.0, y = 0.0, skin:String, name:String)
    {
        super(x, y, skin, name);
        
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (notif != null)
        {
            if (PlayerSettings.user.order != RANDOM)
            {
                notif.destroy();
                notif = null;
                return;
            }
            notif.update(elapsed);
        }
        // TODO: listen for PlayerSettings.user to be created
        // instead of waiting in an update
        else if (PlayerSettings.user.order == RANDOM)
        {
            notif = new Notif();
            notif.animate();
        }
    }
    
    override function draw()
    {
        super.draw();
        if (notif != null)
        {
            notif.x = x + (width - notif.width) / 2;
            notif.y = y - 32;
            notif.draw();
        }
    }
    
    public function goToPriorityTable(tables:Array<CafeTable>)
    {
        var oldTable = targetTable;
        var node = FlxPoint.get();
        var closestDistance = -1;
        for (table in tables)
        {
            node.set(table.node.x, table.node.y);
            var distance = getPathLengthTo(node);
            if (distance != -1 && (distance < closestDistance || closestDistance == -1))
            {
                closestDistance = distance;
                targetTable = table;
            }
        }
        node.put();
        
        if (oldTable == null && targetTable != null)
            cancelPath();
    }
    
    override function targetPosReached()
    {
        if (targetTable != null
        && targetTable.node.x == targetPos.x
        && targetTable.node.y == targetPos.y)
            targetTable.onWaiterReach(this);
        
        targetTable = null;
        super.targetPosReached();
    }
    
    override function startNewPath()
    {
        if (targetTable != null)
            setTargetPos(FlxPoint.weak(targetTable.node.x, targetTable.node.y));
        else
        {
            var pos = FlxG.random.getObject(ogmoPath);
            setTargetPos(FlxPoint.weak(pos.x, pos.y));
        }
    }
    
    inline static public function fromEntity(data)
    {
        return Npc.factory(Waiter.new, data);
    }
}