package states;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import data.Content;
import ui.Controls;
import utils.OverlayGlobal;
import vfx.CrtShader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import openfl.filters.ShaderFilter;

class OverlaySubstate extends flixel.FlxSubState
{
    public var state(default, null):FlxState = null;
    var requestedState:FlxState = null;
    var timers = new FlxTimerManager();
    var oldTimers:FlxTimerManager;
    var tweens = new FlxTweenManager();
    var oldTweens:FlxTweenManager;
    var oldCamera:FlxCamera;
    var oldBounds:FlxRect;
    var bg:FlxSprite;
    
    public function new(initialState:FlxState, cameraData:ArcadeCamera)
    {
        super();
        
        OverlayGlobal.container = this;
        requestedState = initialState;
        if (cameraData == null)
            cameraData = { width:FlxG.width, height:FlxG.height, zoom:1 };
        camera = new FlxCamera(0, 0, cameraData.width, cameraData.height, cameraData.zoom);
        camera.setFilters([new ShaderFilter(new CrtShader())]);
        camera.bgColor = 0x0;
        camera.x = (FlxG.width - camera.width * cameraData.zoom) / 2;
        camera.y = (FlxG.height - camera.height * cameraData.zoom) / 2;
    }
    
    override function create()
    {
        super.create();
        
        bg = new FlxSprite();
        bg.makeGraphic(1, 1);
        bg.color = 0x0;
        bg.setGraphicSize(FlxG.width << 1, FlxG.height << 1);
        bg.scrollFactor.set(0,0);
        bg.camera = camera;
        add(bg);
        
        var instructions = new FlxBitmapText();
        instructions.text = "Press ESCAPE to exit";
        instructions.setBorderStyle(OUTLINE, 0xFF00000);
        instructions.camera = FlxG.camera;
        add(instructions);
        
        oldCamera = FlxG.camera;
        FlxG.camera = camera;
        FlxG.cameras.add(camera);
        oldTimers = FlxTimer.globalManager;
        FlxTimer.globalManager = timers;
        oldTweens = FlxTween.globalManager;
        FlxTween.globalManager = tweens;
        oldBounds = FlxRect.get().copyFrom(FlxG.worldBounds);
        
        switchStateActual();
    }
    
    override function update(elapsed:Float)
    {
        if (camera.bgColor != 0x0)
        {
            bg.color = camera.bgColor;
            camera.bgColor = 0x0;
        }
        
        super.update(elapsed);
        
        timers.update(elapsed);
        tweens.update(elapsed);
        
        if (state != requestedState && requestedState != null)
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
        tweens.clear();
		FlxG.worldBounds.set(-10, -10, camera.width + 20, camera.height + 20);
        camera.scroll.set(0, 0);
        camera.setScrollBounds(null, null, null, null);
        camera.follow(null);
        @:privateAccess
        camera._scrollTarget.set(0, 0);
        camera.deadzone = null;
        // camera.update(0);
        state = requestedState;
        requestedState = null;
        add(state);
        state.camera = camera;
        state.create();
    }
    
    override function close()
    {
        FlxG.cameras.remove(camera);
        OverlayGlobal.container = null;
        timers.clear();
        tweens.clear();
        FlxTimer.globalManager = oldTimers;
        FlxTween.globalManager = oldTweens;
        FlxG.camera = oldCamera;
        FlxG.worldBounds.copyFrom(oldBounds);
        oldTimers = null;
        oldTweens = null;
        oldCamera = null;
        oldBounds.put();
        cameras = null;
        super.close();
    }
}