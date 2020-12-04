package states;

import flixel.text.FlxBitmapText;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.graphics.FlxGraphic;
import data.Manifest;
import data.Content;
import data.Calendar;
import data.NGio;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.input.gamepad.FlxGamepad;

/**
 * ...
 * @author NInjaMuffin99
 */
class GallerySubstate extends FlxSubState 
{
	
	private var data:ArtCreation;
	private var curAnimPlaying:Int = 0;
	private var imageText:FlxBitmapText;
	private var infoBox:FlxSpriteButton;
	private var bigPreview:FlxSprite;
	private var bigImage:FlxSpriteGroup;
	private var textBG:FlxSpriteButton;
	private var onClose:Null<()->Void>;
	
	// GET TOUCH CONTROLS FOR EXITING GOING HERE
	public function new(artId, ?onClose:()->Void) 
	{
		this.data = Content.artwork[artId];
		this.onClose = onClose;
		super();
	}
	
	override public function create():Void 
	{
		FlxG.camera.bgColor = FlxColor.TRANSPARENT;
		
		bigImage = new FlxSpriteGroup();
		bigPreview = new FlxSprite();
		bigPreview.antialiasing = data.antiAlias == null || data.antiAlias == true;
		bigImage.add(bigPreview);
		bigImage.scrollFactor.set();
		
		imageText = new FlxBitmapText();
		imageText.y = FlxG.height - 16;
		imageText.width = FlxG.width / 2;
		imageText.updateHitbox();
		imageText.alignment = FlxTextAlign.CENTER;
		imageText.scrollFactor.set();
		
		var profileUrl = Content.credits[data.authors[0]].newgrounds;
		infoBox = new FlxSpriteButton(0, imageText.y - 2, null, ()->FlxG.openURL(profileUrl));
		infoBox.makeGraphic(Std.int(FlxG.width / 2) + 4, 36, FlxColor.BLACK);
		infoBox.alpha = 0.5;
		infoBox.screenCenter(X);
		
		textBG = new FlxSpriteButton(4, 4, null, close);
		textBG.makeGraphic(150, 18, FlxColor.BLACK);
		textBG.alpha = 0.5;
		textBG.scrollFactor.set();
		
		var text = new FlxBitmapText();
		text.x = 16;
		text.y = 11;
		text.text = 'Current Pic - ${FlxG.onMobile ? "Tap" : "Click"} here to exit';
		text.scrollFactor.set();
		
		add(bigImage);
		
		add(textBG);
		add(infoBox);
		add(imageText);
		add(text);
		
		bigImage.visible = false;
		
		loadImage();
		
		super.create();
	}
	
	function loadImage()
	{
		final text = new FlxText(0, 0, 0, "Loading", 16);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		text.autoSize = true;
		text.x = camera.scroll.x + (camera.width  - text.width) / 2;
		text.y = camera.scroll.y + (camera.height - text.height) / 2;
		add(text);
		
		Manifest.loadArt(data.id, function(graphic)
			{
				remove(text);
				openImage(graphic);
			}
		);
	}
	
	private function openImage(graphic:FlxGraphic):Void
	{
		curAnimPlaying = 0;
		bigImage.visible = true;
		
		// regular artwork
		var title = data.name != null ? data.name : "Art";
		imageText.text = title+ " by " + Content.listAuthorsProper(data.authors) + "\n"
			+ (FlxG.onMobile ? "Tap" : "Click") +" here to view their profile";
		imageText.screenCenter(X);
		bigPreview.loadGraphic(graphic);
		
		var horizSize = Std.int(bigPreview.width);
		var vertSize = Std.int(bigPreview.height);
		if (data.animation != null)
		{
			horizSize = Std.int(horizSize / data.animation.frames);
			bigPreview.loadGraphic(graphic, true, horizSize, vertSize);
		}
		
		bigPreview.setGraphicSize(0, Std.int(FlxG.height));
		bigPreview.updateHitbox();
		bigPreview.screenCenter();
		
		if (bigPreview.width >= FlxG.width)
			bigPreview.setGraphicSize(Std.int(FlxG.width));
		
		bigPreview.updateHitbox();
		bigPreview.screenCenter();
	}
	
	override public function update(elapsed:Float):Void 
	{
		// note to self: if this super.update() isnt at the top of this function
		// there's errors with the FlxSpriteButtons where it fuks some bullshit up with the mouse and nulls and shit 
		super.update(elapsed);
		
		if (bigPreview.graphic == null || bigPreview.graphic.bitmap == null)
			return;
		
		#if !mobile
			keyboardControls();
			
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
			if (gamepad != null)
			{
				gamepadControls(gamepad);
			}
		#end
		
		if (FlxG.keys.justPressed.ENTER)
			FlxG.openURL(Content.credits[data.authors[0]].newgrounds);
		
		dragControls();
	}
	
	
	private function keyboardControls():Void
	{
		#if !mobile
		if (FlxG.mouse.wheel != 0)
		{
			bigPreview.setGraphicSize(Std.int(bigPreview.width + (FlxG.mouse.wheel * 1.5)));
			bigPreview.updateHitbox();
			bigPreview.screenCenter();
		}
		#end
		
		if (FlxG.keys.anyJustPressed([ESCAPE, SPACE, X]))
			close();
		
		// REPLACE THESE TO BE CLEANER LATER AND WITH MORE KEYS
		if (FlxG.keys.pressed.D)
		{
			bigPreview.offset.x += 5;
		}
		if (FlxG.keys.pressed.W)
		{
			bigPreview.offset.y -= 5;
		}	
		if (FlxG.keys.pressed.A)
		{
			bigPreview.offset.x -= 5;
		}
		if (FlxG.keys.pressed.S)
		{
			bigPreview.offset.y += 5;
		}
	}
	
