package data;

import flixel.FlxG;
import states.OgmoState;

import flixel.system.FlxSound;
import flixel.util.FlxSignal;

import openfl.utils.Assets;

import haxe.Json;

class Content
{
    public static var onInit(default, null) = new FlxSignal();
    public static var isInitted(default, null) = false;
    
    public static var credits:Map<User, CreditContent>;
    public static var creditsOrdered:Array<CreditContent>;
    public static var extras:Map<User, CreditContent>;
    public static var artwork:Map<String, ArtCreation>;
    public static var artworkByDay:Map<Int, ArtCreation>;
    public static var songs:Map<String, SongCreation>;
    public static var songsOrdered:Array<SongCreation>;
    public static var arcades:Map<String, ArcadeCreation>;
    public static var instruments:Map<InstrumentType, InstrumentData>;
    public static var instrumentsByIndex:Map<Int, InstrumentData>;
    public static var events:Map<Int, SongCreation>;
    public static var medals:Map<String, Int>;
    public static var medalsById:Map<Int, String>;
    public static var movies:Map<String, MovieCreation>;
    
    static var presentsById:Map<String, Int>;
    static var presentsByIndex:Map<Int, String>;
    
    public static function init(data:String)
    {
        var data:ContentFile = Json.parse(data);
        
        credits = [];
        for (user in Reflect.fields(data.credits))
        {
            var data:CreditContent = Reflect.field(data.credits, user);
            data.id = user;
            if (data.roles == null)
                data.roles = [];
            credits.set(user, data);
            data.portraitPath = 'assets/images/portraits/$user.png';
        }
        
        extras = [];
        for (user in Reflect.fields(data.extras))
        {
            var data:CreditContent = Reflect.field(data.extras, user);
            data.id = user;
            data.roles = [];
            extras.set(user, data);
            data.portraitPath = 'assets/images/portraits/$user.png';
        }
        
        songs = [];
        songsOrdered = [];
        for (songData in data.songs)
        {
            songData.path = 'assets/music/${songData.id}.mp3';
            songData.samplePath = 'assets/sounds/samples/${songData.id}.mp3';
            songData.sideDiskPath = 'assets/images/ui/carousel/disks/side_${songData.id}.png';
            songData.frontDiskPath = 'assets/images/ui/carousel/disks/front_${songData.id}.png';
            if (songData.volume == null)
                songData.volume = 1.0;
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
            if (arcadeData.medal == null)
                arcadeData.medal = arcadeData.type != External;
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
            instrument.iconPath = 'assets/images/props/instruments/${instrument.icon}.png';
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
        
        medals = [];
        medalsById = [];
        for (name in Reflect.fields(data.medals))
        {
            var id = Reflect.field(data.medals, name);
            medals[name] = id;
            medalsById[id] = name;
        }
        
        movies = [];
        for (id in Reflect.fields(data.movies))
        {
            movies[id] = cast Reflect.field(data.movies, id);
            movies[id].id = id;
        }
        
        parseCredits();
        
        isInitted = true;
        onInit.dispatch();
    }
    
    
    static function parseCredits()
    {
        creditsOrdered = [];
        for (data in credits)
        {
            data.firstDay = data.roles.indexOf(RoleType.pm) != -1 ? 0 : 32;
            for (i in 0...data.roles.length)
                data.roles[i] = parseRole(data.roles[i]);
            creditsOrdered.push(data);
        }
        
        for (data in artwork)
        {
            var contentName = data.name == null ? "Untitled Illustration" : data.name;
            for (author in data.authors)
                addRole(author, art, contentName, data.day);
        }
        
        for (data in songs)
        {
            var contentName = data.name == null ? "Untitled Song" : data.name;
            for (author in data.authors)
                addRole(author, music, contentName, data.day);
        }
        
        for (data in arcades)
        {
            var contentName = data.name == null ? "Untitled Minigame" : data.name;
            if (data.authors != null)
            {
                for (author in data.authors)
                    addRole(author, owner, contentName, data.day);
            }
        }
        
        for (data in movies)
        {
            var contentName = data.name == null ? "Untitled Movie" : data.name;
            for (author in data.authors)
                addRole(author, owner, contentName, data.day);
        }
        
        creditsOrdered.sort((a, b)->a.firstDay - b.firstDay);
    }
    
    static function getUserId(user:User)
    {
        if (user.indexOf(":") != -1)
            user = user.split(":")[0];
        return user;
    }
    
    static function creditsExists(user:User)
    {
        user = getUserId(user);
        
        var data:CreditContent = null;
        if (extras.exists(user))
            data = extras[user];
        else if (credits.exists(user))
            data = credits[user];
        
        return data != null && data.proper != null;
    }
    
    static function addRole(user:User, ownerRole:RoleType, contentName:String, day:Int)
    {
        var role:String;
        if (user.indexOf(":") != -1)
        {
            var split = user.split(":");
            user = split[0];
            role = parseRole(split[1]);
        }
        else
            role = parseRole(ownerRole);
        
        var data:CreditContent;
        if (extras.exists(user))
            data = extras[user];
        else if (credits.exists(user))
            data = credits[user];
        else
            throw "invalid user:" + user;
        
        data.roles.push('$role: $contentName');
        
        if (day < data.firstDay && day > 0)
            data.firstDay = day;
    }
    
    static function parseRole(type:RoleType)
    {
        var display = "";
        if (StringTools.startsWith(type, RoleType.adl_))
        {
            display += "Additional ";
            type = type.substring(4);
        }
        
        return display + switch(type)
        {
            case owner  : "Creator";
            case pm     : "Organizer";
            case code   : "Code";
            case design : "Design";
            case art    : "Art";
            case anim   : "Animation";
            case music  : "Music";
            case sound  : "Sound Effects";
            case bg     : "Background Art";
            case va     : "Voice Acting";
            case sprites: "Sprites";
            case disk   : "Disk Art";
            default: type;
        }
    }
    
    /**
     * finds missing files or data and lets
     * @return String
     */
    public static function verifyTodaysContent(includeWarnings:Bool):Array<ContentError>
    {
        var errors = new Array<ContentError>();
        
        function addError(msg:String)
        {
            errors.push(Blocking(msg));
        }
        function addWarning(msg:String)
        {
            if (includeWarnings)
                errors.push(Warning(msg));
        }
        
        var presentIds = getEntityIds("entrance", "Present");
        var daysFound = new Array();
        for (art in artwork)
        {
            if (art.day != null && art.day <= Calendar.day)
            {
                if (art.medal)
                {
                    if (!Manifest.exists(art.medalPath, IMAGE))
                        addError('Missing ${art.medalPath}');
                    
                    if (daysFound.contains(art.day))
                        addError('Multiple artwork with medals of day:${art.day}');
                    else
                        daysFound.push(art.day);
                    
                }
                if (art.comic == null)
                {
                    if (!Manifest.exists(art.path, IMAGE))
                        addError('Missing ${art.path}');
                    if (!Manifest.exists(art.thumbPath, IMAGE))
                        addError('Missing ${art.thumbPath}');
                }
                if (!Manifest.exists(art.presentPath, IMAGE))
                    addError('Missing ${art.presentPath}');
                if (!presentIds.contains(art.id))
                    addError('Missing present in entrance, id:${art.id}');
                if (art.authors == null)
                    addError('Missing artwork authors id:${art.id}');
                for (author in art.authors)
                {
                    author = getUserId(author);
                    if (!creditsExists(author))
                        addError('Missing credits, author:$author');
                    else if (!Manifest.exists(credits[author].portraitPath, IMAGE))
                        addWarning('Missing portrait, author:$author');
                }
            }
        }
        
        if (daysFound.length != Calendar.day)
        {
            daysFound.sort((a,b)->a-b);
            for (i in 0...Calendar.day)
            {
                if (i >= daysFound.length || daysFound[i] != i + 1)
                    addError('Missing art on day:${i + 1}');
            }
        }
        
        for (song in songs)
        {
            if (song.day != null && song.day <= Calendar.day || song.day > 32)
            {
                if (!Manifest.exists(song.path, MUSIC))
                    addError('Missing ${song.path}');
                if (!Manifest.exists(song.samplePath, MUSIC))
                    addError('Missing ${song.samplePath}');
                if (!Manifest.exists(song.sideDiskPath, IMAGE))
                    addWarning('Missing ${song.sideDiskPath}');
                if (!Manifest.exists(song.frontDiskPath, IMAGE))
                    addWarning('Missing ${song.frontDiskPath}');
                if (song.authors == null)
                    addError('Missing song authors id:${song.id}');
                for (author in song.authors)
                {
                    author = getUserId(author);
                    if (!creditsExists(author))
                        addError('Missing credits, author:$author');
                    else if (!Manifest.exists(credits[author].portraitPath, IMAGE))
                        addWarning('Missing portrait, author:$author');
                }
            }
        }
        
        var cabinetIds = getEntityIds("arcade", "Cabinet");
        var teleportIds = getEntityIds("arcade", "Teleport");
        for (arcade in arcades)
        {
            if (arcade.day != null && arcade.day <= Calendar.day)
            {
                if (arcade.cabinet != false)
                {
                    if (!Manifest.exists(arcade.path, IMAGE))
                        addError('Missing ${arcade.path}');
                    if (!cabinetIds.contains(arcade.id))
                        addError('Missing Cabinet in arcade id:${arcade.id}');
                    if (arcade.type == State && !teleportIds.contains(arcade.id))
                        addError('Missing Teleport in arcade id:${arcade.id}');
                }
                if (arcade.type != External && arcade.medal && !Manifest.exists(arcade.medalPath, IMAGE))
                    addError('Missing ${arcade.medalPath}');
                // if (arcade.authors == null)
                //     errors.push('Missing arcade authors id:${arcade.id}');
                if (arcade.authors != null)
                {
                    for (author in arcade.authors)
                    {
                        author = getUserId(author);
                        if (!creditsExists(author))
                            addError('Missing credits, author:$author');
                        else if (!Manifest.exists(credits[author].portraitPath, IMAGE))
                            addWarning('Missing portrait, author:$author');
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
    var extras:Dynamic;
    var events:Dynamic;
    var medals:Dynamic;
    var comics:Dynamic;
    var movies:Dynamic;
}

enum ContentError
{
    Blocking(msg:String);
    Warning(msg:String);
}

typedef CreditContent =
{
    var id:String;
    var proper:String;
    var roles:Array<String>;
    var soundcloud:String;
    var bandcamp:String;
    var personal:String;
    var twitter:String;
    var instagram:String;
    var firstDay:Int;
    var portraitPath:String;
    var nonNg:Bool;
}

@:using(Content.LinkTools)
enum LinkType
{
    Newgrounds(name:String);
    Twitter(name:String);
    Instagram(name:String);
    BandCamp(name:String);
    Personal(link:String);
}

class LinkTools
{
    inline public static function getLink(type:LinkType)
    {
        return switch(type)
        {
            case Personal  (link): link;
            case Newgrounds(name): 'http://$name.newgrounds.com';
            case Twitter   (name): 'https://twitter.com/$name';
            case Instagram (name): 'https://www.instagram.com/$name/';
            case BandCamp  (name): 'https://$name.bandcamp.com/';
        }
    }
    
    inline public static function openUrl(type:LinkType)
    {
        return FlxG.openURL(getLink(type));
    }
    
    
    inline public static function getAsset(type:LinkType)
    {
        return 'assets/images/ui/buttons/${getAssetId(type)}.png';
    }
    
    inline static function getAssetId(type:LinkType)
    {
        return switch(type)
        {
            case Personal  (_): "personal";
            case Newgrounds(_): "ng";
            case Twitter   (_): "twitter";
            case Instagram (_): "instagram";
            case BandCamp  (_): "bandcamp";
        }
    }
    
    inline public static function getNgLink(id:String)
    {
        return Newgrounds(id).getLink();
    }
    
    inline public static function openNgUrl(id:String)
    {
        return Newgrounds(id).openUrl();
    }
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
    var animation:Null<{frames:Int, fps:Int, columns:Int}>;
    var thumbPath:String;
    var presentPath:String;
    var medalPath:String;
    var antiAlias:Null<Bool>;
    var medal:Null<Bool>;
    var preload:Bool;
    var sound:String;
    var comic:ComicCreation;
    var ext:String;
}

typedef SongCreation
= Creation &
{
    var samplePath:String;
    var sideDiskPath:String;
    var frontDiskPath:String;
    var loopStart:Null<Int>;
    var loopEnd:Null<Int>;
    var key:String;
    var bpm:Float;
    var ngId:Int;
    var volume:Float;
    var index:Int;
    var ext:String;
}

typedef ArcadeCamera =
{
    var width:Int;
    var height:Int;
    var zoom:Int;
}

typedef ArcadeCreation
= Creation &
{
    var ngId:Int;
    var scoreboard:String;
    var scoreboardId:Int;
    var medalPath:String;
    var mobile:Bool;
    var medal:Bool;
    var type:ArcadeType;
    var camera:ArcadeCamera;
    var cabinet:Bool;
}

typedef ComicCreation =
{
    var pages:Int;
    var audioPath:String;
    var dataPath:String;
}

typedef MovieCreation = Creation &
{
}

enum abstract ArcadeName(String) to String
{
    var Digging = "digging";
    var Chimney = "chimney";
    var Horse = "horse";
    var Positivity = "positivity";
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

@:forward
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
    var midgetsausage;
}


@:forward
enum abstract RoleType(String) from String to String
{
    var owner;
    var pm;
    var code;
    var design;
    var art;
    var anim;
    var music;
    var sound;
    var bg;
    var va;
    var sprites;
    var disk;
    
    var adl_;
}