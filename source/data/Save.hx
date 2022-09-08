package data;

import data.Content;
import states.rooms.RoomState;

import utils.Log;
import utils.BitArray;

import io.newgrounds.NG;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.Outcome;

import flixel.FlxG;
import flixel.util.FlxSave;

import haxe.Int64;
import haxe.Json;
import haxe.PosInfos;

using io.newgrounds.objects.events.Outcome.OutcomeTools;

class Save
{
    static var emptyData:SaveData = cast {}
    
    static var data:SaveData;
    
    static public function init(callback:(Outcome<String>)->Void)
    {
        #if DISABLE_SAVE
        data = emptyData;
        #else
        NG.core.saveSlots.loadAllFiles
        (
            (outcome)->outcome.splitHandlers((_)->onCloudSavesLoaded(callback), callback)
        );
        #end
    }
    
    static function onCloudSavesLoaded(callback:(Outcome<String>)->Void)
    {
        #if CLEAR_SAVE
        createInitialData();
        flush();
        #else
        if (NG.core.saveSlots[1].isEmpty())
        {
            createInitialData();
            mergeLocalSave();
            flush();
        }
        else
            data = Json.parse(NG.core.saveSlots[1].contents);
        #end
        
        if (NG.core.medals.state == Loaded)
            checkMedals();
        else
            NG.core.medals.onLoaded.addOnce(checkMedals);
        
        log("presents: " + data.presents);
        log("seen days: " + data.days);
        log("seen skins: " + data.skins);
        log("skin: " + data.skin);
        log("instrument: " + data.instrument);
        log("instruments seen: " + data.seenInstruments);
        
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
        
        callback(SUCCESS);
    }
    
    static function createInitialData()
    {
        data =
            { presents       : new BitArray()
            , days           : new BitArray()
            , skins          : new BitArray()
            , seenInstruments: new BitArray()
            , skin           :  0
            , instrument     : -1
            };
    }
    
    static function mergeLocalSave()
    {
        var save = new FlxSave();
        if (save.bind("advent2020", "GeoKureli") && save.isEmpty() == false)
        {
            final localData:SaveData = save.data;
            if (BitArray.isOldFormat(localData.presents))
                localData.presents = BitArray.fromOldFormat(cast localData.presents);
            
            if (BitArray.isOldFormat(localData.days))
                localData.days = BitArray.fromOldFormat(cast localData.days);
            
            if (BitArray.isOldFormat(localData.skins))
                localData.skins = BitArray.fromOldFormat(cast localData.skins);
            
            if (BitArray.isOldFormat(localData.seenInstruments))
                localData.seenInstruments = BitArray.fromOldFormat(cast localData.seenInstruments);
            
            if (localData.instrument < -1 && localData.seenInstruments.countTrue() > 0)
            {
                // fix an old glitch where i deleted instrument save
                var i = 0;
                while (!localData.seenInstruments[i] && i < 32)
                    i++;
                
                localData.instrument = i;
            }
            
            for (field in Reflect.fields(localData))
                Reflect.setField(data, field, Reflect.field(localData, field));
            
            save.erase();
        }
    }
    
    static function checkMedals()
    {
        var newData = false;
        for (medal in NG.core.medals)
        {
            if(medal.id - NGio.DAY_MEDAL_0 <= 31)
            {
                log("seen day:" + (medal.id - NGio.DAY_MEDAL_0 + 1));
                newData = newData
                    || daySeen(medal.id - NGio.DAY_MEDAL_0 + 1, false);
            }
        }
        if (newData)
            flush();
    }
    
    static function flush(?callback:(Outcome<Error>)->Void)
    {
        if (data != emptyData)
            NG.core.saveSlots[1].save(Json.stringify(data), callback);
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
    
    /**
     * Sets the day as seen, and optionally saves the data.
     * 
     * @param day       The day.
     * @param flushNow  If true, the new data is saved, use false if setting days in batches
     * @return Whether the data needed to be changed, in the first place
     */
    static public function daySeen(day:Int, flushNow = true):Bool
    {
        day--;//saves start at 0
        if (data.days[day] == false)
        {
            data.days[day] = true;
            if (flushNow)
                flush();
            return true;
        }
        return false;
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
    var presents       :BitArray;
    var days           :BitArray;
    var skins          :BitArray;
    var seenInstruments:BitArray;
    var skin           :Int;
    var instrument     :Int;
}