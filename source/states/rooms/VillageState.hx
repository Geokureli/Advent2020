package states.rooms;

import data.Manifest;
import states.OgmoState;
import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;
import ui.Prompt;

import flixel.FlxG;
import flixel.math.FlxMath;

class VillageState extends RoomState
{
    override function create()
    {
        super.create();
        
        add(new vfx.Snow(40));

        if(Game.state.match(Intro(Started))){
            Game.state = Intro(Village);
            showIntroCutscene();
        }
    }
    
    override function initEntities()
    {
        super.initEntities();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }

    private function showIntroCutscene(){
        var cam = FlxG.camera;
        Manifest.playMusic("midgetsausage");
    }
}