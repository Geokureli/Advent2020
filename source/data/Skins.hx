package data;


import data.Calendar;
import utils.Log;

import flixel.FlxSprite;

import openfl.utils.Assets;

import io.newgrounds.NG;

import haxe.Json;
using StringTools;

class Skins
{
    static var byIndex:Array<SkinData>;
    static var sorted:Array<SkinData>;
    static var skinOrder:Array<String> = [];
    
    static function init()
    {
        if (byIndex != null)
            throw "Skins already initted";
        
        byIndex = Json.parse(Assets.getText("assets/data/skins.json"));
        byIndex.pop();//custom
        sorted = byIndex.copy();
        for (i=>data in byIndex)
        {
            data.index = i;
            data.unlocked = #if UNLOCK_ALL_SKINS true #else false #end;
            
            if (data.year == null)
                data.year = 2021;
            
            if (data.group == null)
                data.group = data.id;
            
            if (skinOrder.indexOf(data.group) == -1)
                skinOrder.push(data.group);
            
            if (data.unlocksBy != null && !Std.is(data.unlocksBy, String))
                throw 'Invalid unlocksBy:${data.unlocksBy} id:${data.id}';
        }
        
        checkUnlocks(!Game.state.match(Intro(_)));
        
        if (NGio.isLoggedIn)
        {
            if (NG.core.medals != null)
                medalsLoaded();
            else
                NG.core.onMedalsLoaded.add(medalsLoaded);
        }
    }
    
    static function medalsLoaded():Void
    {
        for (medal in NG.core.medals)
        {
            if(!medal.unlocked #if debug || true #end)
                medal.onUnlock.add(checkUnlocks.bind(true));
        }
    }
    
    static public function checkUnlocks(showPopup = true)
    {
        var newUnlocks = 0;
        
        for (data in byIndex)
        {
            if (!data.unlocked && (checkUser(data.users) || checkUnlockCondition(data.unlocksBy, data.year)))
            {
                data.unlocked = true;
                if (!Save.hasSeenskin(data.index))
                    newUnlocks++;
            }
            
            if (!data.unlocked && Save.hasSeenskin(data.index))
                Log.save('skin ${data.id} is locked but was seen, unlocksBy:${data.unlocksBy}');
        }
        
        sorted.sort(function (a, b)
            {
                if (a.unlocked == b.unlocked)
                {
                    // sort unlocked by groups
                    if (a.unlocked && a.group != b.group)
                        return sortGroup(a.group, b.group);
                    
                    // sort locked by year
                    if (!a.unlocked && a.year != b.year)
                        return b.year - a.year;// higher years first
                    
                    // index is tie breaker
                    return a.index - b.index; // lower first
                }
                return (a.unlocked ? 0 : 1) - (b.unlocked ? 0 : 1);
            }
        );
        
        if (showPopup && newUnlocks > 0)
            ui.SkinPopup.show(newUnlocks);
    }
    
    static function sortGroup(a:String, b:String)
    {
        return skinOrder.indexOf(a) - skinOrder.indexOf(b);
    }
    
    static public function checkHasUnseen()
    {
        var unlockedCount = 0;
        for (data in byIndex)
        {
            if (data.unlocked)
                unlockedCount++;
        }
        return unlockedCount > Save.countSkinsSeen();
    }
    
    static function checkUser(users:Array<String>)
    {
        return users != null && NGio.isLoggedIn && users.contains(NGio.userName.toLowerCase());
    }
    
    static function checkUnlockCondition(data:Null<String>, year:Null<Int>)
    {
        if (data == null)
            return false;
        
        if (data.indexOf(",") != -1)
        {
            // check many
            var conditions = data.split(",");
            while (conditions.length > 0)
            {
                if (checkUnlockCondition(conditions.shift(), year))
                    return true;
            }
            return false;
        }
        
        var loggedIn = NGio.isLoggedIn;
        
        // check lone
        return switch(data.split(":"))
        {
            case ["login"    ]: loggedIn;
            case ["free"     ]: true;
            case ["supporter"]: loggedIn && NG.core.user.supporter;
            case [_]: throw "Unhandled unlockBy:" + data;
            // 2020
            case ["day"  , day  ] if (year == 2020): loggedIn && Save.countDaysSeen2020() >= Std.parseInt(day);
            case ["medal", medal] if (year == 2020 && medal.length < 3): loggedIn && Save.hasSeenDay2020(Std.parseInt(medal));
            case ["medal", medal] if (year == 2020): loggedIn && Save.hasMedal2020(Std.parseInt(medal));
            // 2021
            case ["day"  , day  ]: Save.countDaysSeen() >= Std.parseInt(day);
            case ["medal", medal] if (medal.length < 3): NGio.hasDayMedal(Std.parseInt(medal));
            case ["medal", medal]: NGio.hasMedal(Std.parseInt(medal));
            default: throw "Unhandled unlockBy:" + data;
        }
    }
    
    static public function isValidSkin(index:Int)
    {
        return index < byIndex.length;
    }
    
    static public function getData(id:Int)
    {
        if (byIndex == null)
            init();
        
        if (id < 0 || byIndex.length <= id)
            throw "Invalid skin id:" + id;
        
        return byIndex[id];
    }
    
    
    static public function getIdByName(name:String)
    {
        if (byIndex == null)
            init();
        
        for (i in 0...byIndex.length)
        {
            if (byIndex[i].id == name)
                return i;
        }
        
        throw "Missing skin with name:" + name;
    }
    
    static public function getDataSorted(id:Int)
    {
        if (sorted == null)
            init();
        
        if (id < 0 || sorted.length <= id)
            throw "Invalid id:" + id;
        
        return sorted[id];
    }
    
    static public function getLength()
    {
        if (byIndex == null)
            init();
        
        return byIndex.length;
    }
}

typedef SkinDataRaw =
{
    var id:String;
    var proper:String;
    var description:String;
    var unlocksBy:String;
    var frames:Null<Int>;
    var fps:Null<Int>;
    var offset:Null<{x:Float, y:Float}>;
    var users:Null<Array<String>>;
    var year:Int;
    var group:String;
}

typedef SkinDataPlus = SkinDataRaw &
{
    var index:Int;
    var unlocked:Bool;
}

@:forward
abstract SkinData(SkinDataPlus) from SkinDataPlus to SkinDataPlus
{
    public var path(get, never):String;
    inline function get_path() return 'assets/images/player/${this.id}.png';
    
    public function loadTo(sprite:FlxSprite)
    {
        sprite.loadGraphic(path);
        if (this.frames != null && this.frames > 1)
        {
            sprite.loadGraphic(path, true, Std.int(sprite.frameWidth / this.frames), sprite.frameHeight);
            sprite.animation.add("default", [for (i in 0...this.frames) i], this.fps != null ? this.fps : 8);
            sprite.animation.play("default");
        }
    }
}