package states;

import data.Content;
import data.Save;
import utils.BitArray;
import data.Instrument;
import ui.Button;
import ui.Font;

import openfl.geom.Rectangle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import flixel.ui.FlxBitmapTextButton;
import flixel.ui.FlxButton;

class PianoSubstate extends flixel.FlxSubState
{
	static public var musicKeys = "E4R5TY7U8I9OP";
	
	var down:BitArray = new BitArray();
	
	override public function create():Void 
	{
		super.create();
		
		var back = new BackButton(FlxG.width - 2, 25, close);
		back.x -= back.width;
		add(back);
		
		BlackKey.createAll(this, onChange);
		WhiteKey.createAll(this, onChange);
	}
	
	function onChange(char:String, isPress:Bool):Void
	{
		if (isPress)
		{
			trace('press $char');
			Instrument.press(musicKeys.indexOf(char));
		}
		else
		{
			trace('release $char');
			Instrument.release(musicKeys.indexOf(char));
		}
	}
}

abstract BlackKey(Key) to Key
{
	inline static var CHARS = "45789";
	inline static public var TOP = 20;
	inline static public var GAP = 2; // index where left2 starts
	inline static public var WIDTH = 40;
	inline static public var HEIGHT = 63;
	inline static public var LEFT_1 = 24;
	inline static public var LEFT_2 = 137 - WIDTH * GAP;
	
	public function new (index:Int, onClick:(String, Bool)->Void)
	{
		final label = CHARS.charAt(index);
		this = new Key
			( (index < GAP ? LEFT_1 : LEFT_2) + (WIDTH + 1) * index
			, TOP
			, WIDTH
			, HEIGHT
			, "assets/images/ui/blacKey.png"
			, label
			, onClick.bind(label, _)
			);
	}
	
	public static function createAll(parent:FlxGroup, onClick:(String, Bool)->Void):Void
	{
		for (i in 0...CHARS.length)
			parent.add(new BlackKey(i, onClick));
	}
}

abstract WhiteKey(Key) to Key
{
	inline static var CHARS = "ERTYUIOP";
	inline static public var TOP = BlackKey.TOP + BlackKey.HEIGHT + 1;
	inline static public var LEFT = 9;
	inline static public var WIDTH = 37;
	inline static public var HEIGHT = 87;
	
	public function new (index:Int, onClick:(String, Bool)->Void)
	{
		final label = CHARS.charAt(index);
		this = new Key
			( LEFT + (WIDTH + 1) * index
			, TOP
			, WIDTH
			, HEIGHT
			, "assets/images/ui/whitekey.png"
			, label
			, onClick.bind(label, _)
			);
	}
	
	public static function createAll(parent:FlxGroup, onClick:(String, Bool)->Void):Void
	{
		for (i in 0...CHARS.length)
			parent.add(new WhiteKey(i, onClick));
	}
}

class Key extends FlxBitmapTextButton
{
	inline static var LETTER_BUFFER = 8;
	
	public function new 
	( x      :Float
	, y      :Float
	, width  :Int
	, height :Int
	, graphic
	, char   :String
	, onClick:(Bool)->Void
	)
	{
		super(x, y, char);
		loadGraphic(graphic, true, width, height);
		onDown.callback = onClick.bind(true);
		onUp.callback = onClick.bind(false);
		onOut.callback = onClick.bind(false);
		
		statusAnimations = ["normal", "normal", "pressed"];
		label.font = new NokiaFont();
		label.setBorderStyle(OUTLINE, 0xFF222034);
		labelOffsets[0].x
			= labelOffsets[1].x
			= labelOffsets[2].x = Std.int((width - label.width) / 2);
		labelOffsets[0].y
			= labelOffsets[1].y
			= labelOffsets[2].y = height - label.height - LETTER_BUFFER;
		
		var instrument = Content.instruments[Save.getInstrument()];
		if (instrument.keys[PianoSubstate.musicKeys.indexOf(char)] == null)
		{
			active = false;
			update(FlxG.elapsed);
			alpha = 0.5;
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		var key:Array<FlxKey> = switch(label.text)
		{
			case "4": [FOUR];
			case "5": [FIVE];
			case "7": [SEVEN];
			case "8": [EIGHT];
			case "9": [NINE];
			case char: [char];
		}
		
		if (FlxG.keys.anyJustPressed(key))
			onDown.fire();
		
		if (FlxG.keys.anyPressed(key))
			animation.play("pressed");
		
		if (FlxG.keys.anyJustReleased(key))
		{
			onUp.fire();
			animation.play("normal");
		}
	}
}