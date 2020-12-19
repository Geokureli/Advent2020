package states;


import openfl.display.MovieClip;
import openfl.events.AsyncErrorEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;

import flixel.FlxG;

private typedef PlayStatusData = { code:String, duration:Float, position:Float, speed:Float }
private typedef MetaData = { width:Int, height:Int, duration:Float }

class VideoSubstate extends flixel.FlxSubState
{
    var ui:VideoUi;
    
    public function new(path:String)
    {
        super();
        
        ui = new VideoUi(path);
    }
    
    override function create()
    {
        super.create();
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.pause();
        
        FlxG.stage.addChild(ui);
    }
    
    override function close()
    {
        FlxG.stage.removeChild(ui);
        ui.destroy();
        
        super.close();
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.resume();
    }
}

class VideoUi extends openfl.display.Sprite
{
    var netStream:NetStream;
    var video:Video;
    var path:String;
    
    public function new(path:String)
    {
        this.path = path;
        super();
        
        addChild(video = new Video());
        
        var netConnection = new NetConnection();
        netConnection.connect(null);
        
        netStream = new NetStream(netConnection);
        netStream.client =
            { onMetaData  : onMetaData
            , onPlayStatus: onPlayStatus
            };
        netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, (e)->trace("error loading video"));
        netConnection.addEventListener(NetStatusEvent.NET_STATUS,
            function onNetStatus(event)
            {
                trace("net status:" + haxe.Json.stringify(event.info));
                if (event.info.code == "NetStream.Play.Complete")
                    onVideoComplete();
            }
        );
        
        netStream.play(path);
    }
    
    function onMetaData(data:MetaData)
    {
        trace(haxe.Json.stringify(data));
        
        video.attachNetStream(netStream);
        video.width = video.videoWidth;
        video.height = video.videoHeight;
        
        if (video.videoWidth / FlxG.stage.stageWidth > video.videoHeight / FlxG.stage.stageHeight)
        {
            video.width = FlxG.stage.stageWidth;
            video.height = FlxG.stage.stageWidth * video.videoHeight / video.videoWidth;
        }
        else
        {
            video.height = FlxG.stage.stageHeight;
            video.width = FlxG.stage.stageHeight * video.videoWidth / video.videoHeight;
        }
    }
    
    function onPlayStatus(data:PlayStatusData)
    {
        
    }
    
    function onVideoComplete()
    {
    }
    
    public function destroy()
    {
        netStream.dispose();
    }
}