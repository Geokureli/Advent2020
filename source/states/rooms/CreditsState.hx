package states.rooms;

import data.Content;
import props.Teleport;
import flixel.FlxG;
import flixel.FlxSprite;

class CreditsState extends RoomState
{
    var credits:Map<String, CreditContent>;
    
    override function initEntities()
    {
        super.initEntities();
        
        parseCredits();
        
        var floor = background.getByName("credits");
        floor.setBottomHeight(floor.frameHeight);
        var candle = background.getByName("candle");
        candle.setBottomHeight(candle.frameHeight);
        var portrait = background.getByName("portrait");
        portrait.setBottomHeight(portrait.frameHeight);
        var prevFloor = floor;
        function addSection()
        {
            var newFloor = new FlxSprite(prevFloor.x + prevFloor.width, prevFloor.y);
            newFloor.loadGraphicFromSprite(prevFloor);
            background.add(newFloor);
            var newCandle = new FlxSprite(candle.x - floor.x + newFloor.x, candle.y - floor.y + newFloor.y);
            newCandle.loadGraphicFromSprite(candle);
            background.add(newCandle);
            var newPortrait = new FlxSprite(portrait.x - floor.x + newFloor.x, portrait.y - floor.y + newFloor.y);
            newPortrait.loadGraphicFromSprite(portrait);
            background.add(newPortrait);
            prevFloor = newFloor;
        }
        
        for (i in 0...4)
            addSection();
        
        FlxG.worldBounds.right = prevFloor.x + prevFloor.width;
        FlxG.camera.maxScrollX = FlxG.worldBounds.right;
        
        var exitTeleport:Teleport = null;
        for (teleport in teleports.members)
        {
            if ("outside" == teleport.id)
            {
                exitTeleport = teleport;
                break;
            }
        }
        
        if (exitTeleport == null)
            throw "missing teleport";
        
        exitTeleport.x = prevFloor.x + prevFloor.width - exitTeleport.width;
    }
    
    function parseCredits()
    {
        var fullCredits = new Map<User, CreditContent>();
        
        for (user=>data in Content.credits)
        {
            var copy:CreditContent = {};
            for (field in Reflect.fields(data))
                copy[field] = Reflect.field(data, "field");
            fullCredits[user] = data;
        }
        
        function addRole(user:User, ownerRole:String, contentName:String)
        {
            var role = ownerRole;
            if (user.indexOf(":")
            {
                var split = user.split(":");
                user = split[0];
                role = split[1];
            }
            
            fullCredits[user].roles.push('$role: $contentName');
        }
        
        for (data in Content.artwork)
        {
            var contentName = data.name == null ? "UNTITLED" : data.name;
            for (author in data.authors)
                addRole(author, "Artist", contentName);
        }
        
        for (data in Content.songs)
        {
            var contentName = data.name == null ? "UNTITLED" : data.name;
            for (author in data.authors)
                addRole(author, "Musician", contentName);
        }
    }
}