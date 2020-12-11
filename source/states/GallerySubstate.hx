package states;

import ui.Button;
import ui.Controls;
import ui.Font;
import utils.GameSize;
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
		camera = new FlxCamera();
		camera.bgColor = 0x0;
		FlxG.cameras.add(camera);
		
		bigImage = new FlxSpriteGroup();
		bigPreview = new FlxSprite();
		bigPreview.antialiasing = data.antiAlias == null || data.antiAlias == true;
		bigImage.add(bigPreview);
		add(bigImage);
		
		imageText = new FlxBitmapText();
		imageText.y = FlxG.height - 20;
		imageText.width = FlxG.width / 2;
		imageText.lineSpacing = 2;
		imageText.updateHitbox();
		imageText.alignment = FlxTextAlign.CENTER;
		add(imageText);
		
		var profileUrl = Content.credits[data.authors[0]].newgrounds;
		infoBox = new FlxSpriteButton(0, imageText.y - 5, null, ()->FlxG.openURL(profileUrl));
		infoBox.makeGraphic(Std.int(FlxG.width / 2) + 4, 20, FlxColor.BLACK);
		infoBox.alpha = 0.5;
		infoBox.screenCenter(X);
		add(infoBox);
		
		var button = new BackButton(4, 4, close);
		button.x = FlxG.width - button.width - 4;
		add(button);
		
		bigImage.visible = false;
		loadImage();
		
		super.create();
	}
	
	function loadImage()
	{
		final text = new FlxBitmapText(new NokiaFont16());
		text.text = "Loading";
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
		
		if (bigPreview.antialiasing == false)
		{
			bigPreview.scale.x = bigPreview.scale.y = Math.floor(bigPreview.scale.x * GameSize.pixelSize) / GameSize.pixelSize;
			bigPreview.updateHitbox();
			bigPreview.screenCenter();
		}
	}
	
	override public function update(elapsed:Float):Void 
	{
		// note to self: if this super.update() isnt at the top of this function
		// there's errors with the FlxSpriteButtons where it fuks some bullshit up with the mouse and nulls and shit 
		super.update(elapsed);
		
		if (bigPreview.graphic == null || bigPreview.graphic.bitmap == null)
			return;
		
		#if !mobile
			checkControls();
		#end
		
		if (FlxG.keys.justPressed.ENTER)
			FlxG.openURL(Content.credits[data.authors[0]].newgrounds);
		
		dragControls();
	}
	
	private function checkControls():Void
	{
		//Close Substate
		if (Controls.justPressed.B)
			close();
		
		if (Controls.pressed.DOWN ) bigPreview.offset.y += 5;
		if (Controls.pressed.UP   ) bigPreview.offset.y -= 5;
		if (Controls.pressed.LEFT ) bigPreview.offset.x -= 5;
		if (Controls.pressed.RIGHT) bigPreview.offset.x += 5;
		
		//Zooms
		if (Controls.pressed.ZOOM_IN)
		{
			bigPreview.setGraphicSize(Std.int(bigPreview.width + 10));
			bigPreview.updateHitbox();
			bigPreview.screenCenter();
		}
		if (Controls.pressed.ZOOM_OUT)
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