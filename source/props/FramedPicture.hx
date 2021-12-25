package props;

import data.Content;
import data.NGio;
import data.Save;
import states.OgmoState;

import flixel.FlxSprite;

typedef FramedPictureValues = { id:String }

class FramedPicture extends flixel.FlxSprite
{
    public final id:String;
    public var contents:FlxSprite;
    
    public function new (id:String, x = 0.0, y = 0.0)
    {
        this.id = id;
        super(x, y);
        var path = 'assets/images/framed/${id}.png';
        if (!data.Manifest.exists(path, IMAGE))
            path = 'assets/images/thumbs/debug.png';
        
        // We made day 1 unlock on any advent day, so close up their present if they didn't get it.
        // if (NGio.isLoggedIn)
        //     opened = NGio.hasDayMedal(Content.getPresentIndex(id));
        
        loadGraphic(path);
        //graphic.bitmap.fillRect(new openfl.geom.Rectangle(32, 0, 32, 2), 0x0);
        
        //width = frameWidth / 2;
        //(this:OgmoDecal).setBottomHeight(this.frameHeight >> 2);
    }
    
    public function animateOpen(callback:()->Void)
    {
        callback();
    }
    
    static public function fromEntity(data:OgmoEntityData<FramedPictureValues>)
    {
        var framedPicture = new FramedPicture(data.values.id, data.x, data.y);
        return framedPicture;
    }
}

