package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.ui.FlxButton;

class Button extends FlxTypedButton<FlxSprite>
{
    public function new(x = 0.0, y = 0.0, ?onClick:Void->Void, graphic, ?labelGraphic:FlxGraphicAsset)
    {
        super(x, y, onClick);
        
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
    
    inline public function setLabelGraphic(graphic):Void
    {
        if (this.label != null)
            this.label.loadGraphic(graphic);
        else
            this.label = new FlxSprite(graphic);
    }
}

@:forward
abstract IconButton(Button) to Button
{
    inline static public var GRAPHIC = "assets/images/ui/buttons/iconBtn.png";
    
    inline public function new(x = 0.0, y = 0.0, ?icon:String, ?onClick)
    {
        this = new Button(x, y, onClick, GRAPHIC, icon);
    }
}

@:forward
abstract YesButton(Button) to Button
{
    public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new Button(x, y, onClick, "assets/images/ui/buttons/yes.png");
    }
}

@:forward
abstract NoButton(Button) to Button
{
    public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new Button(x, y, onClick, "assets/images/ui/buttons/no.png");
    }
}

@:forward
abstract OkButton(Button) to Button
{
    public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new Button(x, y, onClick, "assets/images/ui/buttons/button_ok.png");
    }
}

@:forward
abstract BackButton(Button) to Button
{
    public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new Button(x, y, onClick, "assets/images/ui/buttons/back.png");
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