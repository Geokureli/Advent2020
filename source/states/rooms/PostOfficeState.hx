package states.rooms;

import states.OgmoState;
import flixel.FlxSprite;

import flixel.text.FlxBitmapText;

import props.Note;

class PostOfficeState extends RoomState
{
    var mail:FlxSprite;
    var nameText = new FlxBitmapText();

    var note:Note;

    override function create()
    {
        entityTypes["MaleMailMan"] = cast initMaleMailMan;

        entityTypes["Note"] = cast function(data)
        {
            note = Note.fromEntity(data);
            return note;
        }
        
        super.create();
    }

    function initMaleMailMan(data:OgmoEntityData<Dynamic>)
    {
        mail = OgmoEntityData.createFlxSprite(data);
        mail.loadGraphic("assets/images/player/mindchamber.png");
        mail.scale.scale(2);
        
        return mail;
    }
    
    override function initEntities() { 
        super.initEntities();

        foreground.remove(note);
        topGround.add(note);

        //foreground.add(mail);

        nameText.text = "MindChamber";
        nameText.alignment = CENTER;
        nameText.color = 0xFFffffff;
        nameText.borderColor = 0xFF000000;
        nameText.borderStyle = SHADOW;

        nameText.x = mail.x + (mail.width - nameText.width) / 2;
        nameText.y = mail.y + mail.height - mail.frameHeight - nameText.height - 4;

        topGround.add(nameText);
    }

    // override function update(elapsed:Float) { super.update(elapsed); }
}
