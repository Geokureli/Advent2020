package data;

import data.Content;
import states.rooms.RoomState;

import utils.Log;
import utils.BitArray;

import flixel.FlxG;
import flixel.util.FlxSave;

import haxe.Int64;
import haxe.PosInfos;

class Save
{
    static var emptyData:SaveData = cast {}
    
    static var data:SaveData;
    static public var showName(get, set):Bool;
    
    static public function init()
    {
        #if DISABLE_SAVE
            data = emptyData;
        #else
            if (FlxG.save.bind("advent2021", "GeoKureli"))
                data = FlxG.save.data;
            else
                data = emptyData;
            
        #end
        
        #if LOAD_2020_SKINS
        load2020SaveData(false);
        #end
        
        var clearSave = #if CLEAR_SAVE true #else false #end;
        
        // set default values
        var newData = false;
        if (clearSave || data.presents == null)
        {
            data.presents = new BitArray();
            newData = true;
        }
        else if (BitArray.isOldFormat(data.presents))
        {
            data.presents = BitArray.fromOldFormat(cast data.presents);
            newData = true;
        }
        log("presents: " + data.presents);
        
        if (clearSave || data.days == null)
        {
            data.days = new BitArray();
            newData = true;
        }
        else if (BitArray.isOldFormat(data.days))
        {
            data.days = BitArray.fromOldFormat(cast data.days);
            newData = true;
        }
        log("seen days: " + data.days);
        
        if (clearSave || data.days2020 == null)
        {
            deleteSave2020(false);
            newData = true;
        }
        log("seen days 2020: " + data.days2020);
        log("medals unlocked 2020: " + data.medalsUnlocked2020);
        log("medals user id 2020: " + data.ngioUserId2020);
        
        //PLURAL: seen skins
        if (clearSave || data.skins == null)
        {
            data.skins = new BitArray();
            newData = true;
        }
        else if (BitArray.isOldFormat(data.skins))
        {
            data.skins = BitArray.fromOldFormat(cast data.skins);
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
        else if (BitArray.isOldFormat(data.seenInstruments))
        {
            data.seenInstruments = BitArray.fromOldFormat(cast data.seenInstruments);
            newData = true;
        }
        log("instruments seen: " + data.seenInstruments);
        
        if (clearSave)
            data.ngioSessionId = null;
        log("saved session: " + data.ngioSessionId);
        
        if (clearSave || data.showName == null)
        {
            data.showName = false;
            newData = true;
        }
        log("saved session: " + data.ngioSessionId);
        
        if (data.instrument < -1 && data.seenInstruments.countTrue() > 0)
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
    
    #if LOAD_2020_SKINS
    @:allow(data.NGio)
    static function load2020SaveData(clearCache = true)
    {
        #if debug
        if (APIStuff.DEBUG_SESSON_2020 != null)
        {
            data.ngioSessionId2020 = APIStuff.DEBUG_SESSON_2020;
            flush();
            return;
        }
        #end
        
        // bypass openfl's save cache via hacking
        if (clearCache)
        {
            // delete saved session
            if (data.ngioSessionId2020 != null)
            {
                data.ngioSessionId2020 = null;
                flush();
            }
            clearSharedObjectCache("advent2020", "GeoKureli");
        }
        
        // Load last years save for session id
        var save2020 = new FlxSave();
        if (save2020.bind("advent2020", "GeoKureli"))
        {
            var data2020:SaveData2020 = save2020.data;
            log("2020 data found: " + data2020);
            if (data2020.ngioSessionId != null)
            {
                data.ngioSessionId2020 = data2020.ngioSessionId;
                flush();
            }
            
            if (data.skin == null && data2020.skin != null)
            {
                log("using 2020 skin:" + data2020.skin);
                data.skin = data2020.skin;
            }
        }
    }
    
    static function clearSharedObjectCache(name:String, path:String)
    {
        @:privateAccess
        openfl.net.SharedObject.__sharedObjects.remove('$path/$name');
    }
    #end
    
    static function flush()
    {
        if (data != emptyData)
            FlxG.save.flush();
    }
    
    static public function resetPresents()
    {
        data.presents = new BitArray();
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
    
    static public function setNgioSessionId(id:String)
    {
        #if !(NG_LURKER)
        if (data.ngioSessionId != id)
        {
            data.ngioSessionId = id;
            flush();
        }
        #end
    }
    
    static public function getNgioSessionId():Null<String>
    {
        #if NG_LURKER
        return null;
        #else
        return data.ngioSessionId;
        #end
    }
    
    inline static function get_showName() return data.showName;
    static function set_showName(value:Bool)
    {
        if (data.showName != value)
        {
            data.showName = value;
            flush();
        }
        return value;
    }
    
    inline static public function toggleShowName()
        return showName = !showName;
    
    /* --- --- --- --- 2020 --- --- --- --- */
    
    static public function getNgioSessionId2020():Null<String>
    {
        return data.ngioSessionId2020;
    }
    
    @:allow(data.NGio)
    static function setUnlockedMedals2020(ids:Array<Int>)
    {
        data.medalsUnlocked2020 = ids;
        flush();
    }
    
    @:allow(data.NGio)
    static function setDaysSeen2020(bits:BitArray)
    {
        if (data.days2020 != bits)
        {
            data.days2020 = bits;
            flush();
        }
    }
    
    @:allow(data.NGio)
    static function setNgioUserId2020(id:Int)
    {
        if (data.ngioUserId2020 != id)
        {
            data.ngioUserId2020 = -1;
            flush();
        }
    }
    
    @:allow(data.NGio)
    static function verifySave2020(id:Int)
    {
        if (data.ngioUserId2020 != id || id == -1)
            deleteSave2020();
    }
    
    @:allow(data.NGio)
    static function deleteSave2020(flushNow = true)
    {
        data.ngioUserId2020 = -1;
        data.days2020 = new BitArray();
        data.medalsUnlocked2020 = [];
        if (flushNow)
            flush();
    }
    
    static public function hasSave2020()
    {
        return data.days2020.countTrue() > 0
            || data.medalsUnlocked2020.length > 0;
    }
    
    static public function hasMedal2020(id:Int)
    {
        return data.medalsUnlocked2020.indexOf(id) != -1;
    }
    
    static public function hasSeenDay2020(day:Int)
    {
        // zero based
        return data.days2020[day - 1];
    }
    
    static public function countDaysSeen2020()
    {
        return data.days2020.countTrue();
    }
    
    inline static function log(msg, ?info:PosInfos) Log.save(msg, info);
}

typedef SaveData2020 =
{
    var presents:BitArray;
    var days:BitArray;
    var skins:BitArray;
    var skin:Int;
    var instrument:Int;
    var seenInstruments:BitArray;
    var ngioSessionId:String;
}

typedef SaveData = SaveData2020 &
{
    var ngioSessionId2020:String;
    var ngioUserId2020:Int;
    var days2020:BitArray;
    var medalsUnlocked2020:Array<Int>;
    var showName:Bool;
}