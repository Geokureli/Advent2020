package data;

import utils.BitArray;

import flixel.FlxG;

import haxe.Int64;

class Save
{
    inline static var name = "advent2020";
    inline static var path = "GeoKureli";
    
    static var emptyData:SaveData = cast {}
    
    static var data:SaveData;
    
    static public function init()
    {
        if (FlxG.save.bind(name, path))
            data = FlxG.save.data;
        else
            data = emptyData;
        
        // default values
        if (data.presents == null)
            data.presents = new BitArray();
        
        if (data.days == null)
            data.days = new BitArray();
    }
    
    static function flush()
    {
        if (data != emptyData)
            FlxG.save.flush();
    }
    
    static public function resetPresents()
    {
        data.presents = (0:Int64);
        flush();
    }
    
    static public function presentOpen(id:String)
    {
        var i = Content.getPresentIndex(id);
        
        if (i < 0)
            throw "invalid present id:" + id;
        
        if (data.presents[i] == false)
        {
            data.presents[i] = true;
            flush();
        }
    }
    
    static public function hasOpenPresent(id:String)
    {
        var i = Content.getPresentIndex(id);
        
        if (i < 0)
            throw "invalid present id:" + id;
        
        return data.presents[i];
    }
    
    static public function daySeen(id:Int)
    {
        id--;//saves start at 0
        if (data.days[id] == false)
        {
            data.days[id] = true;
            flush();
        }
    }
    
    static public function hasSeenDay(id:Int)
    {
        //saves start at 0
        return data.days[id - 1];
    }
}

typedef SaveData = { presents:BitArray, days:BitArray }