package data;

import states.OgmoState;

import flixel.system.FlxSound;

import openfl.utils.Assets;

import haxe.Json;

class Content
{
    public static var credits:Map<User, CreditContent>;
    public static var artwork:Map<String, ArtCreation>;
    public static var artworkByDay:Map<Int, ArtCreation>;
    public static var songs:Map<String, SongCreation>;
    public static var songsOrdered:Array<SongCreation>;
    public static var arcades:Map<String, ArcadeCreation>;
    public static var instruments:Map<InstrumentType, InstrumentData>;
    public static var instrumentsByIndex:Map<Int, InstrumentData>;
    public static var events:Map<Int, SongCreation>;
    
    static var presentsById:Map<String, Int>;
    static var presentsByIndex:Map<Int, String>;
    
    public static function init(data:String)
    {
        var data:ContentFile = Json.parse(data);
        
        credits = [];
        for (user in Reflect.fields(data.credits))
        {
            var data:CreditContent = Reflect.field(data.credits, user);
            credits.set(user, data);
            data.newgrounds = 'http://$user.newgrounds.com';
        }
        
        songs = [];
        songsOrdered = [];
        for (songData in data.songs)
        {
            songData.path = 'assets/music/${songData.id}.mp3';
            songData.samplePath = 'assets/sounds/samples/${songData.id}.mp3';
            if (songData.volume == null)
                songData.volume = 0.5;
            songs[songData.id] = songData;
            songsOrdered.push(songData);
        }
        
        songsOrdered.sort((a, b)->a.day - b.day);
        for (i=>song in songsOrdered)
            song.index = i;
        
        arcades = [];
        for (arcadeData in data.arcades)
        {
            arcadeData.path = 'assets/images/props/cabinets/${arcadeData.id}.png';
            arcadeData.medalPath = 'assets/images/medals/${arcadeData.id}.png';
            if (arcadeData.scoreboard == null)
                arcadeData.scoreboard = arcadeData.name;
            arcades[arcadeData.id] = arcadeData;
        }
        
        artwork = [];
        artworkByDay = [];
        presentsById = [];
        presentsByIndex = [];
        for (i=>artData in data.artwork)
        {
            artwork[artData.id] = artData;
            if (artData.day != null)
                artworkByDay[artData.day] = artData;
            
            artData.path = 'assets/artwork/' + artData.id + "." + (artData.ext == null ? 'png' : artData.ext);
            artData.thumbPath = 'assets/images/thumbs/${artData.id}.png';
            artData.presentPath = 'assets/images/props/presents/${artData.id}.png';
            artData.medalPath = 'assets/images/medals/${artData.id}.png';
            artData.preload = artData.preload == true;
            presentsById[artData.id] = i;
            presentsByIndex[i] = artData.id;
        }
        
        instruments = [];
        instrumentsByIndex = [];
        for (index=>instrument in data.instruments)
        {
            instrument.index = index;
            if (instrument.icon == null)
                instrument.icon = instrument.id;
            instrument.iconPath = 'assets/images/props/instruments/${instrument.id}.png';
            instruments[instrument.id] = instrument;
            instrumentsByIndex[index] = instrument;
            instrument.singleNote = instrument.singleNote == null ? false: instrument.singleNote;
            instrument.sustain = instrument.sustain == null ? false: instrument.sustain;
            if (instrument.keys != null)
            {
                final keyOrder = "E4R5TY7U8I9OP";
                instrument.mapping = [];
                instrument.mapping.resize(keyOrder.length);
                for (key in Reflect.fields(instrument.keys))
                    instrument.mapping[keyOrder.indexOf(key)] = Reflect.field(instrument.keys, key);
            }
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
    
    /**
     * finds missing files or data and lets
     * @return String
     */
    public static function verifyTodaysContent():Array<ContentError>
    {
        var errors = new Array<ContentError>();
        
        var presentIds = getEntityIds("entrance", "Present");
        var daysFound = new Array();
        for (art in artwork)
        {
            if (art.day != null && art.day <= Calendar.day)
            {
                if (daysFound.contains(art.day))
                    errors.push('Multiple artwork with medals of day:${art.day}');
                else if (art.medal)
                    daysFound.push(art.day);
                
                if (!Manifest.exists(art.path, IMAGE))
                    errors.push('Missing ${art.path}');
                if (!Manifest.exists(art.thumbPath, IMAGE))
                    errors.push('Missing ${art.thumbPath}');
                if (!Manifest.exists(art.presentPath, IMAGE))
                    errors.push('Missing ${art.presentPath}');
                if (!Manifest.exists(art.medalPath, IMAGE))
                    errors.push('Missing ${art.medalPath}');
                if (!presentIds.contains(art.id))
                    errors.push('Missing present in entrance, id:${art.id}');
                if (art.authors == null)
                    errors.push('Missing artwork authors id:${art.id}');
                for (author in art.authors)
                {
                    if (!credits.exists(author) || credits[author].proper == null)
                        errors.push('Missing credits author:$author');
                }
            }
        }
        
        if (daysFound.length != Calendar.day)
        {
            daysFound.sort((a,b)->a-b);
            for (i in 0...Calendar.day)
            {
                if (i >= daysFound.length || daysFound[i] != i + 1)
                    errors.push('Missing art on day:${i + 1}');
            }
        }
        
        for (song in songs)
        {
            if (song.day != null && song.day <= Calendar.day)
            {
                if (!Manifest.exists(song.path, MUSIC))
                    errors.push('Missing ${song.path}');
                if (!Manifest.exists(song.samplePath, MUSIC))
                    errors.push('Missing ${song.samplePath}');
                if (song.authors == null)
                    errors.push('Missing song authors id:${song.id}');
                for (author in song.authors)
                {
                    if (!credits.exists(author) || credits[author].proper == null)
                        errors.push('Missing credits author:$author');
                }
            }
        }
        
        var cabinetIds = getEntityIds("arcade", "Cabinet");
        var teleportIds = getEntityIds("arcade", "Teleport");
        for (arcade in arcades)
        {
            if (arcade.day != null && arcade.day <= Calendar.day)
            {
                if (!Manifest.exists(arcade.path, IMAGE))
                    errors.push('Missing ${arcade.path}');
                if (arcade.type != External && !Manifest.exists(arcade.medalPath, IMAGE))
                    errors.push('Missing ${arcade.medalPath}');
                if (!cabinetIds.contains(arcade.id))
                    errors.push('Missing Cabinet in arcade id:${arcade.id}');
                if (arcade.type == State && !teleportIds.contains(arcade.id))
                    errors.push('Missing Teleport in arcade id:${arcade.id}');
                // if (arcade.authors == null)
                //     errors.push('Missing arcade authors id:${arcade.id}');
                if (arcade.authors != null)
                {
                    for (author in arcade.authors)
                    {
                        if (!credits.exists(author) || credits[author].proper == null)
                            errors.push('Missing credits author:$author');
                    }
                }
            }
        }
        
        return errors.length == 0 ? null : errors;
    }
    
    static function getEntityIds(room:String, entityName:String)
    {
        final list = new Array<String>();
        var day = Calendar.day;
        
        var levelPath = 'assets/data/ogmo/$room$day.json';
        while(day-- > 0 && !Manifest.exists(levelPath))
            levelPath = 'assets/data/ogmo/$room$day.json';
        
        if (day <= 0)
            return list;
        
        var levelString = openfl.Assets.getText(levelPath).split("\\\\").join("/");
        var level:OgmoLevelData = Json.parse(levelString);
        for (layerData in level.layers)
        {
            if (Reflect.hasField(layerData, "entities"))
            {
                for (entityData in (cast layerData:OgmoEntityLayerData).entities)
                {
                    if (entityData.name == entityName)
                        list.push(entityData.values.id);
                }
            }
        }
        
        return list;
    }
    
    static public function listAuthorsProper(authors:Array<String>)
    {
        if (authors.length == 1)
            return Content.credits[authors[0]].proper;
        else
        {
            final authorNames:Array<String> = [];
            for (author in authors)
                authorNames.push(Content.credits[author].proper);
            
            final text = " and " + authorNames.pop();
            return authorNames.join(", ") + text;
        }
    }
    
    public static function isArtUnlocked(id:String)
    {
        return artwork.exists(id) && artwork[id].day <= Calendar.day;
    }
    
    inline public static function playTodaysSong(forceRestart = false)
    {
        Manifest.playMusic(getTodaysSong().id, forceRestart);
    }
    
    inline public static function playSongByDay(day:Int)
    {
        Manifest.playMusic(getSongByDay(day).id);
    }
    
    inline public static function getTodaysSong()
    {
        return getSongByDay(Calendar.day);
    }
    
    public static function getSongByDay(day:Int)
    {
        var latestSong:SongCreation = null;
        for (song in songs)
        {
            if (song.day <= day && (latestSong == null || song.day > latestSong.day))
                latestSong = song;
        }
        
        if (latestSong == null)
            throw "No song for day:" + day;
        
        return latestSong;
    }
    
    static public function isContributor(name:String)
    {
        return credits.exists(name.toLowerCase());
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

private typedef ContentFile =
{
    var artwork:Array<ArtCreation>;
    var songs:Array<SongCreation>;
    var instruments:Array<InstrumentData>;
    var arcades:Array<ArcadeCreation>;
    var credits:Dynamic;
    var events:Dynamic;
}

typedef ContentError = String;

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
    var ext:String;
}

typedef ArtCreation
 = Creation & 
{
    var animation:Null<{frames:Int, fps:Int}>;
    var thumbPath:String;
    var presentPath:String;
    var medalPath:String;
    var antiAlias:Null<Bool>;
    var medal:Null<Bool>;
    var preload:Bool;
}

typedef SongCreation
= Creation &
{
    var samplePath:String;
    var loopStart:Null<Int>;
    var loopEnd:Null<Int>;
    var key:String;
    var bpm:Float;
    var ngId:Int;
    var volume:Float;
    var index:Int;
}

typedef ArcadeCreation
= Creation &
{
    var ngId:Int;
    var scoreboard:String;
    var scoreboardId:Int;
    var medalPath:String;
    var mobile:Bool;
    var type:ArcadeType;
}

enum abstract ArcadeName(String) to String
{
    var Digging = "digging";
    var Horse = "horse";
    var Advent2018 = "2018";
    var Advent2019 = "2019";
}

enum abstract ArcadeType(String) to String
{
    var State    = "state";
    var Overlay  = "overlay";
    var External = "external";
}

typedef InstrumentData =
{
    var id:InstrumentType;
    var index:Int;
    var name:String;
    var icon:String;
    var iconPath:String;
    var day:Int;
    var keys:Dynamic;
    var mapping:Array<String>;
    var singleNote:Bool;
    var sustain:Bool;
    var volume:Float;
    var octave:Int;
}

enum abstract InstrumentType(String) to String
{
    var Acoustic = "guitar_ac";
    var Piano = "piano";
    var Glock = "glockenspiel";
    var Flute = "flute";
    var Drums = "drums";
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
    var mintyeggs;
    var danfrombavaria;
    var mixmuffin;
    var einmeister;
    var splatterdash;
}