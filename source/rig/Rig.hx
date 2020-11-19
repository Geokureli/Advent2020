package rig;


import rig.RigData.Skin;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import props.Player;

import openfl.utils.Assets;

class Rig implements IFlxDestroyable
{
    inline static var FLIPX_OFFSET = 2;
    
    public var rigData(default, null):RigData = null;
    public var curAnim(default, null):RigAnimation = null;
    public var frameRate(default, set):Float;
    public var delay(default, null) = 0.0;
    public var curFrame(default, null) = 0;
    public var numFrames(default, null) = 0;
    public var finishCallback:String->Void;
    public var pixelPerfectSnapInterval = 1;
    public var scale = 1.0;
    
    public var paused = false;
    public var finished(default, null) = true;
    public var looping(default, null) = true;
    public var flipX(default, set) = false;
    
    var limbs = new Map<Limb, LimbSprite>();
    var limbsGroup = new FlxTypedGroup<LimbSprite>();
    var skins = new Map<Limb, Skin>();
    
    var timer = 0.0;
    
    public function new ()
    {
        if (RigData.instance == null)
            RigData.instance = new RigData();
        
        rigData = RigData.instance;
        frameRate = RigData.FPS;
        
        var limbNames = Limb.getAll();
        // add back to front for z ordering
        limbNames.reverse();
        for (limb in limbNames)
        {
            skins[limb] = rigData.skinLists[limb]["default"];
            var sprite = new LimbSprite();
            sprite.applySkin(skins[limb]);
            limbs[limb] = sprite;
            limbsGroup.add(sprite);
        }
        
        play("idle");
    }
    
    public function setSkin(limb:Limb, skinName:String)
    {
        if (!rigData.skinLists[limb].exists(skinName))
            throw 'invalid skin:$skinName for limb:$limb';
        
        skins[limb] = rigData.skinLists[limb][skinName];
        limbs[limb].applySkin(skins[limb]);
    }
    
    public function getSkinList(limb:Limb)
    {
        return rigData.skinLists[limb];
    }
    
    public function update(elapsed:Float)
    {
        if (delay == 0 || finished || paused)
            return;
        
        timer += elapsed;
        while (timer > delay && !finished)
        {
            timer -= delay;
            
            if (curFrame == numFrames - 1)
            {
                if (looping)
                    curFrame = 0;
                else
                {
                    finished = true;
                    if (finishCallback != null)
                        finishCallback(curAnim.name);
                }
            }
            else
                curFrame++;
                
        }
        
        redrawFrame();
    }
    
    public function redrawFrame()
    {
        var frame = curAnim.frames[curFrame];
        for (limb=>limbSprite in limbs)
        {
            limbSprite.x = frame[limb].x * (flipX ? -1 : 1) * scale;
            limbSprite.y = frame[limb].y * scale;
            limbSprite.scale.x = frame[limb].xScale * scale;
            limbSprite.scale.y = frame[limb].yScale * scale;
            limbSprite.angle = (frame[limb].rotation + skins[limb].rotation) * (flipX ? -1 : 1);
            limbSprite.flipX = flipX;
            limbSprite.offset.x = flipX ? limbSprite.width + skins[limb].x : -skins[limb].x;
        }
    }
    
    public function drawTo(player:Player)
    {
        var oldPos = FlxPoint.get();
        for (limb in limbsGroup.members)
        {
            limb.getPosition(oldPos);
            limb.x += player.x - player.offset.x + (flipX ? FLIPX_OFFSET : 0);
            limb.y += player.y - player.offset.y;
            if (pixelPerfectSnapInterval > 0)
            {
                limb.x = Math.round(limb.x * pixelPerfectSnapInterval) / pixelPerfectSnapInterval;
                limb.y = Math.round(limb.y * pixelPerfectSnapInterval) / pixelPerfectSnapInterval;
            }
            limb.draw();
            limb.x = oldPos.x;
            limb.y = oldPos.y;
        }
        oldPos.put();
    }
    
    public function play(anim:String, force:Bool = false, frame = 0)
    {
        if (!rigData.animations.exists(anim))
            throw 'invalid anim: $anim';
        
        if (curAnim != null && curAnim.name == anim && !force)
            return;
        
        curAnim = rigData.animations[anim];
        curFrame = frame;
        numFrames = curAnim.frames.length;
        finished = false;
        looping = curAnim.loops;
        timer = 0;
    }
    
    function set_frameRate(value:Float):Float
    {
        delay = 0;
        frameRate = value;
        if (value > 0)
            delay = 1.0 / value;
        return value;
    }
    
    function set_flipX(value:Bool)
    {
        this.flipX = value;
        redrawFrame();
        return value;
    }
    
    public function destroy():Void
    {
        rigData = null;
        curAnim = null;
    }
}

@:forward
abstract LimbSprite(FlxSprite) to FlxSprite
{
    inline static var DRAW_DEBUG = false;
    
    public function new (x = 0.0, y = 0.0, ?graphic)
    {
        this = new FlxSprite(x, y, graphic);
    }
    
    public function applySkin(skin:Skin)
    {
        var graphic = FlxG.bitmap.get(skin.symbol);
        if (graphic == null)
            graphic = FlxG.bitmap.add(Assets.getBitmapData(skin.symbol), false, skin.symbol);
        this.loadGraphic(skin.symbol);
        this.offset.x = -skin.x;
        this.offset.y = -skin.y;
        this.origin.copyFrom(this.offset);
        this.angle = skin.rotation;
        #if debug
        this.ignoreDrawDebug = !DRAW_DEBUG;
        #end
    }
}