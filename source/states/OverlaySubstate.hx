package states;

import ui.Controls;
import flixel.util.FlxTimer;
import data.Content;
import utils.OverlayGlobal;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;

class OverlaySubstate extends flixel.FlxSubState
{
    var state:FlxState = null;
    var requestedState:FlxState = null;
    var timers = new FlxTimerManager();
    
    public function new(initialState:FlxState, cameraData:ArcadeCamera)
    {
        super();
        
        OverlayGlobal.container = this;
        requestedState = initialState;
        camera = new FlxCamera(0, 0, cameraData.width, cameraData.height, cameraData.zoom);
        camera.x = (FlxG.width - camera.width * cameraData.zoom) / 2;
        camera.y = (FlxG.height - camera.height * cameraData.zoom) / 2;
    }
    
    override function create()
    {
        super.create();
        FlxG.cameras.add(camera);
        switchStateActual();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        timers.update(elapsed);
        if (state != requestedState)
            switchStateActual();
        
        if (Controls.justPressed.EXIT)
            close();
    }
    
    public function switchState(nextState:FlxState)
    {
		if (state.switchTo(nextState))
			requestedState = nextState;
    }
    
    public function switchStateActual()
    {
        if (state != null)
        {
            remove(state);
            state.destroy();
        }
        
        timers.clear();
        state = requestedState;
        add(state);
        state.camera = camera;
        state.create();
    }
    
    public function createTimer()
    {
        return new FlxTimer(timers);
    }
    
    override function close()
    {
        FlxG.cameras.remove(camera);
        OverlayGlobal.container = null;
        timers.clear();
        super.close();
    }
}