package props;

import Types;
import data.Game;
import data.PlayerSettings;
import data.Skins;
import states.rooms.RoomState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.text.FlxBitmapText;
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
    
    public var state = new PlayerState();
    public var netState:PlayerNetState = Joining;
    public var usePaths = false;
    public var drawPath = false;
    public var justEmoted(default, null) = false;
    public var emote(default, null) = new Emote();
    public var enabled = true;
    public var name(default, null):String;
    
    var nameText:FlxBitmapText;
    var nameColor = 0xFF000000;
    var nameShadowColor = 0xFFffffff;
    var targetPos:FlxPoint;
    var movePath:Array<FlxPoint>;
    var bobTimer = 0.0;
    var skinOffset = FlxPoint.get();
    
    public function new(x = 0.0, y = 0.0, name, settings:PlayerSettings)
    {
        nameText = new FlxBitmapText();
        nameText.alignment = CENTER;
        if (Game.room.name == Village)
        {
            nameColor = 0xFFffffff;
            nameShadowColor = 0xFF000000;
        }
        #if FLX_DEBUG
        nameText.ignoreDrawDebug = true;
        #end
        
        this.settings = settings;
        super(x, y);
        
        settings.applyTo(this);
        updateNameText(name);
        
        #if FLX_DEBUG
        pathTile.ignoreDrawDebug = true;
        hitbox.ignoreDrawDebug = true;
        #end
    }
    
    override function initVars():Void
    {
        super.initVars();
        
        maxVelocity.set(MAX_SPEED, MAX_SPEED);
        drag.set(MAX_SPEED / ACCEL_TIME, MAX_SPEED / ACCEL_TIME);
        hitbox = new FlxObject();
        
        if (pathTile.graphic == null || pathTile.graphic.width == 0)
        {
            pathTile.makeGraphic(8, 8);
            final bitmap = pathTile.graphic.bitmap;
            final rect = bitmap.rect.clone();
            rect.x += 2;
            rect.y += 2;
            rect.width -= rect.x;
            rect.height -= rect.y;
            bitmap.fillRect(rect, 0xFF000000);
            pathTile.offset.copyFrom(pathTile.origin);
        }
    }
    
    
    public function updateNameText(name:String)
    {
        nameText.text = name == null ? "" : name;
        nameText.visible = name != null;
        this.name = name;
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
        offset.y += skinOffset.y;
        
        super.update(elapsed);
        if (emote.exists && emote.active)
            emote.update(elapsed);
        
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
        final margin = (hitbox.width - width) / 2;
        hitbox.setPosition(x - margin, y + height + margin - hitbox.height - 4);
        
        #if debug
        final keys = FlxG.keys;
        if (keys.justPressed.L && (keys.pressed.SHIFT || isMouseOver()))
        {
            drawPath = !drawPath;
            alpha = drawPath ? 0.75 : 1;
        }
        #end
    }
    
    inline function isMouseOver()
    {
        return hitbox.overlapsPoint(FlxG.mouse.getWorldPosition(FlxPoint.weak()));
    }
    
    function updateMovement(pressU:Bool, pressD:Bool, pressL:Bool, pressR:Bool, pressB:Bool, pressMouse:Bool)
    {
        if (!enabled)
        {
            velocity.set(0, 0);
            acceleration.set(0, 0);
            return;
        }
        
        if (pressR || pressL || pressU || pressD || pressB)
        {
            cancelTargetPos();
        }
        
        if (pressMouse)
            setTargetPos(FlxG.mouse.getWorldPosition(FlxPoint.weak()).subtract(width / 2, height / 2));
        
        justEmoted = false;
        if (pressB && emote.type == None)
        {
            justEmoted = true;
            emote.animate(Smooch);
        }
        
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
            
            final canMove = emote.type == None;
            pressR = canMove && x - nextPos.x < -slideX;
            pressL = canMove && x - nextPos.x >  slideX;
            pressD = canMove && y - nextPos.y < -slideY;
            pressU = canMove && y - nextPos.y >  slideY;
            nextPos.putWeak();
        }
        
        acceleration.x = ((pressR ? 1 : 0) - (pressL ? 1 : 0)) * ACCEL_SPEED;
        acceleration.y = ((pressD ? 1 : 0) - (pressU ? 1 : 0)) * ACCEL_SPEED;
        
        if (velocity.x != 0)
        {
            flipX = velocity.x > 0;
            offset.x = (frameWidth - width) / 2 + (flipX ? -skinOffset.x : skinOffset.x);
        }
        else flipX = state.flipped;
        
        if (targetPos != null && velocity.x == 0 && velocity.y == 0 && acceleration.x == 0 && acceleration.y == 0)
            targetPosReached();
    }
    
    override function draw()
    {
        if (drawPath)
        {
            if (movePath != null)
            {
                final len = movePath.length;
                for (i=>pos in movePath)
                {
                    pathTile.x = pos.x;
                    pathTile.y = pos.y;
                    pathTile.alpha = (len - i) / len;
                    pathTile.draw();
                }
            }
            else if (targetPos != null)
            {
                pathTile.x = targetPos.x;
                pathTile.y = targetPos.y;
                pathTile.alpha = 1;
                pathTile.draw();
            }
        }
        
        super.draw();
        
        hitbox.draw();
        if (emote.exists && emote.visible)
        {
            emote.x = x;
            emote.y = y;
            emote.draw();
        }
        
        if (nameText.visible)
        {
            // draw shadow
            nameText.color = nameColor;
            nameText.alpha = alpha;
            nameText.x = x + 1 + (width - nameText.width) / 2;
            nameText.y = y + 1 + height - frameHeight - nameText.height - 16;
            nameText.draw();
            nameText.color = nameShadowColor;
            nameText.x--;
            nameText.y--;
            nameText.draw();
        }
    }
    
    override function destroy()
    {
        super.destroy();
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
        final end = newPos.copyTo();
        if (targetPos == null || map.getTileIndexByCoords(end) != map.getTileIndexByCoords(targetPos))
        {
            if (targetPos == null)
                targetPos = FlxPoint.get();
            targetPos.copyFrom(newPos);
            movePath = map.findPath(start, end, false, WIDE);
            // remove the first node, this is a lazy fix to prevent them from
            // sometimes going backwards at the start of a new path
            if (movePath != null)
            {
                if (movePath.length == 1)
                    movePath = null;
                else if (movePath.length > 1)
                    movePath.shift();
            }
            
            solid = movePath == null;
        }
        start.put();
        end.put();
    }
    
    function targetPosReached()
    {
        cancelTargetPos();
    }
    
    public function cancelTargetPos()
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
        width = 8;
        height = 8;
        origin.y = 16;
        offset.x = (frameWidth - width) / 2;
        offset.y = frameHeight - height;
        skinOffset.set(0, 0);
        if (data.offset != null)
        {
            skinOffset.set(data.offset.x, data.offset.y);
            offset.addPoint(skinOffset);
        }
        hitbox.width  = width  + 12;
        hitbox.height = height + 14;
    }
    #end
}

