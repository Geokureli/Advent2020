package;

import utils.GameSize;
import flixel.system.scaleModes.FixedScaleAdjustSizeScaleMode;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxCamera;
import props.InputPlayer;
import vfx.PixelPerfectShader;

import flixel.FlxG;
import flixel.FlxState;

import openfl.filters.ShaderFilter;
import openfl.utils.Assets;

class PlayState extends FlxState
{
	var player:InputPlayer;
	override public function create():Void
	{
		player = new InputPlayer(20, 20);
		player = new InputPlayer(FlxG.width / 2, FlxG.height / 2);
		FlxG.camera.follow(player);
		add(player);
		
		//FlxG.debugger.drawDebug = true;
		
		// FlxG.camera.setFilters([new ShaderFilter(new PixelPerfectShader())]);
		
		// FlxTween.tween(FlxG.camera, { zoom:2 }, 2, { startDelay:2 });
		
		super.create();
		
		// dj.SongLoader.loadSong("976686", (response)->trace(response));
		
		FlxG.sound.music = FlxG.sound.stream("assets/music/pillowDX.mp3");
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		// if (FlxG.mouse.justPressed)
		// 	FlxG.sound.music.play();
		
		if (FlxG.keys.justPressed.Z)
			GameSize.setPixelSize(1);
		else if (FlxG.keys.justPressed.X)
			GameSize.setPixelSize(2);
		else if (FlxG.keys.justPressed.C)
			GameSize.setPixelSize(4);
		
		if (FlxG.keys.justPressed.ENTER)
		{
			trace("resetting");
			FlxG.resetState();
		}
	}
}
