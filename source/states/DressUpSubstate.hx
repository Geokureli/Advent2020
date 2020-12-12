package states;


import flixel.group.FlxSpriteGroup;
import data.Calendar;
import data.NGio;
import data.Save;
import data.PlayerSettings;
import data.Skins;
import ui.Button;
import ui.Controls;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

import openfl.utils.Assets;

import haxe.Json;

class DressUpSubstate extends flixel.FlxSubState
{
    inline static var BAR_MARGIN = 8;
    inline static var SIDE_GAP = 48;
    inline static var SPACING = 28;
    
    var sprites = new FlxTypedSpriteGroup<SkinDisplay>();
    var current = -1;
    var nameText = new FlxBitmapText();
    var descText = new FlxBitmapText();
    var arrowLeft:Button;
    var arrowRight:Button;
    var ok:Button;
    // prevents instant selection
    var wasAReleased = false;
    
    var currentSprite(get, never):SkinDisplay;
    inline function get_currentSprite() return sprites.members[current];
    var currentSkin(get, never):SkinData;
    inline function get_currentSkin() return sprites.members[current].data;
    
    override function create()
    {
        super.create();
        
        var bg = new FlxSprite();
        add(bg);
        add(sprites);
        
        var instructions = new FlxBitmapText();
        instructions.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        instructions.text = "Select an avatar!\nThis is how other players will see you";
        instructions.screenCenter(X);
        instructions.y = 32;
        instructions.scrollFactor.set(0, 0);
        instructions.alignment = CENTER;
        instructions.scale.set(2, 2);
        add(instructions);
        
        var top:Float = FlxG.height;
        var bottom:Float = 0;
        
        for (i in 0...Skins.getLength())
        {
            var data = Skins.getDataSorted(i);
            var sprite = new SkinDisplay(data);
            sprites.add(sprite);
            sprite.scale.set(2, 2);
            sprite.updateHitbox();
            sprite.scrollFactor.set(0, 0);
            
            sprite.x = SPACING * i;
            if (data.offsetX != null)
                sprite.offset.x = data.offsetX;
            
            if (data.index == PlayerSettings.user.skin)
            {
                current = i;
                sprite.x += SIDE_GAP;
                camera.follow(sprite);
            }
            else if (i > current && current > -1)
                sprite.x += SIDE_GAP * 2;
            
            sprite.y = (FlxG.height - sprite.height) / 2;
            
            if (!data.unlocked)
                sprite.color = FlxColor.BLACK;
            
            top = Math.min(top, sprite.y);
            bottom = Math.max(bottom, sprite.y + sprite.height);
        }
        top -= BAR_MARGIN;
        
        nameText.text = currentSkin.proper;
        nameText.screenCenter(X);
        nameText.y = top - nameText.height;
        nameText.scrollFactor.set(0, 0);
        top -= nameText.height + BAR_MARGIN;
        add(nameText);
        
        descText.text = currentSkin.description;
        descText.alignment = CENTER;
        descText.fieldWidth = Std.int(FlxG.width * .75);
        descText.width = descText.fieldWidth;
        descText.height = 1000;
        descText.wordWrap = true;
        descText.screenCenter(X);
        descText.y = bottom + BAR_MARGIN;
        descText.scrollFactor.set(0, 0);
        bottom += descText.height + BAR_MARGIN * 2;
        add(descText);
        
        if (!FlxG.onMobile)
        {
            var keysText = new FlxBitmapText();
            keysText.text = "Arrow Keys to Select, Space to confrim";
            keysText.x = 10;
            keysText.y = FlxG.height - keysText.height;
            keysText.scrollFactor.set(0, 0);
            keysText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            add(keysText);
        }
        
        bg.y = top;
        bg.makeGraphic(FlxG.width, Std.int(bottom - top), 0xFF555555);
        bg.scrollFactor.set(0, 0);
        
        add(arrowLeft  = new Button(0, 0, toPrev, "assets/images/ui/leftArrow.png"));
        arrowLeft.x  = (FlxG.width - arrowLeft.width  - SIDE_GAP - SPACING) / 2;
        arrowLeft.y  = bg.y + (bg.height - arrowLeft.height ) / 2;
        arrowLeft.scrollFactor.set(0, 0);
        add(arrowRight = new Button(0, 0, toNext, "assets/images/ui/rightArrow.png"));
        arrowRight.x = (FlxG.width - arrowRight.width + SIDE_GAP + SPACING) / 2;
        arrowRight.y = bg.y + (bg.height - arrowRight.height) / 2;
        arrowRight.scrollFactor.set(0, 0);
        add(ok = new Button(0, 0, select, "assets/images/ui/ok.png"));
        ok.screenCenter(X);
        ok.y = bottom + BAR_MARGIN;
        ok.scrollFactor.set(0, 0);
        
        hiliteCurrent();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!wasAReleased && Controls.released.A)
            wasAReleased = true;
        
