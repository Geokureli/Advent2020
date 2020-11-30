package states;

import data.Game;
import data.Content;
import data.Manifest;

import flixel.FlxG;

import openfl.utils.Assets;

class BootState extends flixel.FlxState
{
    var manifestLoaded = false;
    
    override function create()
    {
        super.create();
        
        Game.init();
        Content.init(Assets.getText("assets/data/content.json"));
        Manifest.init(onManifestLoad);
        
        FlxG.autoPause = false;
    }
    
    public function onManifestLoad()
    {
        trace("manifest loaded");
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        Game.goToRoom(Main.initialRoom);
    }
}