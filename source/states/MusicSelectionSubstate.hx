package states;

import data.Calendar;
import data.Content;
import data.Manifest;
import ui.Button;
import ui.Controls;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MusicSelectionSubstate extends flixel.FlxSubState
{
    static inline var LEFT_PATH = "assets/images/ui/carousel/left.png";
    static inline var RIGHT_PATH = "assets/images/ui/carousel/right.png";
    
    var carousel:Carousel;
    // prevents instant selection
    var wasAReleased = false;
    
    override function create()
    {
        super.create();
        
        carousel = new Carousel();
        carousel.screenCenter(XY);
        add(carousel);
        
        var camera = new FlxCamera(0, 0, Std.int(carousel.width), Std.int(carousel.height), 2);
        cameras = [camera];
        camera.x = FlxG.width / camera.zoom - camera.width;
        camera.y = FlxG.height / camera.zoom - camera.height;
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera);
        camera.scroll.x = carousel.x;
        camera.scroll.y = carousel.y;
        
        var left = new Button(0, 0, carousel.toPrev, LEFT_PATH);
        left.scrollFactor.set(1,1);
        left.x = carousel.x;
        left.y = carousel.y + carousel.height - left.height;
        add(left);
        var right = new Button(0, 0, carousel.toNext, RIGHT_PATH);
        right.x = carousel.x + carousel.width - right.width;
        right.y = carousel.y + carousel.height - right.height;
        right.scrollFactor.set(1,1);
        add(right);
        
        // Show these with the default camera because they are out of range
        var okay = new OkButton(0, 0, selectCurrent);
        okay.camera = FlxG.camera;
        okay.scale.set(2, 2);
        okay.updateHitbox();
        okay.y = FlxG.height - okay.height;
        okay.screenCenter(X);
        add(okay);
        
        var back = new BackButton(4, 4, cancel);
        back.camera = FlxG.camera;
        back.x = FlxG.width - back.width - 4;
        add(back);
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
            selectCurrent();
        if (Controls.justPressed.B)
            cancel();
    }
    
    function selectCurrent()
    {
        carousel.select(onSelectComplete);
    }
    
    function cancel()
    {
        if (carousel.playingIndex > -1)
            Manifest.playMusic(Content.songsOrdered[carousel.playingIndex].id);
        else
            stopMusic();
        
        close();
    }
    
    function onSelectComplete(song:SongCreation)
    {
        if (song != null)
            Manifest.playMusic(song.id);
        else
            stopMusic();
        
        close();
    }
    
    override function close()
    {
        if (camera == null)
            FlxG.cameras.remove(camera);
        
        super.close();
    }
    
    inline public static function stopMusic()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        
        FlxG.sound.music = null;
    }
}

class Carousel extends FlxSpriteGroup
{
    static inline var SPACING = 10;
    static inline var SIDE_GAP = 20;
    static inline var BACK_PATH = "assets/images/ui/carousel/back.png";
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
    inline function get_currentSprite() return disks.members[current + 1];
    function getCurrentSong()
    {
        return current == -1 ? null : Content.songsOrdered[current];
    }
    
    public function new(x = 0.0, y = 0.0)
    {
        super();
        back = new FlxSprite(BACK_PATH);
        add(back);
        add(disks);
        
        playingIndex = -1;
        var music = Std.downcast(FlxG.sound.music, StreamedSound);
        if (music != null)
            playingIndex = music.data.index;
        
        current = playingIndex;
        
        for (i in -1...Content.songsOrdered.length)
        {
            if (i < 0 || Content.songsOrdered[i].day <= Calendar.day)
            {
                var path = "assets/images/ui/carousel/disks/side_silence.png";
                if (i >= 0)
                    path = Content.songsOrdered[i].sideDiskPath;
                
                final disk = new FlxSprite(path);
                disk.x = SPACING * disks.length;
                if (i == current)
                    disk.x += SIDE_GAP;
                else if (i > current)
                    disk.x += SIDE_GAP * 2;
                
                disk.y = (back.height - disk.height) / 2;
                disks.add(disk);
            }
        }
        var width = SPACING * disks.length + disks.members[0].width + SIDE_GAP * 2;
        disks.x = (back.width - width) / 2;
        
        add(new FlxSprite(SLOT_PATH));
        
        disk = new FlxSprite("assets/images/ui/carousel/disks/front_silence.png");
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
        if(this.current >= this.disks.group.length - 2)
            return;
        
        unhiliteCurrent();
        currentSprite.x -= SIDE_GAP;
        current++;
        currentSprite.x -= SIDE_GAP;
        hiliteCurrent();
    }
    
    public function toPrev():Void
    {
        if(current <= -1)
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
        MusicSelectionSubstate.stopMusic();
        
        if (current == -1)
        {
            infoField.text = "The Sound of Simon & Garfunkel\nGeoKureli";
            infoField.x = back.x + (back.width - infoField.width) / 2;
        }
        else
        {
            var song = getCurrentSong();
            FlxG.sound.playMusic(song.samplePath, song.volume);
            infoField.text = song.name + "\n" + Content.listAuthorsProper(song.authors);
            infoField.x = back.x + (back.width - infoField.width) / 2;
        }
    }
    
    public function select(callback:(SongCreation)->Void)
    {
        selecting = true;
        
        var song = getCurrentSong();
        if (song != null)
            disk.loadGraphic(song.frontDiskPath);
        disk.y = back.y - disk.height;
        
        FlxTween.tween(currentSprite, { y: back.y - currentSprite.height }, 0.5,
            { ease:FlxEase.quadIn });
        FlxTween.tween(disk, { y:back.y + back.height }, 1.0,
            { startDelay:1.0, ease:FlxEase.quadOut, onStart: (_)->disk.revive(), onComplete: (_)->callback(song) });
    }
}

