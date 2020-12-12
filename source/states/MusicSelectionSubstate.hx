package states;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.Calendar;
import data.Content;
import data.Manifest;
import ui.Controls;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;

class MusicSelectionSubstate extends flixel.FlxSubState
{
    var carousel:Carousel;
    // prevents instant selection
    var wasAReleased = false;
    
    override function create()
    {
        super.create();
        
        cameras = [new FlxCamera()];
        // camera.zoom = 2;
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera);
        
        carousel = new Carousel();
        carousel.screenCenter(XY);
        
        final border = 60;
        var boxMiddle = new FlxSprite(0, carousel.y);
        boxMiddle.makeGraphic(FlxG.width, Std.int(carousel.height) + border, 0xFF555555);
        add(boxMiddle);
        add(carousel);
        
        var boxAbove = new FlxSprite(0, carousel.y - border);
        boxAbove.makeGraphic(FlxG.width, border, 0xFF555555);
        add(boxAbove);
        var boxbelow = new FlxSprite(0, carousel.y + carousel.height);
        boxbelow.makeGraphic(FlxG.width, border, 0xFF555555);
        add(boxbelow);
    }
    
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (carousel.selecting)
            return;
        
        if (!wasAReleased && Controls.released.A)
            wasAReleased = true;
        
        if (Controls.justPressed.RIGHT)
            carousel.toNext();
        if (Controls.justPressed.LEFT)
            carousel.toPrev();
        if (Controls.justPressed.A && wasAReleased)
            carousel.select(onSelectComplete);
        if (Controls.justPressed.B)
        {
            if (carousel.playingIndex > -1)
                Manifest.playMusic(Content.songsOrdered[carousel.playingIndex].id);
            close();
        }
    }
    
    function onSelectComplete(song:SongCreation)
    {
        Manifest.playMusic(song.id);
        close();
    }
}

class Carousel extends FlxSpriteGroup
{
    static inline var SPACING = 10;
    static inline var SIDE_GAP = 20;
    static inline var BACK_PATH = "assets/images/ui/carousel/back.png";
    static inline var DISK_SIDE_PATH = "assets/images/ui/carousel/disk_side.png";
    static inline var DISK_FRONT_PATH = "assets/images/ui/carousel/disk_front.png";
    static inline var SLOT_PATH = "assets/images/ui/carousel/slot.png";
    static inline var FRONT_PATH = "assets/images/ui/carousel/front.png";
    
    public var selecting = false;
    public var playingIndex(default, null) = -1;
    
    var back:FlxSprite;
    var disks = new FlxTypedSpriteGroup<FlxSprite>();
    var disk:FlxSprite;
    var infoField:FlxBitmapText;
    var current = 0;
    
    var currentSprite(get, never):FlxSprite;
    inline function get_currentSprite() return disks.members[current];
    var currentSong(get, never):SongCreation;
    inline function get_currentSong() return Content.songsOrdered[current];
    
    public function new(x = 0.0, y = 0.0)
    {
        super();
        back = new FlxSprite(BACK_PATH);
        add(back);
        add(disks);
        
        current = 0;
        playingIndex = -1;
        if (FlxG.sound.music != null && Std.is(FlxG.sound.music, StreamedSound))
            playingIndex = (cast FlxG.sound.music:StreamedSound).data.index;
        
        if (playingIndex > 0)
            current = playingIndex;
        
        for (i=>song in Content.songsOrdered)
        {
            if (song.day <= Calendar.day)
            {
                final disk = new FlxSprite(DISK_SIDE_PATH);
                disk.x = SPACING * disks.length;
                if (i == current)
                    disk.x += SIDE_GAP;
                else if (i > current)
                    disk.x += SIDE_GAP * 2;
                
                disk.y = (back.height - disk.height) / 2;
                disks.add(disk);
            }
        }
        var width = SPACING * disks.length + disks.members[0].width;
        disks.x = (back.width - disks.width) / 2;
        
        add(new FlxSprite(SLOT_PATH));
        
        disk = new FlxSprite(DISK_FRONT_PATH);
        disk.x = (back.width - disk.width) / 2;
        add(disk).kill();
        
        var front = new FlxSprite();
        front.loadGraphic(FRONT_PATH, true, back.frameWidth, back.frameHeight);
        front.animation.add("anim", [0,1,2]);
        add(front);
        
        add(infoField = new FlxBitmapText());
        infoField.alignment = CENTER;
        infoField.color = 0xFF000000;
        hiliteCurrent();
        infoField.y = back.height - infoField.height - 4;
        
        this.x = x;
        this.y = y;
    }
    
    public function toNext():Void
    {
        if(current >= disks.length - 1)
            return;
        
        unhiliteCurrent();
        currentSprite.x -= SIDE_GAP;
        current++;
        currentSprite.x -= SIDE_GAP;
        hiliteCurrent();
    }
    
    public function toPrev():Void
    {
        if(current <= 0)
            return;
        
        unhiliteCurrent();
        currentSprite.x += SIDE_GAP;
        current--;
        currentSprite.x += SIDE_GAP;
        hiliteCurrent();
    }
    
    function unhiliteCurrent()
    {
    }
    
    function hiliteCurrent()
    {
        FlxG.sound.music.stop();
        FlxG.sound.music = null;
        // disks.x = (current+1) * -SPACING - SIDE_GAP*2 + (FlxG.width - currentSprite.width) / 2;
        FlxG.sound.playMusic(currentSong.samplePath, currentSong.volume);
        infoField.text = currentSong.name + "\n" + Content.listAuthorsProper(currentSong.authors);
        infoField.x = back.x + (back.width - infoField.width) / 2;
        // ok.active = true;
        // ok.alpha = 1;
    }
    
    public function select(callback:(SongCreation)->Void)
    {
        selecting = true;
        
        disk.y = back.y - disk.height;
        FlxTween.tween(currentSprite, { y: back.y - currentSprite.height }, 0.5,
            { ease:FlxEase.quadIn });
        FlxTween.tween(disk, { y:back.y + back.height }, 1.0,
            { startDelay:1.0, ease:FlxEase.quadOut, onStart: (_)->disk.revive(), onComplete: (_)->callback(currentSong) });
    }
}

