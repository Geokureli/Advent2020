package data;

import utils.BitArray;
import states.OutsideState;
import flixel.FlxG;
import haxe.Json;
import haxe.ds.ReadOnlyArray;
import openfl.utils.Assets;

class OldCalendar
{
    inline static var DEBUG_DAY:Int = 0;// 0 to disable debug feature
    static public var isDebugDay = DEBUG_DAY > 0;
    static public var isPast(default, null) = false;
    static public var participatedInAdvent(default, null) = false;
    static public var day(default, null) = 24;
    static public var hanukkahDay(default, null) = 7;
    static public var isAdvent(default, null) = false;
    static public var isDecember(default, null) = false;
    static public var isChristmas(default, null) = false;
    static public var data(default, null):ReadOnlyArray<ContentData>;
    static public var today(get, never):ContentData;
    static public var openedPres(default, null) = new BitArray();
    static public var seenDays(default, null) = new BitArray();
    
    static var unveiledArtists(default, null) =
	[ "geokureli"    // organizer/programmer
	, "brandybuizel" // artist
	, "thedyingsun"  // artist, tree
	, "nickconter"   // artist, sculptures
	];// populated automatically from contents artists based on the day
    
    // Can preview the next day
    static var whitelist = unveiledArtists.copy();
    
    inline static function get_today() return data[day];
    
    static public function init(callback:Void->Void = null):Void
    {
        data = Json.parse(Assets.getText("assets/data/content.json"));
        parseWhitelist();
        
        function initSaveAndEnd()
        {
            parseUnveiledArtists();
            
            FlxG.save.bind("advent2019", "GeoKureli");
            if (Std.is(FlxG.save.data.openedPres, Int))
            {
                openedPres = FlxG.save.data.openedPres;
                // trace("loaded savefile: " + openedPres);
            }
            
            if (Std.is(FlxG.save.data.seenDays, Int))
            {
                seenDays = FlxG.save.data.seenDays;
            }
            
            seenMurder = FlxG.save.data.seenMurder == true;
            hasKnife = FlxG.save.data.hasKnife == true;
            solvedMurder = FlxG.save.data.solvedMurder == true;
            
            if (Std.is(FlxG.save.data.interrogated, Int))
                interrogated = FlxG.save.data.interrogated;
            else
                interrogated = BitArray.fromString("11111111111");
            
            // trace("day: " + day);
            if (callback != null)
                callback();
        }
        
        if (DEBUG_DAY == 0)
        {
            NGio.checkNgDate(()->{
                onDateReceived(NGio.ngDate);
                initSaveAndEnd();
            });
        }
        else
        {
            day = DEBUG_DAY - 1;
            isAdvent = true;
            isDecember = true;
            initSaveAndEnd();
        }
    }
    
    static public function onMedalsRequested():Void
    {
        var saveNow = FlxG.save.data.seenDays == null;
        
        for (i in 0...25)
        {
            if (NGio.hasDayMedal(i))
            {
                participatedInAdvent = true;
                if (!seenDays[i])
                {
                    seenDays[i] = true;
                    saveNow = true;
                }
            }
        }
        
        if (saveNow)
        {
            FlxG.save.data.seenDays = (seenDays:Int);
            FlxG.save.flush();
        }
    }
    
    static function parseWhitelist():Void
    {
        for (i in 0...data.length)
        {
            var artist = data[i].art.artist.toLowerCase();
            if (whitelist.indexOf(artist) == -1)
                whitelist.push(artist);
            
            artist = data[i].song.artist.toLowerCase();
            if (whitelist.indexOf(artist) == -1)
                whitelist.push(artist);
        }
        
        NGio.checkWhitelist();
    }
    
    static function parseUnveiledArtists():Void
    {
        for (i in 0...day + 1)
        {
            var artist = data[i].art.artist.toLowerCase();
            if (unveiledArtists.indexOf(artist) == -1)
                unveiledArtists.push(artist);
            
            artist = data[i].song.artist.toLowerCase();
            if (unveiledArtists.indexOf(artist) == -1)
                unveiledArtists.push(artist);
        }
        
        NGio.checkWhitelist();
    }
    
    static function onDateReceived(date:Date):Void
    {
        isDecember = date.getMonth() == 11;
        isChristmas = date.getDate() == 25;
        
        if (isDecember)// && date.getFullYear() == 2019)
        {
            hanukkahDay = date.getDate() - 22;
            if (date.getDate() < 26)
            {
                isAdvent = true;
                day = date.getDate() - 1;
            }
        }
        
        if (!seenDays[day])
        {
            seenDays[day] = true;
            FlxG.save.data.seenDays = (seenDays:Int);
            FlxG.save.flush();
        }
    }
    
    static public function getData(day:Int):Null<ContentData>
    {
        if (isAdvent && data.length > day)
            return data[day];
        return null;
    }
    
    static public function checkWhitelisted(user:String):Bool
    {
        return whitelist.indexOf(user.toLowerCase()) != -1;
    }
    
    static public function checkUnveiledArtist(user:String):Bool
    {
        return unveiledArtists.indexOf(user.toLowerCase()) != -1;
    }
    
