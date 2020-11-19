package utils;

import flixel.FlxCamera;
import flixel.FlxG;

class GameSize
{
    public static var pixelSize(get, null) = 0;
    static function get_pixelSize():Int
    {
        if (pixelSize == 0)
            pixelSize = Std.int(FlxG.stage.stageWidth / FlxG.game.width);
        
        return GameSize.pixelSize;
    }
    
    public static function setPixelSize(pixelSize:Int)
    {
        if (pixelSize < 1)
            throw ("Cannot set pixel size to " + pixelSize);
        
        if (pixelSize == GameSize.pixelSize)
            return;
        
        GameSize.pixelSize = pixelSize;
        final stageWidth = FlxG.stage.stageWidth;
        final stageHeight = FlxG.stage.stageHeight;
        
        if (stageWidth % pixelSize != 0 || stageHeight % pixelSize != 0)
            throw "window width/height must be a multiple of pixelSize";
        
        final width = Std.int(FlxG.stage.stageWidth / pixelSize);
        final height = Std.int(FlxG.stage.stageHeight / pixelSize);
        // trace('resizing: $width, $height');
        
        @:privateAccess
        FlxG.initialWidth = width;
        @:privateAccess
        FlxG.initialHeight = height;
        
        FlxG.resizeGame(width, height);
        @:privateAccess
        FlxG.game.scaleX = FlxG.game.scaleY = pixelSize;
        @:privateAccess
        var focusLostScreen = FlxG.game._focusLostScreen;
        focusLostScreen.width = width;
        focusLostScreen.height = height;
        var scaleX = focusLostScreen.scaleX;
        var scaleY = focusLostScreen.scaleY;
        @:privateAccess
        var cursor = FlxG.mouse._cursor;
        cursor.scaleX = scaleX;
        cursor.scaleY = scaleY;
        #if FLX_DEBUG
        var debugger = FlxG.game.debugger;
        debugger.scaleX = scaleX;
        debugger.scaleY = scaleY;
        #end
        
        
        for (camera in FlxG.cameras.list)
        {
            camera.width = width;
            camera.height = height;
            @:privateAccess
            camera.updateScrollRect();
            
            if (camera.target != null)
                updateDeadzone(camera);
            
            // @:privateAccess
            // camera.totalScaleX = camera.canvas.scaleX * pixelSize;
            // @:privateAccess
            // camera.totalScaleY = camera.canvas.scaleY * pixelSize;
            
            // @:privateAccess
            // trace(camera.totalScaleX, camera.totalScaleY, camera.canvas.scaleX, camera.canvas.scaleY);
        }
    }
    
    /** Copied from FlxCamera.follow */
    static function updateDeadzone(camera:FlxCamera)
    {
        final deadzone = camera.deadzone;
        if (deadzone == null)
            return;
        
        final target = camera.target;
        final width = camera.width;
        final height = camera.height;
        
        switch (camera.style)
        {
            case LOCKON:
                var w = target.width;
                var h = target.height;
                deadzone.set((width - w) / 2, (height - h) / 2 - h / 4, w, h);
                
            case PLATFORMER:
                var w = target.width;
                var h = target.height;
                deadzone.set((width - w) / 2, (height - h) / 2 - h / 4, w, h);
                
            case TOPDOWN:
                var size = Math.max(width, height) / 4;
                deadzone.set((width - size) / 2, (height - size) / 2, size, size);
                
            case TOPDOWN_TIGHT:
                var size = Math.max(width, height) / 8;
                deadzone.set((width - size) / 2, (height - size) / 2, size, size);
                
            case SCREEN_BY_SCREEN:
                deadzone.set(0, 0, width, height);
                
            case NO_DEAD_ZONE:
        }
    }
}