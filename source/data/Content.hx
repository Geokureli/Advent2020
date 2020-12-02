package data;

import flixel.system.FlxSound;

import openfl.utils.Assets;

import haxe.Json;

class Content
{
    public static var credits:Map<User, CreditContent>;
    public static var artwork:Map<String, ArtCreation>;
    public static var songs:Map<String, SongCreation>;
    public static var events:Map<Int, SongCreation>;
    
    static var presentsById:Map<String, Int>;
    static var presentsByIndex:Map<Int, String>;
    
    public static function init(data:String)
    {
        var data:Dynamic = Json.parse(data);
        
        credits = [];
        for (user in Reflect.fields(data.credits))
        {
            var data:CreditContent = Reflect.field(data.credits, user);
            credits.set(user, data);
            data.newgrounds = 'http://$user.newgrounds.com';
        }
        
        songs = [];
        for (songData in (data.songs:Array<SongCreation>))
        {
            songData.path = 'assets/music/${songData.id}.mp3';
            songs[songData.id] = songData;
        }
        
        artwork = [];
        presentsById = [];
        presentsByIndex = [];
        for (i=>artData in (data.artwork:Array<ArtCreation>))
        {
            artwork[artData.id] = artData;
            artData.path = 'assets/artwork/${artData.id}.png';
            artData.thumbPath = 'assets/images/thumbs/${artData.id}.png';
            presentsById[artData.id] = i;
            presentsByIndex[i] = artData.id;
        }
        
        events = [];
        for (eventKey in Reflect.fields(data.events))
        {
            var day = Std.parseInt(eventKey);
            if (Std.string(day) != eventKey)
                throw "Invalid event day:" + eventKey;
            
            var event = Reflect.field(data.events, eventKey);
            event.day = day;
            events[day] = event;
        }
    }
    
    public static function isArtUnlocked(id:String)
    {
        return artwork.exists(id) && artwork[id].day <= Calendar.day;
    }
    
    @:allow(data.Save)
    static function getPresentIndex(id:String)
    {
        if (id != null && presentsById.exists(id))
            return presentsById[id];
        return -1;
    }
    
    @:allow(data.Save)
    static function getPresentId(index:Int) return presentsByIndex[index];
}

typedef CreditContent =
{
    var proper:String;
    var roles:Array<String>;
    var soundcloud:String;
    var bandcamp:String;
    var newgrounds:String;
}

typedef Creation = 
{
    var id:String;
    var name:Null<String>;
    var authors:Array<User>;
    var path:String;
    var day:Int;
}

typedef ArtCreation
 = Creation & 
{
    var animation:Null<{frames:Int, fps:Int}>;
    var thumbPath:String;
    var antiAlias:Null<Bool>;
    var medal:Null<Bool>;
}

typedef SongCreation
= Creation &
{
    var loopStart:Null<Int>;
    var loopEnd:Null<Int>;
    var key:String;
    var bpm:Float;
    var ngId:Int;
}

typedef EventContent = 
{
    var id:String;
    var day:Int;
    var saveState:Bool;
}

enum abstract User(String) from String to String
{
    var geokureli;
    var brandybuizel;
    var nickconter;
    var albegian;
    var cymbourine;
}