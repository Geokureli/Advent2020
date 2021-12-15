package states.rooms;

import states.OgmoState;
import flixel.FlxSprite;

import flixel.text.FlxBitmapText;

import props.Note;

class PostOfficeState extends RoomState
{
    var mail:FlxSprite;
    var mindchamberText = new FlxBitmapText();

    var robot:FlxSprite;
    var pbotText = new FlxBitmapText();

    var note:Note;

    override function create()
    {
        entityTypes["MaleMailMan"] = cast initMaleMailMan;
        entityTypes["PBot"] = cast initPBot;

        entityTypes["Note"] = cast function(data)
        {
            note = Note.fromEntity(data);
            note.visible = false;
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
    
    function initPBot(data:OgmoEntityData<Dynamic>)
    {
        robot = OgmoEntityData.createFlxSprite(data);
        robot.loadGraphic("assets/images/player/pbot.png");
        robot.scale.set(-2, 2);
        robot.height *= 2.5;

        addHoverTextTo(robot, "LETTER", () -> note.visible = !note.visible);
            
        return robot;
    }

    override function initEntities() { 
        super.initEntities();

        foreground.remove(note);
        topGround.add(note);

        //foreground.add(mail);

        mindchamberText.text = "MindChamber";
        mindchamberText.alignment = CENTER;
        mindchamberText.color = 0xFFffffff;
        mindchamberText.borderColor = 0xFF000000;
        mindchamberText.borderStyle = SHADOW;

        mindchamberText.x = mail.x + (mail.width - mindchamberText.width) / 2;
        mindchamberText.y = mail.y + mail.height - mail.frameHeight - mindchamberText.height - 4;

        topGround.add(mindchamberText);

        pbotText.text = "P-Bot";
        pbotText.alignment = CENTER;
        pbotText.color = 0xFFffffff;
        pbotText.borderColor = 0xFF000000;
        pbotText.borderStyle = SHADOW;

        pbotText.x = robot.x + (robot.width - pbotText.width) / 2;
        pbotText.y = robot.y + robot.height - robot.frameHeight - pbotText.height - 8;

        topGround.add(pbotText);
    }

    // override function update(elapsed:Float) { super.update(elapsed); }
}
