package data;

import data.Content;
import states.rooms.RoomState;

import utils.Log;
import utils.BitArray;

import flixel.FlxG;

import haxe.Int64;
import haxe.PosInfos;

class Save
{
    inline static var name = "advent2020";
    inline static var path = "GeoKureli";
    
    static var emptyData:SaveData = cast {}
    
    static var data:SaveData;
    
    static public function init()
    {
        #if !(DISABLE_SAVE)
        if (FlxG.save.bind(name, path))
            data = FlxG.save.data;
        else
        #end
            data = emptyData;
        
        var clearSave = #if CLEAR_SAVE true #else false #end;
        
        // set default values
        var newData = false;
        if (clearSave || data.presents == null)
        {
            data.presents = new BitArray();
            newData = true;
        }
        log("presents: " + data.presents);
        
        if (clearSave || data.days == null)
        {
            data.days = new BitArray();
            newData = true;
        }
        log("seen days: " + data.days);
        
        //PLURAL: seen skins
        if (clearSave || data.skins == null)
        {
            data.skins = new BitArray();
            newData = true;
        }
        log("seen skins: " + data.skins);
        
        //SINGULAR: current skin
        if (clearSave || data.skin == null)
        {
            data.skin = 0;
            newData = true;
        }
        log("skin: " + data.skin);
        
        #if FORGET_INSTRUMENT data.instrument = null; #end
        if (clearSave || data.instrument == null)
        {
            data.instrument = -1;
            newData = true;
        }
        log("instrument: " + data.instrument);
        
        #if FORGET_INSTRUMENT data.seenInstruments = null; #end
        if (clearSave || data.seenInstruments == null)
        {
            data.seenInstruments = new BitArray();
            newData = true;
        }
        log("instruments seen: " + data.seenInstruments);
        
        if (data.instrument < -1 && (data.seenInstruments:Int64) > 0)
        {
            // fix an old glitch where i deleted instrument save
            var i = 0;
            while (!data.seenInstruments[i] && i < 32)
                i++;
            data.instrument = i;
            newData = true;
        }
        
        if (newData)
            flush();
        
        function setInitialInstrument()
        {
            var instrument = getInstrument();
            if (instrument != null)
                Instrument.setCurrent();
        }
        
        if (Content.isInitted)
            setInitialInstrument();
        else
            Content.onInit.addOnce(setInitialInstrument);
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
    
    static public function presentOpened(id:String)
    {
        var index = Content.getPresentIndex(id);
        
        if (index < 0)
            throw "invalid present id:" + id;
        
        if (data.presents[index] == false)
        {
            data.presents[index] = true;
            flush();
        }
    }
    
    static public function hasOpenedPresent(id:String)
    {
        var index = Content.getPresentIndex(id);
        
        if (index < 0)
            throw "invalid present id:" + id;
        
        return data.presents[index];
    }
    
    inline static public function hasOpenedPresentByDay(day:Int)
    {
        return data.presents[day - 1];
    }
    
    static public function countPresentsOpened(id:String)
    {
        return data.presents.countTrue();
    }
    
    static public function anyPresentsOpened()
    {
        return !noPresentsOpened();
    }
    
    static public function noPresentsOpened()
    {
        return data.presents.getLength() == 0;
    }
    
    static public function daySeen(day:Int)
    {
        day--;//saves start at 0
        if (data.days[day] == false)
        {
            data.days[day] = true;
            flush();
        }
    }
    
    static public function debugForgetDay(day:Int)
    {
        day--;//saves start at 0
        data.days[day] = false;
        data.presents[day] = false;
        flush();
    }
    
    static public function hasSeenDay(day:Int)
    {
        //saves start at 0
        return data.days[day - 1];
    }
    
    static public function countDaysSeen()
    {
        return data.days.countTrue();
    }
    
    static public function skinSeen(index:Int)
    {
        #if !(UNLOCK_ALL_SKINS)
        if (data.skins[index] == false)
        {
            data.skins[index] = true;
            flush();
        }
        #end
    }
    
    static public function hasSeenskin(index:Int)
    {
        return data.skins[index];
    }
    
    static public function countSkinsSeen()
    {
        return data.skins.countTrue();
    }
    
    static public function setSkin(id:Int)
    {
        PlayerSettings.user.skin = data.skin = id;
        flush();
    }
    
    static public function getSkin()
    {
        return data.skin;
    }
    
    static public function setInstrument(type:InstrumentType)
    {
        if (type == null || type == getInstrument()) return;
        
        PlayerSettings.user.instrument = type;
        data.instrument = Content.instruments[type].index;
        flush();
        Instrument.setCurrent();
    }
    
    static public function getInstrument()
    {
        if (data.instrument < 0) return null;
        return Content.instrumentsByIndex[data.instrument].id;
    }
    
    static public function instrumentSeen(type:InstrumentType)
    {
        if (type == null) return;
        
        data.seenInstruments[Content.instruments[type].index] = true;
        flush();
    }
    
    static public function seenInstrument(type:InstrumentType)
    {
        if (type == null) return true;
        
        return data.seenInstruments[Content.instruments[type].index];
    }
    
    inline static function log(msg, ?info:PosInfos) Log.save(msg, info);
}

typedef SaveData =
{
    var presents:BitArray;
    var days:BitArray;
    var skins:BitArray;
    var skin:Int;
    var instrument:Int;
    var seenInstruments:BitArray;
}