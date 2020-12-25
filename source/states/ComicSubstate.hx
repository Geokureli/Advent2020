package states;

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
    var data:ComicCreation;
    
    var container = new Sprite();
    var bitmap = new Bitmap();
    var audio:FlxSound;
    var loaded = false;
    var playing = false;
    var currentPage = -1;
    var pageTimes:Array<Float>;
    
    public function new (id:String, bgColor = 0x0)
    {
        this.data = Content.comics[id];
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
        FlxG.stage.addChild(container);
        container.addChild(bitmap);
        pageTimes = cast haxe.Json.parse(getText(data.dataPath));
        
        if (hasImage("cover.png"))
            setBitmapData(getImage("cover.png"));
        else
            start();
    }
    
    function start()
    {
        playing = true;
        currentPage = 1;
        showCurrentPage();
        
        if (data.audioPath != null)
            audio = FlxG.sound.play(getPath(data.audioPath), close);
    }
    
    function nextPage()
    {
        currentPage++;
        showCurrentPage();
    }
    
    function prevPage()
    {
        currentPage++;
        showCurrentPage();
    }
    
    function showCurrentPage()
    {
        setBitmapData(getPage(currentPage));
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
        
        if (!playing)
        {
            if (FlxG.mouse.justPressed || Controls.justPressed.A)
                start();
        }
        else
        {
            if (pageTimes != null && audio != null)
            {
                final nextTime = pageTimes[currentPage - 1];
                if (audio.time > nextTime)
                    nextPage();
            }
            else
            {
                //left right stuff
            }
        }
    }
    
    override function close()
    {
        FlxG.mouse.useSystemCursor = false;
        FlxG.stage.removeChild(container);
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