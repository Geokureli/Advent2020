package ui;

import lime.system.Clipboard;
import dj.SongLoader;
import ui.Button;
import ui.Font;
import utils.GameSize;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;

import flixel.addons.display.FlxSliceSprite;

import openfl.display.BitmapData;
import openfl.geom.Point;

class DjUi extends FlxSpriteGroup
{
    inline static var MARGIN = 2;
    
    var bg:UiBgHeader;
    var currentSong:SongSprite;
    var addBtn:AddButton;
    var queue = new Array<dj.SongLoader.SongFeed>();
    var queueSprites = new FlxTypedSpriteGroup<SongSprite>();
    var dragOffset:FlxPoint;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        
        bg = new UiBgHeader(0, 0, 200, 80);
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
        var finder = new SongFinder();
        add(finder);
        finder.songSelected = function(data:SongFeed)
        {
            remove(finder);
            finder.kill();
            addSong(data);
        }
    }
    
    function addSong(data:SongFeed)
    {
        queue.push(data);
        redrawQueue();
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
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        final overlapping = dragOffset != null || bg.overlapsPoint(FlxG.mouse.getScreenPosition(null, FlxPoint.weak()));
        final contains = Button.allBlocking.contains(bg);
        
        if (overlapping && !contains)
            Button.allBlocking.push(bg);
        else if(!overlapping && contains)
            Button.allBlocking.remove(bg);
        
        final mouse = FlxG.mouse.getScreenPosition();
        if (dragOffset != null)
        {
            var p = FlxPoint.get(mouse.x + dragOffset.x, mouse.y + dragOffset.y);
            if (p.x < 0) p.x = 0;
            if (p.y < 0) p.y = 0;
            if (p.x > FlxG.width  - bg.width ) p.x = FlxG.width  - bg.width ;
            if (p.y > FlxG.height - bg.height) p.y = FlxG.height - bg.height;
            x = p.x;
            y = p.y;
            p.put();
            
            if (!FlxG.mouse.pressed)
                dragOffset = null;
        }
        else if (FlxG.mouse.justPressed && overlapping && mouse.y - y < UiBgHeader.HEADER_HEIGHT)
            dragOffset = FlxPoint.get(x - mouse.x, y - mouse.y);
        
        mouse.put();
    }
    
    override function destroy()
    {
        if (Button.allBlocking.contains(bg))
            Button.allBlocking.remove(bg);
        
        super.destroy();
    }
}

class SongFinder extends FlxSpriteGroup
{
    inline static var DEFAULT_SEARCH = "######";
    inline static var COLOR_ON  = 0xFFffffff;
    inline static var COLOR_OFF = 0xFF808080;
    
    inline static var MARGIN = 2;
    
    public var songSelected:(data:SongFeed)->Void;
    
    var bg:UiBgHeader;
    var input:FlxBitmapText;
    var info:FlxBitmapText;
    var searching = false;
    var searchedData:SongFeed;
    
    public function new(x = 0.0, y = 0.0)
    {
        super(x, y);
        bg = new UiBgHeader(0, 0, 200, 100);
        add(bg);
        
        var header = new FlxBitmapText();
        add(header);
        header.text = "Choose a Song";
        header.x = bg.x + (bg.width - header.width) / 2;
        header.y = bg.y + MARGIN;
        
        var instructions = new FlxBitmapText();
        add(instructions);
        instructions.alignment = CENTER;
        instructions.text = "Enter the song's 6 digit id\n"
            + "newgrounds.com/audio/listen/######";
        instructions.x = bg.x + (bg.width - instructions.width) / 2;
        instructions.y = bg.y + UiBgHeader.HEADER_HEIGHT + MARGIN;
        
        input = new FlxBitmapText();
        add(input);
        input.text = DEFAULT_SEARCH;
        input.color = COLOR_OFF;
        input.x = bg.x + (bg.width - input.width) / 2;
        input.y = instructions.y + instructions.height + MARGIN;
        
        info = new FlxBitmapText();
        add(info);
        info.alignment = CENTER;
        info.text = "";
        info.x = input.x + (bg.width - info.width) / 2;
        info.y = input.y + input.height + MARGIN;
    }
    
    static var keys:Array<FlxKey> = [ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE];
    static var digitFinder = ~/\d{6}/;
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (searching)
        {
            return;
        }
        
        if (FlxG.onMobile)
        {
        }
        else
        {
            if (FlxG.keys.justPressed.V)
            {
                var clipboard = Clipboard.text;
                if (digitFinder.match(clipboard))
                {
                    info.text = digitFinder.matched(0);
                    input.color = COLOR_ON;
                }
                else
                {
                    info.text = DEFAULT_SEARCH;
                    input.color = COLOR_OFF;
                }
            }
            
            for (i in 0...keys.length)
            {
                if (FlxG.keys.checkStatus(keys[i], JUST_PRESSED))
                    onDial(i);
            }
            
            if (FlxG.keys.justPressed.BACKSPACE || Controls.justPressed.B)
                deleteChar();
            
            if (Controls.justPressed.PAUSE)
                enter();
        }
    }
    
    function onDial(digit:Int)
    {
        var newText = input.text;
        if (input.text == DEFAULT_SEARCH)
        {
            newText = "";
            input.color = COLOR_ON;
        }
        else if (newText.length >= 6)
            return;
        
        newText += Std.string(digit);
        input.text = newText;
    }
    
    function deleteChar()
    {
        if (searchedData != null)
        {
            searchedData = null;
            info.text = "";
        }
        
        if (input.text == DEFAULT_SEARCH)
            return;
        else if (input.text.length == 1)
        {
            input.text = DEFAULT_SEARCH;
            input.color = COLOR_OFF;
        }
        else
            input.text = input.text.substr(0, input.text.length - 1);
    }
    
    function enter()
    {
        if (searchedData != null)
        {
            songSelected(searchedData);
            return;
        }
        
        searching = true;
        info.color = COLOR_OFF;
        setInfo("searching...");
        SongLoader.checkCode(input.text, function(response)
        {
            searching = false;
            info.color = COLOR_ON;
            switch(response)
            {
                case Success(data):
                    searchedData = data;
                    final author = SongLoader.getOwner(data.authors).name;
                    setInfo('${cap(data.title, 25)} by ${cap(author, 20)}\nPress ENTER to select');
                    
                case Fail(type):
                    switch (type)
                    {
                        case ScrapeError(_) | IoError(_):
                            setInfo("Invalid song ID");
                        case ApiNotAllowed | InvalidFeedInfo:
                            setInfo("This song disallows external use");
                    }
            }
        });
    }
    
    function cap(str:String, length:Int)
    {
        if (str.length > length)
            return str.substr(0, length - 3) + "...";
        
        return str;
    }
    
    function setInfo(msg:String)
    {
        info.text = msg;
        info.x = bg.x + (bg.width - info.width) / 2;
    }
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
        var numLabel = new FlxBitmapText(new NokiaFont16());
        this.label = numLabel;
        numLabel.text = Std.string(digit);
    }
}