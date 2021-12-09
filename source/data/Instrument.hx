package data;

import utils.Log;
import openfl.utils.Assets;
import data.Content;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.util.FlxSignal;

class Instrument
{
    inline static var PATH = "assets/sounds/";
    
    static var majorScale:Array<Int> = [0,2,4,5,7,9,11,12];
    static var minorScale:Array<Int> = [0,2,3,5,7,8,10,12];
    static var notes
        = [ "a", "aS", "b", "c", "cS", "d", "dS", "e", "f", "fS", "g", "gS" ];
    
    static var musicKeys:Array<FlxKey>
        = [ E, FOUR, R, FIVE, T, Y, SEVEN, U, EIGHT, I, NINE, O, P];
    
    static public var onChange(default, null) = new FlxSignal();
    
    static var key:Key;
    static var root:Int;
    static var scale:Array<Int>;
    static var currentNote:Null<Int> = null;
    static var activeNotes:Array<FlxSound> = [];
    static var current:InstrumentData;
    static var loading = false;
    
    static public function setCurrent():Void
    {
        var type = Save.getInstrument();
        Log.instrument(type + " setting");
        #if !(PRELOAD_INSTRUMENTS)
        loading = Assets.getLibrary(type) == null;
        if (loading)
        {
            Log.instrument(type + " loading");
            Assets.loadLibrary(type).onComplete(
                function (lib)
                {
                    Log.instrument(type + " loaded, current:" + (current.id == type));
                    if (current.id == type)
                        loading = false;
                }
            );
        }
        #end
        current = Content.instruments[type];
        onChange.dispatch();
    }
    
    static public function checkKeys()
    {
        if (current != null && !loading)
        {
            for (i in 0...musicKeys.length)
            {
                @:privateAccess
                if (FlxG.keys.justReleased.check(musicKeys[i]))
                    Instrument.release(i);
                
                @:privateAccess
                if (FlxG.keys.justPressed.check(musicKeys[i]))
                    Instrument.press(i);
            }
        }
    }
    
    static public function press(note:Int):Void
    {
        if (loading)
            return;
        
        if (current.singleNote && currentNote != note && activeNotes[currentNote] != null)
        {
            var sound = activeNotes[currentNote];
            if (sound.playing)
                sound.fadeOut(0.1, 0, (_)->sound.kill());
        }
        
        currentNote = note;
        
        var soundName = current.mapping != null
            ? current.mapping[note]
            : getNoteName(root + note, current.octave);
        
        final id = current.id;
        if (soundName != null)
            activeNotes[note] = FlxG.sound.play('$id:assets/notes/$id/$soundName.mp3', current.volume);
    }
    
    inline static function getNoteName(scaleNote:Int, octave:Int)
    {
        return (octave + Math.floor(scaleNote / notes.length)) + notes[scaleNote % notes.length];
    }
    
    static public function release(note:Int):Void
    {
        if (activeNotes[note] != null)
        {
            final sound = activeNotes[note];
            activeNotes[note] = null;
            
            if (current.singleNote && note == currentNote)
            {
                currentNote = null;
                var lastPressed = getLastPressed();
                if (lastPressed != -1)
                    press(lastPressed);
            }
            
            if (current.sustain && sound != null && sound.playing)
                sound.fadeOut(0.1, 0, (_)->sound.kill());
        }
    }
    
    inline static function getLastPressed():Int
    {
        var lastPressed = -1;
        for (i in 0...activeNotes.length)
        {
            if (activeNotes[i] != null && (lastPressed == -1 || activeNotes[i].time < activeNotes[lastPressed].time))
                lastPressed = i;
        }
        return lastPressed;
    }
    
    static function setKey(value:Key):Key
    {
        var note:String;
        switch(value)
        {
            case Major(n):
                note = n;
                scale = majorScale;
            case Minor(n):
                note = n;
                scale = minorScale;
        }
        
        root = notes.indexOf(note.split("#").join("S"));
        if (root == -1)
            throw "invalid key";
        
        return key = value;
    }
    
    inline static public function setKeyFromString(key:String):Void
    {
        setKey(getKeyFromString(key));
    }
    
    inline static public function getKeyFromString(key:String):Key
    {
        if (key == null)
            return Major("c");
        
        return switch(key.substr(-3))
        {
            case "Maj": Major(key.substr(0, -3));
            case "Min": Minor(key.substr(0, -3));
            case _: throw "unhandled key: " + key;
        }
    }
    
    inline static public function keyToString(key:Key):String
    {
        return switch(key)
        {
            case Major(note): note + "Maj";
            case Minor(note): note + "Min";
        }
    }
}

enum Key
{
    Major(note:String);
    Minor(note:String);
}