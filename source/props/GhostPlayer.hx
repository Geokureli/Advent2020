package props;

import flixel.util.FlxSignal;
import Types;
import utils.Log;

import flixel.math.FlxPoint;

import io.colyseus.serializer.schema.Schema;

class GhostPlayer extends Player
{
    public var key(default, null):String;
    public var onJoinFinish(default, null) = new FlxSignal();
    var leaveCallback:()->Void;
    var netDestination = new FlxPoint();
    
    public function new(key:String, name:String, x = 0.0, y = 0.0, settings)
    {
        this.key = key;
        
        super(x, y, name, settings);
        targetPos = FlxPoint.get(this.x, this.y);
        if (x != 0 || y != 0)
            netState = Idle;
        
        usePaths = true;
    }
    
    override function setSkin(skin:Int)
    {
        var error = false;
        try
        {
            super.setSkin(skin);
        }
        catch(e)
        {
            trace('Error: $e. showing tankman');
            super.setSkin(0);
            #if debug
            // red name so we know it's happening
            nameColor = 0xFFff0000;
            #end
        }
        
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        updateMovement(false, false, false, false, false, false);
        
        if (leaveCallback != null && velocity.x == 0 && velocity.y == 0 && acceleration.x == 0 && acceleration.y == 0)
            leaveCallback();
    }
    
    public function onChange(changes:Array<DataChange>)
    {
        Log.netVerbose('avatar changes[$key] ' 
            + ([for (change in changes) outputChange(change)].join(", "))
        );
        
        var oldNetState = netState;
        var isMoving = false;
        
        for (change in changes)
        {
            switch (change.field)
            {
                case "x":
                    netDestination.x = Std.int(change.value);
                    isMoving = true;
                case "y":
                    netDestination.y = Std.int(change.value);
                    isMoving = true;
                case "skin":
                    settings.skin = change.value;
                    setSkin(change.value);
                case "netState":
                    netState = change.value;
                case "state":
                    state = change.value;
                case "name":
                    updateNameText(change.value);
                case "emote":
                    var newType = (change.value:EmoteType);
                    if (emote.type != newType)
                        emote.animate(newType);
            }
        }
        
        // trace('$netState != $oldNetState && $oldNetState == ${Joining}:'
        //     + (netState != oldNetState && oldNetState == Joining)
        //     + '\n($x, $y)->(${netDestination.x}, ${netDestination.y})');
        
        // Check 0,0 because sometimes state doesn't change to 1 and the walk in from 0, 0
        if ((netState != oldNetState && oldNetState == Joining) || x == 0 || y == 0)
        {
            x = netDestination.x;
            y = netDestination.y;
            targetPos = FlxPoint.get(x, y);
            netState = Idle;//Todo: fix
            onJoinFinish.dispatch();
        }
        else if (isMoving)
        {
            Log.netVerbose('moving to $netDestination');
            setTargetPos(netDestination);
        }
    }
    
    public function leave(callback:()->Void)
    {
        leaveCallback = callback;
    }
    
    inline function outputChange(change:DataChange)
    {
        return change.field + ":" + change.previousValue + "->" + change.value;
    }
    
    override function destroy()
    {
        super.destroy();
        leaveCallback = null;
    }
}