        if (Controls.justPressed.RIGHT)
            toNext();
        if (Controls.justPressed.LEFT)
            toPrev();
        if (Controls.justPressed.A && wasAReleased)
            select();
        if (Controls.justPressed.B)
            close();
    }
    
    function toNext():Void
    {
        if(current >= sprites.length - 1)
            return;
        
        unhiliteCurrent();
        currentSprite.x -= SIDE_GAP;
        current++;
        currentSprite.x -= SIDE_GAP;
        hiliteCurrent();
    }
    
    function toPrev():Void
    {
        if(current <= 0)
            return;
        
        unhiliteCurrent();
        currentSprite.x += SIDE_GAP;
        current--;
        currentSprite.x += SIDE_GAP;
        hiliteCurrent();
    }
    
    function unhiliteCurrent()
    {
        currentSprite.unseen.visible
            = currentSkin.unlocked && !Save.hasSeenskin(currentSkin.index);
    }
    
    function hiliteCurrent()
    {
        sprites.x = (current+1) * -SPACING - BAR_MARGIN*2 + (FlxG.width - currentSprite.width) / 2;
        
        if (currentSkin.unlocked)
        {
            nameText.text = currentSkin.proper;
            descText.text = currentSkin.description;
            ok.active = true;
            ok.alpha = 1;
            if (currentSprite.unseen.visible && !Calendar.isDebugDay)
                Save.skinSeen(currentSkin.index);
        }
        else
        {
            nameText.text = "???";
            final KEEP_PLAYING = "Keep playing every day to unlock";
            final LOGIN = "Log in to Newgrounds to unlock this";
            descText.text = KEEP_PLAYING;
            if (currentSkin.unlocksBy != null)
            {
                descText.text = switch (currentSkin.unlocksBy.split(":"))
                {
                    case ["login"    ]: LOGIN;
                    case ["medal", day]: NGio.isLoggedIn ? KEEP_PLAYING : LOGIN;
                    case ["supporter"]: "Become a newgrounds supporter to unlock this";
                    default: KEEP_PLAYING;
                }
            }
            ok.active = false;
            ok.alpha = 0.5;
        }
        nameText.screenCenter(X);
        descText.screenCenter(X);
    }
    
    function select():Void
    {
        if (currentSkin.unlocked)
        {
            Save.setSkin(currentSkin.index);
            close();
        }
    }
}

class SkinDisplay extends FlxSprite
{
    public final data:SkinData;
    public final unseen:FlxSprite;
    
    public function new (data:SkinData, x = 0.0, y = 0.0)
    {
        this.data = data;
        super(x, y);
        
        data.loadTo(this);
        unseen = new FlxSprite("assets/images/ui/new.png");
        unseen.visible = data.unlocked && !Save.hasSeenskin(data.index);
    }
    
    override function draw()
    {
        super.draw();
        if (unseen.visible)
        {
            unseen.x = x + width - unseen.width / 2;
            unseen.y = y - unseen.height;
            unseen.draw();
        }
    }
}