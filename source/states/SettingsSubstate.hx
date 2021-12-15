package states;

import flixel.group.FlxGroup;
import data.Save;
import ui.Button;
import ui.Controls;
import ui.Font;
import ui.UiBox;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.text.FlxBitmapText;

class SettingsSubstate extends flixel.FlxSubState
{
    override function create()
    {
        super.create();
        
        camera = new FlxCamera().copyFrom(camera);
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera, false);
        
        var bg = UiBox.toStageXYMargin(60, 60);
        add(bg);
        
        var title = new FlxBitmapText(new NokiaFont16());
        title.text = "Settings";
        title.screenCenter(X);
        title.y = bg.top + 10;
        add(title);
        
        var back = new BackButton(close);
        back.x = bg.right - back.width - 6;
        back.y = bg.top + 6;
        add(back);
        
        final GAP = 50;
        var buttons = new FlxTypedGroup<Button>();
        buttons.add(new SoundButton());
        buttons.add(new FullscreenButton());
        buttons.add(new ShowNameButton());
        add(buttons);
        
        var buttonsLeft = (FlxG.width - buttons.members[0].width * buttons.length - (GAP * buttons.length - GAP)) / 2;
        for (i=>button in buttons.members)
        {
            button.x = buttonsLeft + i * (GAP + button.width);
            button.y = (FlxG.height - button.height) / 2;
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (Controls.justPressed.B)
            close();
    }
    
    override function close()
    {
        FlxG.cameras.remove(camera);
        super.close();
    }
}

class ShowNameButton extends Button
{
    public function new(x = 0.0, y = 0.0)
    {
        super(x, y, toggle, getPath());
    }
    
    function toggle():Void
    {
        Save.toggleShowName();
        this.setGraphic(getPath());
    }
    
    inline function getPath()
        return 'assets/images/ui/buttons/show_name_${Save.showName ? "on" : "off"}.png';
}

class SoundButton extends Button
{
    public function new(x = 0.0, y = 0.0)
    {
        super(x, y, toggle, getPath());
    }
    
    function toggle():Void
    {
        FlxG.sound.toggleMuted();
        this.setGraphic(getPath());
    }
    
    inline function getPath()
        return 'assets/images/ui/buttons/sound_${FlxG.sound.muted ? "on" : "off"}.png';
}