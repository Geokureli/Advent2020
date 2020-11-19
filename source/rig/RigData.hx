package rig;

import openfl.utils.Assets;
import openfl.display.MovieClip;

@:allow(rig.Rig)
class RigData
{
    inline static public var FPS = 12;
    inline static public var SCALE = 1;
    
    static var instance(default, null):RigData = null;
    
    var skinLists:Map<Limb, Map<String, Skin>>;
    var animations:Map<String, RigAnimation>;
    
    var totalFrames:Int;
    
    function new()
    {
        var movieClip = Assets.getMovieClip("Animations:Animations");
        movieClip.stopAllMovieClips();
        totalFrames = movieClip.totalFrames;
        
        skinLists = parseSkins();
        animations = parseAnimations(movieClip);
    }
    
    function parseSkins()
    {
        var skinLists = new Map<Limb, Map<String, Skin>>();
        for (limb in Limb.getAll())
        {
            var mc = Assets.getMovieClip('Animations:$limb');
            mc.gotoAndStop(0);
            
            var skinList = new Map<String, Skin>();
            for (i in 0...mc.totalFrames)
            {
                final name = mc.currentFrameLabel;
                var symbol = toTitleCase(name);
                if (bitmapExists('Animations:${limb}_$symbol'))
                    symbol = 'Animations:${limb}_$symbol';
                else
                {
                    // shared leg asset
                    if (limb.isLeg() && bitmapExists('Animations:Leg_$symbol'))
                        symbol = 'Animations:Leg_$symbol';
                    // shared arm asset
                    else if (limb.isArm() && bitmapExists('Animations:Arm_$symbol'))
                        symbol = 'Animations:Arm_$symbol';
                    else
                        throw 'Could not find symbol:$symbol for limb:$limb';
                }
                
                final graphic = mc.getChildAt(0);
                if (!skinList.exists(name))
                    skinList[name] = { x:graphic.x, y:graphic.y, rotation:graphic.rotation, symbol:symbol };
                mc.nextFrame();
            }
            skinLists[limb] = skinList;
        }
        return skinLists;
    }
    
    inline function bitmapExists(symbol:String):Bool
    {
        return Assets.exists(symbol, IMAGE);
    }
    
    function parseAnimations(movieClip:MovieClip)
    {
        var animations = new Map<String, RigAnimation>();
        var anim:RigAnimation = null;
        
        for (i in 0...movieClip.totalFrames)
        {
            var label = movieClip.currentFrameLabel;
            if (label != null)
            {
                // end previous animation
                if (anim != null && anim.name != label)
                    anim.end = i - 1;
                
                // start new animation
                anim = new RigAnimation(label, i);
                if (!StringTools.endsWith(label, "_unused"))
                    animations[anim.name] = anim;
            }
            
            try
            {
                anim.pushFrameFrom(movieClip);
            }
            catch(error:String)
                throw error + "frame: " + (i + 1);
            
            // end last animation
            if (i + 1 == movieClip.totalFrames)
                anim.end = i;
            
            movieClip.nextFrame();
        }
        
        return animations;
    }
    
    @:pure
    inline function toTitleCase(str:String)
    {
        return str.charAt(0).toUpperCase() + str.substr(1);
    }
}

typedef Skin =
{
    x:Float,
    y:Float,
    rotation:Float,
    symbol:String
}
