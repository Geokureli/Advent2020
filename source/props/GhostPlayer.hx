package props;

import flixel.math.FlxPoint;

import io.colyseus.serializer.schema.Schema;

class GhostPlayer extends Player
{
    var key:String;
    
    public function new(key:String, x = 0.0, y = 0.0, settings)
    {
        this.key = key;
        super(x, y, settings);
        
        targetPos = FlxPoint.get(this.x, this.y);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        updateMovement(false, false, false, false, false);
    }
    
    public function onChange(changes:Array<DataChange>)
    {
        trace('avatar changes[$key] ' 
            + ([for (change in changes) outputChange(change)].join(", "))
        );
        
        var oldState = state;
        var newPos = FlxPoint.get(x + width / 2, y + height / 2);
        var isMoving = false;
        
        for (change in changes)
        {
            switch (change.field)
            {
                case "x":
                    newPos.x = Std.int(change.value);
                    isMoving = true;
                case "y":
                    newPos.y = Std.int(change.value);
                    isMoving = true;
                case "color":
                    settings.color = rig.color = change.value;
                case "state":
                    state = change.value;
            }
        }
        
        if (state != oldState && oldState == Joining)
        {
            x = newPos.x;
            y = newPos.y;
            targetPos = FlxPoint.get(x, y);
        }
        else if (isMoving)
        {
            trace('moving to $newPos');
            setTargetPos(newPos);
        }
        newPos.put();
    }
    
    inline function outputChange(change:DataChange)
    {
        return change.field + ":" + change.previousValue + "->" + change.value;
    }
}