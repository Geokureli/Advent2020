package states.rooms;

import states.OgmoState;
import flixel.FlxSprite;

import flixel.text.FlxBitmapText;

class PostOfficeState extends RoomState
{
    var mail:FlxSprite;
    var nameText = new FlxBitmapText();

    override function create()
    {
        entityTypes["MaleMailMan"] = cast initMaleMailMan;
        
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

        foreground.add(mail);

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
