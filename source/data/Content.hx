package data;

import openfl.utils.Assets;
import flixel.system.FlxSound;
import haxe.Json;

class Content
{
    static public var credits:Map<User, CreditContent>;
    static public var artwork:Map<String, ArtCreation>;
    static public var songs:Map<String, SongCreation>;
    static public var days:Array<DayContent>;
    
    static public function init(data:String)
    {
        var data:Dynamic = Json.parse(data);
        
        credits = [];
        for (user in Reflect.fields(data.credits))
            credits.set(user, Reflect.field(data.credits, user));
        
        songs = [];
        for (songData in (data.songs:Array<SongCreation>))
            songs[songData.id] = songData;
        
        artwork = [];
        for (artData in (data.artwork:Array<ArtCreation>))
            artwork[artData.id] = artData;
        
        days = data.days;
    }
}

typedef CreditContent =
{
    var proper:String;
    var roles:Array<String>;
    var soundcloud:String;
    var bandcamp:String;
}

typedef Creation = 
{
    var id:String;
    var name:Null<String>;
    var authors:Array<User>;
    var path:String;
}

typedef ArtCreation
 = Creation & 
{
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

typedef DayContent = 
{
    var song:Int;
    var art:Int;
}

enum abstract User(String) from String to String
{
    var geokureli;
    var brandybuizel;
    var nickconter;
    var albegian;
    var cymbourine;
}