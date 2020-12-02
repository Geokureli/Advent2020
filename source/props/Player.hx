package props;

import flixel.math.FlxVector;
import flixel.math.FlxMath;
import Types;
import data.PlayerSettings;
import data.Skins;
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
    inline static public var MAX_SPEED = 125;
    inline static public var BOB = 3;
    inline static public var BOB_PERIOD = 0.25;
    inline static public var ACCEL_SPEED = MAX_SPEED / ACCEL_TIME;
    
    static var pathTile = new FlxSprite();
    
    public var settings(default, null):PlayerSettings;
    public var hitbox(default, null):FlxObject;
    
    public var state:PlayerState = Joining;
    public var usePaths = false;
    public var drawPath = false;
    
    var targetPos:FlxPoint;
    var movePath:Array<FlxPoint>;
    var bobTimer = 0.0;
    
    public function new(x = 0.0, y = 0.0, settings:PlayerSettings)
    {
        this.settings = settings;
        super(x, y);
        
        settings.applyTo(this);
    }
    
    override function initVars():Void
    {
        super.initVars();
        
        maxVelocity.set(MAX_SPEED, MAX_SPEED);
        drag.set(MAX_SPEED / ACCEL_TIME, MAX_SPEED / ACCEL_TIME);
        hitbox = new FlxObject();
        
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
        // BOB SHIT
        var oldV = velocity.copyTo();
        if (velocity.x != 0 || velocity.y != 0)
        {
            bobTimer += elapsed;
            var bobTime = Math.max(0, FlxMath.fastSin(bobTimer / BOB_PERIOD * Math.PI));
            offset.y = frameHeight - height + bobTime * BOB;
            velocity.scale(0.25 + 1 * bobTime);
        }
        else
        {
            bobTimer = bobTimer % BOB_PERIOD;
            if (bobTimer > BOB_PERIOD / 2)
                bobTimer = 0;
            if (bobTimer > BOB_PERIOD / 4)
                bobTimer = BOB_PERIOD / 4 - bobTimer;
            bobTimer = Math.max(0, bobTimer - elapsed);
            var bobTime = Math.max(0, FlxMath.fastSin(bobTimer / BOB_PERIOD * Math.PI));
            offset.y = frameHeight - height + bobTime * BOB;
        }
        
        super.update(elapsed);
        velocity.copyFrom(oldV);
        oldV.put();
        var last = FlxPoint.get(x, y);
        oldV.set(x, y);
        updateMotion(elapsed);
        x = oldV.x;
        y = oldV.y;
        last.put();
        // BOB SHIT END
        
        var v:FlxVector = velocity;
        if (v.lengthSquared > MAX_SPEED * MAX_SPEED)
            v.length = MAX_SPEED;
        
        hitbox.update(elapsed);
        hitbox.setPosition(x + (width - hitbox.width) / 2, y + height - (frameHeight + 1) * scale.y);
        
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
        
        #if USE_RIG
        if (rig.visible)
            rig.drawTo(this);
        #end
        
        hitbox.draw();
    }
    
    override function destroy()
    {
        super.destroy();
        
        #if USE_RIG rig = FlxDestroyUtil.destroy(rig); #end
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
    
    #if USE_RIG
    override function set_flipX(value:Bool):Bool
    {
        return super.flipX = rig.flipX = value;
    }
    #else
    public function setSkin(skin:Int)
    {
        var data = Skins.getData(skin);
        data.loadTo(this);
        scale.set(2, 2);
        width = 16;
        height = 16;
        origin.y = 16;
        offset.x = (frameWidth - width) / 2;
        offset.y = frameHeight - height;
        hitbox.width = (frameWidth - 2) * scale.x;
        hitbox.height = (frameHeight + 2) * scale.y;
    }
    #end
}