package props;

import Types;
import ui.Font;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;

import io.colyseus.serializer.schema.Schema;

class GhostPlayer extends Player
{
    var key:String;
    var name:String;
    var nameText:FlxBitmapText;
    
    public function new(key:String, name:String, x = 0.0, y = 0.0, settings)
    {
        this.key = key;
        super(x, y, settings);
        
        targetPos = FlxPoint.get(this.x, this.y);
        nameText = new FlxBitmapText();
        nameText.alignment = CENTER;
        updateNameText(name);
        shader = new vfx.GhostShader();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        updateMovement(false, false, false, false, false, false);
        
        var ghostShader = Std.downcast(shader, vfx.GhostShader);
        if (ghostShader != null)
        {
            var screenPos = getScreenPosition();
            ghostShader.updatePosRound(screenPos.x, screenPos.y);
            screenPos.put();
        }
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
            trace('moving to $newPos');
            setTargetPos(newPos);
        }
        newPos.put();
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
}