package ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;

class MusicPopup extends FlxTypedSpriteGroup<FlxSprite>
{
    static var instance(default, null):MusicPopup;
    
    inline static var MAIN_PATH = "assets/images/ui/music/popup.png";
    inline static var BAR_PATH = "assets/images/ui/music/popup_bar.png";
    
    var main:FlxSprite;
    var bar:FlxSprite;
    var text:FlxBitmapText;
    
    public function new()
    {
        super();
        
        add(bar = new FlxSprite(BAR_PATH));
        add(main = new FlxSprite(MAIN_PATH));
        add(text = new FlxBitmapText());
        visible = false;
    }
    
    override function destroy()
    {
        // super.destroy();
    }
    
    static public function getInstance()
    {
        if (instance == null)
            instance = new MusicPopup();
        return instance;
    }
}