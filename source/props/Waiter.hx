package props;

import flixel.FlxG;
import flixel.math.FlxPoint;

class Waiter extends Npc
{
    public var targetTable:CafeTable = null;
    
    public function new(x = 0.0, y = 0.0, skin:String, name:String)
    {
        super(x, y, skin, name);
    }
    
    public function goToPriorityTable(tables:Array<CafeTable>)
    {
        var oldTable = targetTable;
        var node = FlxPoint.get();
        var closestDistance = -1;
        for (table in tables)
        {
            if (table.needsPlayerService)
            {
                targetTable = table;
                break;
            }
            
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