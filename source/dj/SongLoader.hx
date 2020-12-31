package dj;

import haxe.Json;
import haxe.Http;

import openfl.events.IOErrorEvent;
import openfl.net.URLRequest;

import flixel.system.FlxSound;

class SongLoader
{
    inline static var URL_FORMAT = "https://www.newgrounds.com/audio/feed/";
    
    public static function checkCode(id:String, ?callback:(InfoResponse)->Void)
    {
        if (callback == null)
            callback = (_)->{};
        
        final url = URL_FORMAT + id;
        trace('checking feed: $url');
        var http = new Http(url);
        http.onError = (msg )->callback(Fail(ScrapeError(msg)));
        http.onData  = (data)->callback(parseFeedData(data));
        http.request(true);
    }
    
    public static function loadSongFromData(data:SongFeed, ?callback:(LoadResponse)->Void)
    {
        trace('loading song: ${data.stream_url}');
        var sound = new FlxSound();
        loadStream(sound, data, callback);
    }
    
    public static function loadSong(id:String, ?callback:(LoadResponse)->Void):FlxSound
    {
        final url = URL_FORMAT + id;
        trace('loading song: $url');
        var sound = new FlxSound();
        checkCode(id, function(response)
            {
                switch (response)
                {
                    case Fail(error): callback(Fail(error));
                    case Success(data): loadStream(sound, data, callback);
                }
            }
        );
        return sound;
    }
    
    static function parseFeedData(dataStr:String):InfoResponse
    {
        var data = Json.parse(dataStr);
        
        if (data.allow_external_api == false)
            return Fail(ApiNotAllowed);
        
        if (data.stream_url == null)
            return Fail(InvalidFeedInfo);
        
        if (getOwner(data.authors) == null)
            return Fail(InvalidFeedInfo);
        
        return Success(data);
    }
    
    static function loadStream(sound:FlxSound, data:SongFeed, callback:(LoadResponse)->Void)
    {
        sound.loadStream(data.stream_url, true, true, null, callback.bind(Success(sound)));
        @:privateAccess
        sound._sound.addEventListener(IOErrorEvent.IO_ERROR, (e)->callback(Fail(IoError(e))));
    }
    
    static public function getOwner(authors:Array<Author>)
    {
        for (author in authors)
            if (author.owner == 1)
                return author;
        
        return null;
    }
}

enum InfoResponse
{
    Fail(type:FailureType);
    Success(data:SongFeed);
}

enum LoadResponse
{
    Fail(type:FailureType);
    Success(sound:FlxSound);
}

enum FailureType
{
    ScrapeError(msg:String);
    ApiNotAllowed;
    InvalidFeedInfo;
    IoError(event:IOErrorEvent);
}

typedef SongFeed =
{ 
    var id:Int;
    var title:String;
    var url:String;
    var download_url:String;
    var stream_url:String;
    var filesize:Int;
    var icons:Icons;
    var authors:Array<Author>;
    var has_scouts:Bool;
    var unpublished:Bool;
    var allow_downloads:Bool;
    var has_valid_portal_member:Bool;
    var allow_external_api:Bool;
}

typedef Author =
{
    var id:Int;
    var name:String;
    var url:String;
    var icons:Icons;
    var owner:Int;
    var manager:Int;
    var is_scout:Bool;
}

private typedef Icons = { small:String, medium:String, large:String }