package ui;

import flixel.input.IFlxInput;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.ui.FlxButton;

class Button extends FlxTypedButton<FlxSprite>
{
    public function new(x = 0.0, y = 0.0, ?onClick:Void->Void, graphic, ?labelGraphic:FlxGraphicAsset)
    {
        super(x, y, onClick);
        
        allowSwiping = false;
        this.statusAnimations[FlxButton.HIGHLIGHT] = "normal";
        setGraphic(graphic);
        
        if (labelGraphic != null)
            setLabelGraphic(labelGraphic);
    }
    
    inline public function setGraphic(graphic):Void
    {
        this.loadGraphic(graphic);
        this.loadGraphic(graphic, true, Std.int(this.width / 2), Std.int(this.height));
    }
    
    override function updateStatus(input:IFlxInput)
    {
        super.updateStatus(input);
        if (currentInput != null && !allPressed.contains(this))
            allPressed.push(this);
        else if (currentInput == null && allPressed.contains(this))
            allPressed.remove(this);
    }
    
    inline public function setLabelGraphic(graphic):Void
    {
        if (this.label != null)
            this.label.loadGraphic(graphic);
        else
            this.label = new FlxSprite(graphic);
    }
    
    override function destroy()
    {
        super.destroy();
        
        if (allPressed.contains(this))
            allPressed.remove(this);
    }
    
    static var allPressed(default, null) = new Array<Button>();
    
    public static function isBlockingMouse() return allPressed.length > 0;
}

@:forward
abstract SimpleButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick, id:String, ?icon)
    {
        this = new Button(x, y, onClick, 'assets/images/ui/buttons/$id.png', icon);
    }
}

@:forward
abstract IconButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?icon:String, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "iconBtn", icon);
    }
}

@:forward
abstract YesButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "yes");
    }
}

@:forward
abstract NoButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "no");
    }
}

@:forward
abstract OkButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "ok");
    }
}

@:forward
abstract LoadButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "load");
    }
}

@:forward
abstract BackButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "back");
    }
}

class FullscreenButton extends Button
{
    public function new(x = 0.0, y = 0.0)
    {
        super(x, y, toggle, "assets/images/ui/buttons/fullscreen_off.png");
    }
    
    function toggle():Void
    {
        FlxG.fullscreen = !FlxG.fullscreen;
        this.setGraphic('assets/images/ui/buttons/fullscreen_${FlxG.fullscreen ? "on" : "off"}.png');
    }
}

@:forward
abstract EmoteButton(Button) to Button
{
    inline public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new SimpleButton(x, y, onClick, "emote");
    }
}