class Emote extends FlxSprite
{
    inline static var SMOOCH_PATH = "assets/images/emotes/heart.png";
    inline static var SMOOCH_FRAMES = 13;
    inline static var SMOOCH_FPS = 10;
    
    public var type(default, null) = None;
    
    public function new()
    {
        super();
        visible = false;
    }
    
    public function animate(type:EmoteType)
    {
        this.type = type;
        
        inline function calcOffset(x = 0.0, y = 0.0)
        {
            return FlxPoint.weak(width / 2 + x, y);
        }
        
        switch(type)
        {
            case Smooch: load(SMOOCH_PATH, SMOOCH_FRAMES, SMOOCH_FPS, calcOffset());
            case None:
                animation.finishCallback = null;
                visible = false;
        }
    }
    
    inline function load(path:String, frames:Int, fps:Int, ?offset:FlxPoint)
    {
        visible = true;
        loadGraphic(path);
        loadGraphic(path, true, Std.int(frameWidth / frames), frameHeight);
        
        if (offset != null)
            offset = FlxPoint.weak();
        this.offset.copyFrom(offset);
        this.offset.x += frameWidth / 2;
        this.offset.y += frameHeight;
        
        animation.add("anim", [for (i in 0...fps) i], fps, false);
        animation.add("anim", [for (i in 0...fps) i], fps, false);
        animation.play("anim");
        animation.finishCallback = onAnimComplete;
    }
    
    function onAnimComplete(animName:String)
    {
        animation.callback = null;
        animate(None);
    }
}