    static public function saveOpenPresent(day:Int)
    {
        openedPres[day] = true;
        // trace("saved: " + openedPres);
        FlxG.save.data.openedPres = (openedPres:Int);
        FlxG.save.flush();
    }
    
    static public function saveSeenMurder()
    {
        FlxG.save.data.seenMurder = seenMurder = true;
        FlxG.save.flush();
    }
    
    static public function resetMurder():Void
    {
        seenMurder = FlxG.save.data.seenMurder = false;
        hasKnife = FlxG.save.data.hasKnife = false;
        solvedMurder = FlxG.save.data.solvedMurder = false;
        interrogated = FlxG.save.data.interrogated = BitArray.fromString("11111111111");
        FlxG.save.flush();
        openedPres[13-1] = false;
    }
    
    static public function saveInterrogated(index:Int)
    {
        interrogated[index] = false;
        FlxG.save.data.interrogated = interrogated;
        FlxG.save.flush();
    }
    
    inline static function get_interrogatedAll():Bool
    {
        return (interrogated:Int) == 0;
    }
    
    static public function saveHasKnife():Void
    {
        FlxG.save.data.hasKnife = hasKnife = true;
        FlxG.save.flush();
    }
    
    static public function saveSolvedMurder():Void
    {
        FlxG.save.data.solvedMurder = solvedMurder = true;
        FlxG.save.flush();
    }
    
    static public function resetOpenedPresents()
    {
        openedPres.reset();
        FlxG.save.data.openedPres = 0;
        FlxG.save.flush();
    }
    
    static public function allowDailyMedalUnlock(day:Int):Bool
    {
        return isChristmas
            || ((isAdvent || participatedInAdvent) && day == Calendar.day);
    }
    
    static public function showDebugNextDay():Void
    {
        day++;
        isDebugDay = true;
        parseUnveiledArtists();
    }
    
    static public function timeTravelTo(date:Int):Void
    {
        isDecember = true;
        isPast = true;
        day = date;
        
        if (!seenDays[day])
        {
            seenDays[day] = true;
            FlxG.save.data.seenDays = (seenDays:Int);
            FlxG.save.flush();
        }
    }
    
    inline static public function getPresentPath(index = -1):String
    {
        return 'assets/images/presents/present_${index == -1 ? day + 1 : index + 1}.png';
    }
    
    inline static public function getMedalPath(index = -1):String
    {
        return 'assets/images/presents/medal${index == -1 ? day + 1 : index + 1}.png';
    }
}

typedef RawCreationData =
{ 
    artist:String,
    ?credit:String,
    ?statue:String,
    ?fileExt:String,
    ?id:Int
}

typedef RawMusicData = RawCreationData &
{ 
    key:String,
    ?volume:Float
}

typedef RawArtData = RawCreationData &
{
    ?frames:Int,
    ?antiAlias:Bool,
    ?link:String
}

typedef RawContentData =
{
    final art  :ArtData;
    final song :MusicData;
    final char :String;
    final tv   :Null<String>;
    final ready:Null<Bool>;
    final extras:Null<Array<ArtData>>;
}

@:forward
abstract CreationData<T:RawCreationData>(T) from T
{
    public var credit(get, never):String;
    inline function get_credit() return this.credit != null ? this.credit : this.artist;
    public var statue(get, never):String;
    inline function get_statue() return this.statue != null ? this.statue : this.artist;
    
    inline public function getProfileLink() return "https://" + this.artist + ".newgrounds.com";
    
    inline public function getFilename(defaultExt = "jgp"):String
    {
        return this.artist.toLowerCase() + "." + (this.fileExt == null ? defaultExt : this.fileExt);
    }
    
    inline public function getSnowmanPath():String
    {
        return 'assets/images/snowSprite/${statue}.png';
    }
}

@:forward
abstract MusicData(CreationData<RawMusicData>) from RawMusicData
{
    inline public function getPath():String
        return "assets/music/" + this.getFilename("mp3");
}

@:forward
abstract ArtData(CreationData<RawArtData>) from RawArtData
{
    inline public function getPath():String
        return "assets/artwork/" + this.getFilename("jpg");
    
    inline public function getThumbPath():String
        return "assets/images/thumbs/thumb-" + this.getFilename("png");
    
    public function getExternalPath():String
    {
        if (this.id == null || this.link == null)
            return null;
        
        return "https://art.ngfiles.com/images/" + (Std.int(this.id / 1000) * 1000) + "/" + this.link;
    }
}

@:forward
abstract ContentData(RawContentData) from RawContentData
{
    public var profileLink(get,never):String;
    inline function get_profileLink() return this.art.getProfileLink();
    
    public var musicProfileLink(get,never):String;
    inline function get_musicProfileLink() return this.song.getProfileLink();
    
    public var ready(get, never):Bool;
    inline function get_ready() return this.ready != false;
    
    public var notReady(get, never):Bool;
    inline function get_notReady() return this.ready == false;
    
    inline public function getArtPath():String return this.art.getPath();
    
    inline public function getThumbPath():String return this.art.getThumbPath();
    
    inline public function getSongPath():String return this.song.getPath();
    
    inline public function getArtistSnowmanPath():String return this.art.getSnowmanPath();
    
    inline public function getMusicianSnowmanPath():String return this.song.getSnowmanPath();
}