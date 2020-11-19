package dj;

import haxe.Json;
import haxe.Http;

import openfl.events.IOErrorEvent;
import openfl.net.URLRequest;

import flixel.system.FlxSound;

class SongLoader
{
    inline static var URL_FORMAT = "https://www.newgrounds.com/audio/feed/";
    
    public static function loadSong(id:String, ?callback:(LoadResponse)->Void):FlxSound
    {
        if (callback == null)
            callback = (_)->{};
        
        final url = URL_FORMAT + id;
        trace('loading song: $url');
        var http = new Http(url);
        var sound = new FlxSound();
        http.onError = (msg )->callback(Fail(ScrapeError(msg)));
        http.onData  = (data)->onSongFeedLoad(sound, data, callback);
        http.request(true);
        return sound;
    }
    
    static function onSongFeedLoad(sound:FlxSound, dataStr:String, callback:(LoadResponse)->Void)
    {
        var data = Json.parse(dataStr);
        if (data.allow_external_api == false)
            callback(Fail(ApiNotAllowed));
        else if (data.stream_url == null)
            callback(Fail(MissingStreamUrl));
        else
            loadStream(sound, data.stream_url, callback);
    }
    
    static function loadStream(sound:FlxSound, url:String, callback:(LoadResponse)->Void)
    {
        sound.loadStream(url, true, true, null, callback.bind(Success(sound)));
        @:privateAccess
        sound._sound.addEventListener(IOErrorEvent.IO_ERROR, (e)->callback(Fail(IoError(e))));
    }
}

enum LoadResponse
{
    Fail(type:FailureType);
    Success(sound:FlxSound);
}

enum FailureType
{
    ScrapeError(msg:String);
    StreamError(msg:String);
    ApiNotAllowed;
    MissingStreamUrl;
    IoError(event:IOErrorEvent);
}