package ui;

import data.Content;
import openfl.Lib;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import openfl.utils.Assets;

import io.newgrounds.NG;
import io.newgrounds.objects.Medal;

import data.Calendar;
import data.NGio;

import flixel.FlxG;
import flixel.FlxSprite;

class MedalPopup extends flixel.group.FlxSpriteGroup
{
    inline static var MEDAL_0 = NGio.DAY_MEDAL_0;
    inline static var TEST_MEDAL = MEDAL_0;
    inline static var BOX_PATH = "assets/images/ui/medal/medalAnim.png";
    inline static var MEDAL_PATH = "assets/images/ui/medal/medalSlide.png";
    
    static var instance(default, null):MedalPopup;
    
    var animQueue = new Array<Medal>();
    var medalRects = new Array<Rectangle>();
    var box:FlxSprite;
    var medalGuide:FlxSprite;
    var medal:FlxSprite;
    
    function new()
    {
        super();
        
        x = FlxG.width - 65;
        y = FlxG.height - 79;
        visible = false;
        
        add(medalGuide = new FlxSprite(0, 0).loadGraphic(MEDAL_PATH, true, 97, 79));
        medalGuide.animation.add("anim", [0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,3,4,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,8,9,0], 10, false);
        medalGuide.animation.play("anim");
        medalGuide.animation.finish();
        var medalBmd = medalGuide.graphic.bitmap;
        var frameBmd = new BitmapData(97, 79);
        final numFrames = Std.int(medalBmd.width/frameBmd.width);
        var sourceRect = new Rectangle(0, 0, frameBmd.width, frameBmd.height);
        var point = new Point();
        for (i in 0...numFrames)
        {
            frameBmd.fillRect(frameBmd.rect, 0);
            frameBmd.copyPixels(medalBmd, sourceRect, point);
            final rect = frameBmd.getColorBoundsRect(0xFF000000, 0x0, false);
            medalRects.push(rect);
            sourceRect.x += sourceRect.width;
        }
        
        add(medal = new FlxSprite()).visible = false;
        
        add(box = new FlxSprite().loadGraphic(BOX_PATH, true, 65, 79));
        box.animation.add("anim", [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,16,16,17,18,19,20,21,22,23,24], 10, false);
        box.animation.play("anim");
        box.animation.finish();
        
        scrollFactor.set(); 
        if (NGio.isLoggedIn)
        {
            if (NG.core.medals != null)
                medalsLoaded();
            else
                NG.core.onMedalsLoaded.add(medalsLoaded);
        }
    }
    
    function medalsLoaded():Void
    {
        for (medal in NG.core.medals)
        {
            if(!medal.unlocked #if debug || true #end)
                medal.onUnlock.add(onMedalUnlock.bind(medal));
        }
    }
    
    function onMedalUnlock(medal:Medal):Void
    {
        // if (!enabled)
        //     return;
        
        animQueue.push(medal);
        
        if (!visible)
            playNextAnim();
    }
    
    function playDebugAnim():Void
    {
        onMedalUnlock(NG.core.medals.get(MEDAL_0 + Calendar.day));
    }
    
    function playNextAnim():Void {
        
        if (animQueue.length == 0)
            return;
        
        var medalData = animQueue.shift();
        
        if (Content.medalsById.exists(medalData.id))
            medal.loadGraphic('assets/images/medals/${Content.medalsById[medalData.id]}.png');
        else
        { 
            var medalNum = medalData.id - MEDAL_0 + 1;
            if (Content.artworkByDay.exists(medalNum))
                medal.loadGraphic(Content.artworkByDay[medalNum].medalPath);
        }
        
        visible = true;
        box.visible = true;
        box.animation.play("anim", true);
        box.animation.finishCallback = (_)->box.visible = false;
        
        medal.visible = medalGuide.visible = false;
        medalGuide.animation.play("anim", true);
        medalGuide.animation.finishCallback = (_)->onAnimComplete();
    }
    
    function onAnimComplete():Void {
        
        visible = false;
        medal.visible = false;
        playNextAnim();
    }
    
    override function update(elapsed:Float)
    {
        final anim = medalGuide.animation.curAnim;
        var prevMedalFrame = anim.frames[anim.curFrame];
        
        super.update(elapsed);
        if (visible)
        {
            final frame = anim.frames[anim.curFrame];
            medal.visible = medalGuide.visible = frame > 0;
            if (prevMedalFrame != frame)
            {
                final rect = medalRects[frame];
                medal.x = x + rect.x;
                medal.y = y + rect.y;
                medal.scale.x = rect.width / medal.frameWidth;
                medal.scale.y = rect.height / medal.frameHeight;
                medal.updateHitbox();
            }
        }
        
        #if debug
        if (FlxG.keys.justPressed.ENTER)
            playDebugAnim();
        #end
    }
    
    override function destroy()
    {
        // super.destroy();
    }
    
    static public function getInstance()
    {
        if (instance == null)
            instance = new MedalPopup();
        return instance;
    }
}