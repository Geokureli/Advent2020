package ui;

import utils.GameSize;
import openfl.geom.Point;
import dj.SongLoader;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;

import flixel.addons.display.FlxSliceSprite;

import openfl.display.BitmapData;

class DjUi extends FlxGroup
{
    inline static var MARGIN = 2;
    
    var bg:UiBgHeader;
    var currentSong:SongSprite;
    var addBtn:AddButton;
    var queue = new Array<dj.SongLoader.SongFeed>();
    var queueSprites = new FlxTypedSpriteGroup<SongSprite>();
    
    public function new (x = 0.0, y = 0.0)
    {
        super();
        
        bg = new UiBgHeader(x, y, 200, 80);
        add(bg);
        
        var header = new FlxBitmapText();
        add(header);
        header.text = "Currently playing";
        header.x = bg.x + (bg.width - header.width) / 2;
        header.y = bg.y + MARGIN;
        
        currentSong = new SongSprite(0, 0);
        add(currentSong);
        currentSong.x = bg.x + (bg.width - currentSong.width) / 2;
        currentSong.y = bg.y + UiBgHeader.HEADER_HEIGHT + MARGIN;
        
        var queueBg = new UiMiddleBar(0, 0, bg.width, 12);
        add(queueBg);
        queueBg.x = bg.x;
        queueBg.y = currentSong.y + currentSong.height + MARGIN;
        
        var queueHeader = new FlxBitmapText();
        add(queueHeader);
        queueHeader.text = "Queued Songs";
        queueHeader.x = queueBg.x + (queueBg.width - queueHeader.width) / 2;
        queueHeader.y = queueBg.y + MARGIN + 1;
        
        add(queueSprites);
        queueSprites.y = queueBg.y + queueBg.height + MARGIN;
        
        addBtn = new AddButton(0, 0, openAddSongWindow);
        add(addBtn);
        addBtn.x = addBtn.x + (bg.width - addBtn.width) / 2;
        
        redrawQueue();
    }
    
    function openAddSongWindow()
    {
        
    }
    
    function redrawQueue()
    {
        var queueBottom = queueSprites.y;
        for (i in 0...queueSprites.members.length)
        {
            final sprite = queueSprites.members[i];
            if (i >= queue.length)
                sprite.kill();
            else
            {
                if (!sprite.exists)
                    sprite.revive();
                sprite.setData(queue[i]);
                queueBottom = sprite.y + sprite.height + MARGIN;
            }
        }
        
        addBtn.y = queueBottom;
        bg.height = (addBtn.y + addBtn.height + MARGIN) - bg.y;
    }
}

class SongFinder extends FlxSpriteGroup
{
    var bg:UiBgHeader;
    var input:FlxBitmapText;
    
    public function new(x = 0.0, y = 0.0)
    {
        bg = new UiBgHeader(x, y, 200, 100);
        add(bg);
        
        var header = new FlxBitmapText();
        add(header);
        header.text = "Choose a Song";
        header.x = bg.x + (bg.width - header.width) / 2;
        header.y = bg.y + MARGIN;
        
        input = new FlxBitmapText();
        add(input);
        input.text = "######";
        input.x = bg.x + (bg.width - input.width) / 2;
        input.y = bg.y + UiBgHeader.HEADER_HEIGHT + MARGIN;
        
        
    }
    
    function 
}

class UiBgHeader extends FlxSliceSprite
{
    inline static public var HEADER_HEIGHT = 12;
    
    inline static var PATH = "assets/images/ui/bg_header.png";
    
    public function new (x, y, width, height)
    {
        super(PATH, FlxRect.get(2, 12, 1, 1), width, height);
    }
}

class UiMiddleBar extends FlxSliceSprite
{
    inline static var PATH = "assets/images/ui/bg_middle.png";
    
    inline static public var MARGIN = 2;
    
    public function new (x, y, width, height)
    {
        super(PATH, FlxRect.get(1, 1, 1, 10), width, height);
    }
}

class SongSprite extends FlxSpriteGroup
{
    inline static var EMPTY_DISK_PATH = "https://img.ngfiles.com/defaults/icon-audio-smallest.png";
    inline static var EMPTY_DISK = "emptyDisk";
    inline static var EMPTY_INFO = "Add a song to the queue to hear it";
    
    var disk:FlxSprite;
    var info:FlxBitmapText;
    
    public function new(x = 0.0, y = 0.0, ?data:SongFeed)
    {
        super(x, y);
        
        var emptyArt = loadDiskArt(EMPTY_DISK, EMPTY_DISK_PATH, true);
        
        add(disk = new FlxSprite());
        disk.antialiasing = true;
        add(info = new FlxBitmapText());
        final pixelSize = GameSize.pixelSize;
        info.x = disk.x + (emptyArt.width / GameSize.pixelSize) + 2;
        info.y = disk.y + ((emptyArt.height / GameSize.pixelSize) - info.y) / 2;
        
        setData(data);
    }
    
    public function setData(data:Null<SongFeed>)
    {
        if (data == null)
        {
            disk.loadGraphic(EMPTY_DISK);
            info.text = EMPTY_INFO;
            info.color = 0xFF9badb7;
        }
        else
        {
            loadGraphic(loadDiskArt("disk:" + data.id, data.icons.small));
            var owner = SongLoader.getOwner(data.authors);
            if (owner == null)
                throw "Missing Owner";
            info.text = owner.name + " - " + data.title;
            info.color = 0xFFffffff;
        }
        disk.scale.set(0.5, 0.5);
        disk.updateHitbox();
    }
    
    static public function loadDiskArt(key:String, path:String, persist = false)
    {
        var graphic = FlxG.bitmap.get(key);
        if (graphic == null)
        {
            graphic = FlxG.bitmap.create(35, 35, 0x0, false, key);
            graphic.persist = persist;
            BitmapData.loadFromFile(path).onComplete((data)->graphic.bitmap.copyPixels(data, data.rect, new Point()));
        }
        return graphic;
    }
}

@:forward
abstract AddButton(Button) to Button
{
    public function new(x = 0.0, y = 0.0, ?onClick)
    {
        this = new Button(x, y, onClick, "assets/images/ui/buttons/add.png");
    }
}

@:forward
abstract DialButton(Button) to Button
{
    public function new(digit:Int, x = 0.0, y = 0.0, ?onClick)
    {
        this = new Button(x, y, onClick, "assets/images/ui/buttons/sqaure.png");
        label = new FlxBitmapText(ui.Font.NokiaFont16);
        label.text = Std.string(digit);
    }
}