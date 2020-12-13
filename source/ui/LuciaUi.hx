package ui;

import flixel.util.FlxTimer;
import data.Lucia;
import flixel.FlxSprite;
import ui.Font;

import flixel.text.FlxBitmapText;
import flixel.group.FlxGroup;

class LuciaUi extends FlxGroup
{
    var countField:FlxBitmapText;
    var timerField:FlxBitmapText;
    
    public function new ()
    {
        super();
        var uiBun = new FlxSprite(4, 4);
        uiBun.loadGraphic("assets/images/props/shared/lucia_cat.png", true, 32, 32);
        uiBun.animation.add("anim", [for (i in 0...uiBun.animation.frames) i], 10);
        uiBun.animation.play("anim");
        uiBun.updateHitbox();
        add(uiBun);
        
        add(countField = new FlxBitmapText(new NokiaFont16()));
        countField.x = uiBun.x + uiBun.width + 4;
        countField.y = 12;
        countField.setBorderStyle(OUTLINE, 0xFF000000);
        
        add(timerField = new FlxBitmapText(new NokiaFont16()));
        timerField.x = 4;
        timerField.y = countField.y + countField.height + 4;
        timerField.setBorderStyle(OUTLINE, 0xFF000000);
        updateFields();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (Lucia.finding)
        {
            Lucia.update(elapsed);
            updateFields();
        }
    }
    
    function updateFields()
    {
        countField.text = Lucia.collected + "/" + Lucia.TOTAL;
        timerField.text = "Time: " + Lucia.getDisplayTimer();
    }
    
    public function onComplete(callback:()->Void)
    {
        var field = new FlxBitmapText(new XmasFont());
        field.setBorderStyle(OUTLINE, 0xFF000000);
        field.text = "Complete!";
        field.screenCenter();
        add(field);
        new FlxTimer().start(1.0,
            function(_)
            {
                field.kill();
                callback();
            }
        );
    }
}