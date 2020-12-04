package props;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import data.NGio;
import states.OgmoState;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;

import openfl.utils.Assets;

typedef NoteValues = { id:String };

class Note extends FlxSpriteGroup
{
    var note:FlxSprite;
    var text:FlxBitmapText;
    
    public function new(x = 0.0, y = 0.0, id:String)
    {
        super(x, y);
        add(note = new FlxSprite(0, 0, "assets/images/props/bedroom/note.png"));
        add(text = new FlxBitmapText());
        text.x = note.x + 16;
        text.y = note.y + 20;
        text.text = getText(id);
        text.color = 0xFF000000;
    }
    
    static function getText(id:String)
    {
        var text = Assets.getText('assets/data/letters/$id.txt');
        var name = NGio.userName;
        if (name == null || name == "")
            name = "UNREGISTERED NG LURKER";
        
        return text.split("[NAME]").join(name);
    }
    
    inline static var RISE = 32;
    public function animateIn(delay = 0.0, ?onComplete:()->Void)
    {
        var dither = new vfx.DitherShader();
        dither.setAlpha(0);
        note.shader = dither;
        var startY = y + RISE;
        
        function func(_)
        {
            note.shader = null;
            
            if (onComplete != null)
                onComplete();
        }
        
        FlxTween.num(0, 1, 1.0,
            { startDelay: delay
            , ease:FlxEase.circOut
            , onComplete:func
            },
            function (num)
            {
                y = startY - num * RISE;
                dither.setAlpha(num);
            }
        );
    }
    
    static public function fromEntity(data:OgmoEntityData<NoteValues>)
    {
        var note = new Note(0, 0, data.values.id);
        data.applyToObject(note);
        return note;
    }
}