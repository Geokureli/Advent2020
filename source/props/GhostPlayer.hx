package props;

import Types;
import ui.Font;
import utils.Log;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;

import io.colyseus.serializer.schema.Schema;

class GhostPlayer extends Player
{
    public var key(default, null):String;
    public var name(default, null):String;
    var nameText:FlxBitmapText;
    var leaveCallback:()->Void;
    
    public function new(key:String, name:String, x = 0.0, y = 0.0, settings)
    {
        this.key = key;
        
        nameText = new FlxBitmapText();
        nameText.color = 0xFF000000;
        nameText.alignment = CENTER;
        #if FLX_DEBUG
        nameText.ignoreDrawDebug = true;
        #end
        
        super(x, y, settings);
        targetPos = FlxPoint.get(this.x, this.y);
        
        updateNameText(name);
        
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
            nameText.color = 0xFFff0000;
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
    
    override function draw()
    {
        super.draw();
        if (nameText.visible)
        {
            nameText.alpha = alpha;
            nameText.x = x + (width - nameText.width) / 2;
            nameText.y = y + height - frameHeight - nameText.height - 16;
            nameText.draw();
        }
    }
    
    public function onChange(changes:Array<DataChange>)
    {
        Log.netVerbose('avatar changes[$key] ' 
            + ([for (change in changes) outputChange(change)].join(", "))
        );
        
        var oldState = state;
        var newPos = FlxPoint.get(x, y);
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
                case "skin":
                    settings.skin = change.value;
                    setSkin(change.value);
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
        
        if (state != oldState && oldState == Joining)
        {
            x = newPos.x;
            y = newPos.y;
            targetPos = FlxPoint.get(x, y);
        }
        else if (isMoving)
        {
            Log.netVerbose('moving to $newPos');
            setTargetPos(newPos);
        }
        newPos.put();
    }
    
    public function leave(callback:()->Void)
    {
        leaveCallback = callback;
    }
    
    function updateNameText(name:String)
    {
        nameText.text = name == null ? "" : name;
        nameText.visible = name != null;
        this.name = name;
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