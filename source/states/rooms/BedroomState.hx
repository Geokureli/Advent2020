package states.rooms;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.Manifest;
import props.InputPlayer;
import props.InfoBox;
import states.OgmoState;
import states.debug.AudioToolSubstate;
import utils.GameSize;
import vfx.DitherShader;
import vfx.DitherSprite;
import vfx.PixelPerfectShader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;

import openfl.filters.ShaderFilter;

class BedroomState extends RoomState
{
    var dresser:OgmoDecal;
    
    override function create()
    {
        // GameSize.setPixelSize(4);
        super.create();
        
        // FlxG.camera.pixelPerfectRender = true;
        
        // Manifest.playMusic("albegian");
        // #if debug FlxG.debugger.drawDebug = true; #end
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var door = background.getByName("door");
        door.animation.add("open", [0]);
        door.animation.add("closed", [1]);
        door.animation.play("closed");
        
        dresser = foreground.getByName("dresser");
        dresser.setBottomHeight(8);
        addHoverTextTo(dresser, "DRESS UP", onOpenDresser);
    }
    
    function onOpenDresser()
    {
        trace("dresser opened");
    }
}