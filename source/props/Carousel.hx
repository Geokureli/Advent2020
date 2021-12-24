package props;

import states.OgmoState;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;

typedef CarouselValues = { folder:String, files:String, secondsPerSlide:Float };
class Carousel extends FlxSpriteGroup
{
    var slides = new FlxTypedGroup<FlxSprite>();
    var secondsPerSlide:Float;
    var transitionTime:Float;
    var timer:Float;
    var moving = false;
    var currentSlide = 0;
    
    public function new (x = 0, y = 0, files:Array<FlxGraphicAsset>, secondsPerSlide = 5.0, transitionTime = 0.25)
    {
        this.secondsPerSlide = 1.0;//secondsPerSlide;
        this.transitionTime = transitionTime;
        timer = this.secondsPerSlide;
        super(x, y);
        
        var width = 0;
        var height = 0;
        for (i=>file in files)
        {
            var slide = add(new FlxSprite(file));
            slides.add(slide);
            if (i == 0)
            {
                width = slide.frameWidth;
                height = slide.frameHeight;
            }
            else if (width != slide.frameWidth || height != slide.frameHeight)
                throw "all files must be the same size";
            
            slide.x = x + i * width;
            slide.clipRect = FlxRect.get(x - slide.x, 0, width, height);
        }
        
        if (slides.length == 0)
        {
            exists = false;
            trace("No files listed in the Carousel");
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (slides.length == 1)
            return;
        
        if (moving == false && timer > 0)
        {
            timer -= elapsed;
            if (timer <= 0)
            {
                moving = true;
                timer = transitionTime;
            }
            return;
        }
        
        timer -= elapsed;
        var t = 1.0 - FlxEase.cubeInOut(Math.max(0, timer) / transitionTime);
        // trace(timer, t);
        for (i=>slide in slides.members)
        {
            var pos = (i - currentSlide + slides.length) % slides.length;
            slide.x = x + (pos * slide.frameWidth) - Std.int(slide.frameWidth * t);
            // trace(currentSlide, i, pos, pos * slide.frameWidth, Std.int(slide.frameWidth * t));
            slide.clipRect.x = x - slide.x;
            slide.clipRect = slide.clipRect;
        }
        
        if (timer <= 0)
        {
            var slide = slides.members[currentSlide];
            slide.x += slides.length * slide.frameWidth;
            moving = false;
            timer = secondsPerSlide;
            currentSlide = (++currentSlide) % slides.length;
        }
    }
    
    static public function fromEntity(data:OgmoEntityData<CarouselValues>)
    {
        var files = data.values.files != "" && data.values.files != null
            ? data.values.files.split(",").map(file->data.values.folder + file + ".png")
            : [];
        return new Carousel(data.x, data.y, files, data.values.secondsPerSlide);
    }
}