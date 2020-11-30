package data;

import flixel.FlxG;
import flixel.system.FlxSound;

import openfl.display.BitmapData;
import openfl.utils.Assets;
import openfl.utils.AssetType;

import lime.utils.AssetManifest;

class Manifest
{
    static public var noPreload:AssetManifest = null;
    
    static public var songs = new Map<String, FlxSound>();
    static var loadingSongs = new Map<String, (FlxSound)->Void>();
    
    static public var art = new Map<String, BitmapData>();
    static var loadingArt = new Map<String, (BitmapData)->Void>();
    
    static public function init(onComplete:()->Void):Void
    {
        final manifestHttp = new haxe.Http("manifest/noPreload.json");
        manifestHttp.onError = function (msg) throw msg;
        manifestHttp.onData = function (data)
        {
            noPreload = AssetManifest.parse(data, "./");
            onComplete();
        }
        manifestHttp.request();
    }
    
    static public function exists(id:String, ?type:AssetType):Bool
    {
        if (Assets.exists(id, type))
            return true;
        
        if (noPreload != null)
        {
            for (asset in (cast noPreload.assets:Array<AssetData>))
            {
                if (asset.id == id && (type == null || type == asset.type))
                    return true;
            }
        }
        
        return false;
    }
    
    static public function loadArt(id:String, onLoad:(BitmapData)->Void):Void
    {
        if (art.exists(id))
            onLoad(art[id]);
        #if !(PRELOAD_ALL)
        else if (loadingArt.exists(id))
        {
            if (onLoad != null)
            {
                var oldOnLoad = loadingArt[id];
                loadingArt[id] = function(bitmap)
                {
                    onLoad(bitmap);
                    oldOnLoad(bitmap);
                }
            }
        }
        #end
        
        if (Content.artwork.exists(id) == false)
            throw 'Invalid song id: $id';
        var data = Content.songs[id];
        
        #if PRELOAD_ALL
        return Assets.getBitmapData("noPreload:" + data.path);
        #else
        var loader = BitmapData.loadFromFile(data.path);
        loadingArt[id] = onLoad;
        onLoad = function(bmd)
        {
            art[id] = bmd;
            var graphic = FlxG.bitmap.add(bmd, true, id);
            graphic.destroyOnNoUse = false;
            loadingArt[id](bmd);
        }
        loader.onComplete(onLoad);
        #end
    }
    
    static public function loadSong(id:String, looped = true, ?onComplete:()->Void, ?onLoad:(FlxSound)->Void):FlxSound
    {
        if (songs.exists(id))
        {
            final song = songs[id];
            if (onLoad != null && loadingSongs.exists(id))
            {
                if (loadingSongs[id] == null)
                    loadingSongs[id] = onLoad;
                else
                {
                    var oldOnLoad = loadingSongs[id];
                    loadingSongs[id] = function(sound)
                    {
                        onLoad(sound);
                        oldOnLoad(sound);
                    }
                }
            }
            
            if(song.onComplete != null)
                FlxG.log.warn("overriding onComplete of " + id);
            song.onComplete = onComplete;
            return song;
        }
        
        if (Content.songs.exists(id) == false)
            throw 'Invalid song id: $id';
        var data = Content.songs[id];
        
        final song = new PeristentSound();
        songs[id] = song;
        #if PRELOAD_ALL
        song.loadEmbedded("noPreload:" + data.path, looped, false, onComplete);
        if (onLoad != null)
            onLoad(song);
        #else
        function loadFunc()
        {
            var callback = loadingSongs[id];
            loadingSongs.remove(id);
            if (callback != null)
                callback(song);
        }
        loadingSongs[id] = onLoad;
        song.loadStream(data.path, looped, false, onComplete, loadFunc);
        #end
        
        if (data.loopStart != null)
            song.loopTime = data.loopStart;
        
        if (data.loopEnd != null)
            song.endTime = data.loopEnd;
        
        return song;
    }
    
    static public function playMusic(id, volume = 1.0, ?onComplete, ?onLoad:(FlxSound)->Void)
    {
        var loaded = false;
        #if PRELOAD_ALL
        loaded = true;
        var loadFunc = onLoad;
        #else
        function loadFunc(song)
        {
            if (song == FlxG.sound.music)
                song.play();
            
            if (onLoad != null)
                onLoad(song);
            
            loaded = true;
        }
        #end
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        
        final song = loadSong(id, true, onComplete, loadFunc);
        song.volume = volume;
        
        FlxG.sound.music = song;
        if (loaded)
            song.play();
        
        return song;
    }
}

class ArtSprite extends flixel.FlxSprite
{
    public function new(id:String, x = 0.0, y = 0.0)
    {
        super(x, y);
        
        makeGraphic(1, 1, 0x0);
        Manifest.loadArt(id, (_)->loadGraphic(id));
    }
}

class PeristentSound extends FlxSound
{
    override function reset()
    {
		// destroy();

		x = 0;
		y = 0;

		_time = 0;
		_paused = false;
		_volume = 1.0;
		_volumeAdjust = 1.0;
		looped = false;
		loopTime = 0.0;
		endTime = 0.0;
		_target = null;
		_radius = 0;
		_proximityPan = false;
		visible = false;
		amplitude = 0;
		amplitudeLeft = 0;
		amplitudeRight = 0;
		autoDestroy = false;

		if (_transform == null)
			_transform = new openfl.media.SoundTransform();
		_transform.pan = 0;
    }
    
    override function destroy()
    {
        throw "Can not destroy a PersistentSound";
    }
}

private typedef AssetData =
{
    path:String,
    size:Int,
    type:AssetType,
    id:String,
    preload:Bool
};