	private function gamepadControls(gamepad:FlxGamepad):Void
	{
		var pressed = FlxG.gamepads.anyPressed;
		function anyPressed(idArray:Array<FlxGamepadInputID>)
		{
			while(idArray.length > 0)
			{
				if (pressed(idArray.shift()))
					return true;
			}
			return false;
		}
		
		//Close Substate
		if (pressed(B))
			close();
		
		if (anyPressed([DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN ])) bigPreview.offset.y += 5;
		if (anyPressed([DPAD_UP   , LEFT_STICK_DIGITAL_UP   ])) bigPreview.offset.y -= 5;
		if (anyPressed([DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT ])) bigPreview.offset.x -= 5;
		if (anyPressed([DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT])) bigPreview.offset.x += 5;
		
		//Zooms
		if (anyPressed([RIGHT_TRIGGER, RIGHT_STICK_DIGITAL_UP]))
		{
			bigPreview.setGraphicSize(Std.int(bigPreview.width + 10));
			bigPreview.updateHitbox();
			bigPreview.screenCenter();
		}
		if (anyPressed([LEFT_TRIGGER, RIGHT_STICK_DIGITAL_DOWN]))
		{
			bigPreview.setGraphicSize(Std.int(bigPreview.width - 10));
			bigPreview.updateHitbox();
			bigPreview.screenCenter();
		}
	}
	
	private var dragPos:FlxPoint = new FlxPoint();
	private var picPosOld:FlxPoint = new FlxPoint();
	
	private var touchesLength:Float = 0;
	private var touchesAngle:Float = 0;
	private var picAngleOld:Float = 0;
	private var picWidthOld:Float = 0;
	
	private function dragControls():Void
	{	
		var pressingButton:Bool = false;
		var zoomPressingButton:Bool = false;
		var buttonJustPressed:Bool = false;
		var zoomButtonJustPressed:Bool = false;
		var buttonPos:FlxPoint = new FlxPoint();
		
		// its called touchNew, but really its the length of the line between the two touches
		// or the length between the center of the image and the mouse on right click
		var touchNew:Float = 0;
		var rads:Float = 0;
		var midScreen:FlxPoint = new FlxPoint();
		midScreen.set(FlxG.width / 2, FlxG.height / 2);
				
		
		#if !mobile
			if (FlxG.mouse.pressed)
			{
				if (FlxG.mouse.justPressed)
				{
					dragPos = FlxG.mouse.getPosition();
					buttonJustPressed = true;
				}
				
				pressingButton = true;
				buttonPos = FlxG.mouse.getPosition();
			}
			
			if (FlxG.mouse.pressedRight)
			{
				if (FlxG.mouse.justPressedRight)
				{
					zoomButtonJustPressed = true;
				}
				
				zoomPressingButton = true;
				
				rads = Math.atan2(midScreen.y - FlxG.mouse.y, midScreen.x - FlxG.mouse.x);
				touchNew = FlxMath.vectorLength(midScreen.x - FlxG.mouse.x, midScreen.y - FlxG.mouse.y);
			}
			
		#else
			if (FlxG.touches.list.length == 1)
			{
				if (FlxG.touches.list[0].justPressed)
				{
					dragPos = FlxG.touches.list[0].getPosition();
					buttonJustPressed = true;
				}
				
				pressingButton = true;
				buttonPos = FlxG.touches.list[0].getPosition();
			}
			if (FlxG.touches.list.length == 2)
			{
				
				if (FlxG.touches.list[1].justPressed)
				{
					zoomButtonJustPressed = true;
				}
				
				zoomPressingButton = true;
				
				rads = Math.atan2(FlxG.touches.list[0].y - FlxG.touches.list[1].y, FlxG.touches.list[0].x - FlxG.touches.list[1].x);
				touchNew = FlxMath.vectorLength(FlxG.touches.list[0].x - FlxG.touches.list[1].x, FlxG.touches.list[0].y - FlxG.touches.list[1].y);
			}
		#end
		
		// drag behaviour
		if (pressingButton)
		{
			if (buttonJustPressed)
			{
				picPosOld.x = bigPreview.offset.x;
				picPosOld.y = bigPreview.offset.y;
			}
		
			
			var xPos:Float = buttonPos.x - dragPos.x;
			var yPos:Float = buttonPos.y - dragPos.y;
			
			bigPreview.offset.x = picPosOld.x - xPos;
			bigPreview.offset.y = picPosOld.y - yPos;
			
		}
		
		// zoom behaviour
		if (zoomPressingButton)
		{	
			if (zoomButtonJustPressed)
			{
				touchesLength = touchNew;
				touchesAngle = FlxAngle.asDegrees(rads);
				picAngleOld = bigPreview.angle;
				picWidthOld = bigPreview.width;
			}
			
			
			var degs = FlxAngle.asDegrees(rads);
			// bigPreview.angle = (picAngleOld + degs - touchesAngle);
			
			FlxG.watch.addQuick("Degs/Angle", degs);
			
			bigPreview.setGraphicSize(Std.int(picWidthOld * (touchNew / touchesLength)));
			bigPreview.updateHitbox();
			bigPreview.screenCenter();
			
		}
	}
	
	override function close()
	{
		super.close();
		
		if (onClose != null)
		{
			onClose();
			onClose = null;
		}
	}
	
}