package states;

import ui.OpenFlButton;
import ui.Controls;
import data.Content;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.text.FlxBitmapText;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.utils.Assets;

class ComicSubstate extends flixel.FlxSubState
{
    var data:ArtCreation;
    
    var container = new Sprite();
    var bitmap = new Bitmap();
    var audio:FlxSound;
    var loaded = false;
    var playing = false;
    var currentPage = -1;
    var pageTimes:Array<Float>;
    var prev:OpenFlButton;
    var next:OpenFlButton;
    var exit:OpenFlButton;
    var buttons:Sprite;
    var moveTimer = 2.0;
    
    public function new (id:String, bgColor = 0x0)
    {
        data = Content.artwork[id];
        if (data.comic == null)
            throw "Invalid comic data, id:" + data.id;
        
        super(bgColor);
    }
    
    override function create()
    {
        super.create();
        
        if (Assets.hasLibrary(data.id))
            onLoad();
        else
        {
            var loadingField = new FlxBitmapText(new ui.Font.NokiaFont16());
            loadingField.text = "Loading...";
            loadingField.setBorderStyle(OUTLINE, 0xFF000000);
            loadingField.screenCenter(XY);
            add(loadingField);
            
            Assets.loadLibrary(data.id).onComplete(function (_)
            {
                loadingField.kill();
                onLoad();
            });
        }
    }
    
    function onLoad()
    {
        FlxG.mouse.useSystemCursor = true;
        loaded = true;
        
        final stage = FlxG.stage;
        stage.addChild(container);
        container.addChild(bitmap);
        stage.addChild(buttons = new Sprite());
        buttons.addChild(prev = new PrevButton(clickPrev));
        buttons.addChild(next = new NextButton(clickNext));
        buttons.addChild(exit = new OpenFlBackButton(close));
        prev.x = 16;
        prev.y = (stage.stageHeight - prev.height) / 2;
        prev.visible = false;
        next.x = stage.stageWidth - next.width * next.scaleX - prev.x;
        next.y = prev.y;
        next.mouseEnabled = false;
        
        if (data.comic.dataPath != null)
        {
            if (!hasText(data.comic.dataPath))
                throw "invalid dataPath:" + data.comic.dataPath;
            pageTimes = cast haxe.Json.parse(getText(data.comic.dataPath));
            pageTimes.unshift(0);
        }
        if (hasImage("cover.png"))
            setBitmapData(getImage("cover.png"));
        else
            start();
    }
    
    function clickPrev()
    {
        if (playing)
            prevPage();
    }
    
    function clickNext()
    {
        if (playing)
            nextPage();
    }
    
    function start()
    {
        playing = true;
        if (data.comic.audioPath != null)
            audio = FlxG.sound.play(getPath(data.comic.audioPath), close);
        
        currentPage = 1;
        showCurrentPage(false);
    }
    
    function nextPage(setAudio = true)
    {
        if (currentPage < data.comic.pages)
        {
            currentPage++;
            showCurrentPage(setAudio);
        }
    }
    
    function prevPage()
    {
        if (currentPage > 1)
        {
            currentPage--;
            showCurrentPage(true);
        }
    }
    
    function showCurrentPage(setAudio = true)
    {
        prev.visible = currentPage > 1;
        next.visible = currentPage < data.comic.pages;
        
        setBitmapData(getPage(currentPage));
        
        if (setAudio && audio != null && pageTimes != null)
            audio.time = pageTimes[currentPage - 1];
    }
    
    function setBitmapData(bitmapData:BitmapData)
    {
        bitmap.bitmapData = bitmapData;
        
        final stage = container.stage;
        if (bitmapData.width / stage.stageWidth > bitmapData.height / stage.stageHeight)
        {
            bitmap.width = stage.stageWidth;
            bitmap.scaleY = bitmap.scaleX;
        }
        else
        {
            bitmap.height = stage.stageHeight;
            bitmap.scaleX = bitmap.scaleY;
        }
        
        bitmap.x = bitmap.y = 0;
        if (bitmap.width < stage.stageWidth)
            bitmap.x = (stage.stageWidth - bitmap.width) / 2;
        
        if (bitmap.height < stage.stageHeight)
            bitmap.y = (stage.stageHeight - bitmap.height) / 2;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!loaded)
            return;
        
        prev.update(elapsed);
        next.update(elapsed);
        exit.update(elapsed);
        
        if (!playing)
        {
            if (FlxG.mouse.justPressed || Controls.justPressed.A)
                start();
        }
        else
        {
            if (!next.mouseEnabled && !FlxG.mouse.pressed)
                next.mouseEnabled = true;
            
            if (pageTimes != null && audio != null)
            {
                final nextTime = pageTimes[currentPage];
                if (audio.time > nextTime)
                    nextPage(false);
            }
            
            if (Controls.justPressed.LEFT ) prevPage();
            if (Controls.justPressed.RIGHT) nextPage();
            if (Controls.justPressed.B    ) close();
            
            if (moveTimer > 0)
            {
                moveTimer -= elapsed;
                if (moveTimer <= 0)
                    buttons.visible = false;
            }
            
            if (FlxG.mouse.justMoved || FlxG.mouse.pressed)
            {
                buttons.visible = true;
                moveTimer = 2.0;
            }
        }
    }
    
    override function close()
    {
        FlxG.mouse.useSystemCursor = false;
        
        final stage = FlxG.stage;
        stage.removeChild(container);
        stage.removeChild(buttons);
        prev.destroy();
        next.destroy();
        exit.destroy();
        
        if (audio != null)
            audio.kill();
        
        super.close();
    }
    
    inline function getPath(path:String) return '${data.id}:${data.id}/$path';
    inline function getImage(path:String) return Assets.getBitmapData(getPath(path));
    inline function hasImage(path:String) return Assets.exists(getPath(path), IMAGE);
    inline function getPage(num:Int) return Assets.getBitmapData(getPath(getPageName(num)));
    inline function hasPage(num:Int) return Assets.exists(getPath(getPageName(num)), IMAGE);
    inline function getText(path:String) return Assets.getText(getPath(path));
    inline function hasText(path:String) return Assets.exists(getPath(path), TEXT);
    
    function getPageName(num:Int) return "page" + StringTools.lpad(Std.string(num), "0", 2) + ".png";
}

@:forward
abstract PrevButton(OpenFlButton) from OpenFlButton to OpenFlButton
{
    inline public function new (callback) { this = new OpenFlButton("prev", callback); }
}

@:forward
abstract NextButton(OpenFlButton) from OpenFlButton to OpenFlButton
{
    inline public function new (callback) { this = new OpenFlButton("next", callback); }
}