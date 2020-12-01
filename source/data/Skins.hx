package data;


import data.Calendar;
import flixel.FlxSprite;

import openfl.utils.Assets;

import haxe.Json;
using StringTools;

class Skins
{
    static var byIndex:Array<SkinData>;
    static var sorted:Array<SkinData>;
    
    static function init()
    {
        if (byIndex != null)
            throw "Skins already initted";
        
        byIndex = Json.parse(Assets.getText("assets/data/skins.json"));
        byIndex.pop();//custom
        sorted = byIndex.copy();
        for (i in 0...byIndex.length)
        {
            byIndex[i].index = i;
            byIndex[i].unlocked = #if UNLOCK_ALL_SKINS true #else false #end;
        }
        
        checkUnlocks();
    }
    
    static public function checkUnlocks()
    {
        for (data in byIndex)
        {
            if (!data.unlocked)
            {
                if (data.users != null && NGio.isLoggedIn && data.users.contains(NGio.userName.toLowerCase()))
                {
                    data.unlocked = true;
                }
                else if (data.unlocksBy != null)
                {
                    final split = data.unlocksBy.split(":");
                    switch(split.shift())
                    {
                        case "day":
                            var day = Std.parseInt(split.shift());
                            data.unlocked = Calendar.day >= day;
                        case "medal":
                            var medal = Std.parseInt(split.shift());
                            data.unlocked = NGio.hasDayMedal(medal);
                    }
                }
            }
        }
        
        sorted.sort(function (a, b)
            {
                if (a.unlocked == b.unlocked)
                    return a.index - b.index;
                return (a.unlocked ? 0 : 1) - (b.unlocked ? 0 : 1);
            }
        );
    }
    
    static public function getData(id:Int)
    {
        if (byIndex == null)
            init();
        
        if (id < 0 || byIndex.length <= id)
            throw "Invalid id:" + id;
        
        return byIndex[id];
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
    var offsetX:Null<Float>;
    var offsetY:Null<Float>;
    var users:Null<Array<String>>;
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