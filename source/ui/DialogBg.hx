package ui;

import flixel.FlxG;
import flixel.FlxSprite;

using flixel.util.FlxSpriteUtil;

@:forward
abstract DialogBg(FlxSprite) to FlxSprite
{
	public function new (x, y, width, height, fill = 0xFF52294b, line = 0xFF928fb8)
	{
		this = new FlxSprite(x, y);
		
		var oldQuality = FlxG.stage.quality;
		FlxG.stage.quality = LOW;
		this.makeGraphic(width, height, 0, true, '$width*$height:dialogBg');
		this.drawRoundRect(
			0, 0,
			width, height,
			8, 8,
			fill,
			{ color:line, thickness:1 },
			{ smoothing: false }
		);
		this.x = (FlxG.width  - this.width ) / 2;
		this.y = (FlxG.height - this.height) / 2;
		this.scrollFactor.set();
		FlxG.stage.quality = oldQuality;
	}
	
	inline public static function fromBuffer(buffer = 6, fill = 0xFF52294b, line = 0xFF928fb8)
	{
		return new DialogBg(buffer, buffer, FlxG.width - buffer * 2, FlxG.height - buffer * 2, fill, line);
	}
}