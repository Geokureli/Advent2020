package props;

import io.colyseus.serializer.schema.Schema;

class GhostPlayer extends Player
{
    var key:String;
    
    public function new(key:String, x = 0.0, y = 0.0, color = 0xFFFFFF)
    {
        this.key = key;
        super(x, y, color);
        
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
        var newPos = FlxPoint.get(x + frameWidth / 2, y + frameHeight / 2);
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
                    testColor = color = change.value;
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