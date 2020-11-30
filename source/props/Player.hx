package props;

import Types;
import data.PlayerSettings;
import states.rooms.RoomState;
import rig.Rig;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class Player extends flixel.FlxSprite
{
    inline static public var ACCEL_TIME = 0.2;
    inline static public var MAX_SPEED = 50;
    inline static public var ACCEL_SPEED = MAX_SPEED / ACCEL_TIME;
    
    static var pathTile = new FlxSprite();
    
    public var settings(default, null):PlayerSettings;
    public var rig(default, null):Rig;
    public var hitbox(default, null):FlxObject;
    
    public var state:PlayerState = Joining;
    public var usePaths = false;
    public var drawPath = false;
    
    var targetPos:FlxPoint;
    var movePath:Array<FlxPoint>;
    
    public function new(x = 0.0, y = 0.0, settings:PlayerSettings)
    {
        this.settings = settings;
        super(x, y);
        
        settings.applyTo(this);
    }
    
    override function initVars():Void
    {
        super.initVars();
        
        makeGraphic(1, 1, 0);
        width = 8;
        height = 8;
        hitbox = new FlxObject(0, 0, width + 6, height + 16);
        rig = new Rig();
        offset.set(-3, 11);
        
        maxVelocity.set(MAX_SPEED, MAX_SPEED);
        drag.set(MAX_SPEED / ACCEL_TIME, MAX_SPEED / ACCEL_TIME);
        
        if (pathTile.graphic == null || pathTile.graphic.width == 0)
        {
            pathTile.makeGraphic(32, 32);
            final bitmap = pathTile.graphic.bitmap;
            final rect = bitmap.rect.clone();
            rect.x += 4;
            rect.y += 4;
            rect.width -= rect.x * 2;
            rect.height -= rect.y * 2;
            bitmap.fillRect(rect, 0x0);
            pathTile.offset.copyFrom(pathTile.origin);
        }
    }
    
    override function update(elapsed:Float)
    {
        // must be before update, anfter collision
        if (x != last.x || y != last.y)
            rig.play("walk");
        else
            rig.play("idle");
        
        super.update(elapsed);
        
        rig.update(elapsed);
        hitbox.update(elapsed);
        hitbox.setPosition(x + (width - hitbox.width) / 2, y + height - hitbox.height);
        
        #if debug
        if (FlxG.keys.justPressed.L && overlapsPoint(FlxG.mouse.getWorldPosition(FlxPoint.weak())))
        {
            drawPath = !drawPath;
            // this.alpha = drawPath ? 0.75 : 1;
        }
        #end
    }
    
    function updateMovement(pressU:Bool, pressD:Bool, pressL:Bool, pressR:Bool, pressMouse:Bool)
    {
        if (pressR || pressL || pressU || pressD)
        {
            cancelTargetPos();
        }
        else
        {
            if (pressMouse)
                setTargetPos(FlxG.mouse.getWorldPosition(FlxPoint.weak()).subtract(width / 2, height / 2));
            
            var nextPos = targetPos;
            if (movePath != null)
            {
                final map = (cast FlxG.state:RoomState).geom;
                final index = map.getTileIndexByCoords(FlxPoint.weak(x + width / 2, y + height / 2));
                // final index = map.getTileIndexByCoords(FlxPoint.weak(x, y));
                
                while(movePath.length > 1 && map.getTileIndexByCoords(movePath[0]) == index)
                    movePath.shift();//.put();
                
                nextPos = FlxPoint.weak().copyFrom(movePath[0]).subtract(width / 2, height / 2);
            }
            
            if (nextPos != null)
            {
                final vx = Math.abs(velocity.x);
                final vy = Math.abs(velocity.y);
                final slideX = Math.max(1, (vx / 2) * (vx / drag.x));
                final slideY = Math.max(1, (vy / 2) * (vy / drag.y));
                
                pressR = x - nextPos.x < -slideX;
                pressL = x - nextPos.x >  slideX;
                pressD = y - nextPos.y < -slideY;
                pressU = y - nextPos.y >  slideY;
                nextPos.putWeak();
            }
        }
        
        acceleration.x = ((pressR ? 1 : 0) - (pressL ? 1 : 0)) * ACCEL_SPEED;
        acceleration.y = ((pressD ? 1 : 0) - (pressU ? 1 : 0)) * ACCEL_SPEED;
        
        if (velocity.x != 0)
            flipX = velocity.x > 0;
    }
    
    override function draw()
    {
        super.draw();
        
        if (rig.visible)
            rig.drawTo(this);
        
        hitbox.draw();
    }
    
    override function destroy()
    {
        super.destroy();
        
        rig = FlxDestroyUtil.destroy(rig);
        offset = FlxDestroyUtil.put(offset);
        // scale = FlxDestroyUtil.put(scale);
    }
    public function setTargetPos(newPos:FlxPoint)
    {
        if (usePaths)
            calcNewPath(newPos);
        else
        {
            if (movePath != null)
            {
                solid = true;
                movePath = null;
            }
            
            if (targetPos == null)
                targetPos = FlxPoint.get();
            targetPos.copyFrom(newPos);
        }
        
        newPos.putWeak();
    }
    
    function calcNewPath(newPos:FlxPoint)
    {
        final map = (cast FlxG.state:RoomState).geom;
        final start = FlxPoint.get(x, y);
        final end = FlxPoint.get(newPos.x, newPos.y);
        if (targetPos == null || map.getTileIndexByCoords(end) != map.getTileIndexByCoords(targetPos))
        {
            if (targetPos == null)
                targetPos = FlxPoint.get();
            targetPos.copyFrom(newPos);
            movePath = map.findPath(start, end, false, WIDE);
            solid = movePath == null;
        }
        start.put();
        end.put();
    }
    
    function cancelTargetPos()
    {
        targetPos = null;
        movePath = null;
        solid = true;
    }
    
    override function set_flipX(value:Bool):Bool
    {
        return super.flipX = rig.flipX = value;
    }
}