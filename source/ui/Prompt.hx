package ui;

import ui.Button;
import ui.Font;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;

using flixel.util.FlxSpriteUtil;

class Prompt extends flixel.group.FlxGroup {
	
	inline static var BUFFER = 6;
	
	var box:FlxSprite;
	var label:FlxBitmapText;
	var yesMouse:Button;
	var noMouse:Button;
	// var keyButtons:ButtonGroup;
	// var yesKeys:BitmapText;
	// var noKeys:BitmapText;
	
	var forceMouse:Bool;
	
	public function new (singleButton = false) {
		super();
		
		this.forceMouse = true;//forceMouse || FlxG.onMobile;
		var oldQuality = FlxG.stage.quality;
		FlxG.stage.quality = LOW;
		add(box = new FlxSprite());
		box.makeGraphic(FlxG.width - BUFFER * 2, 72, 0, true, "prompt-bg");
		box.drawRoundRect(
			0,
			0,
			box.graphic.width,
			box.graphic.height,
			8,
			8,
			0xFF52294b,
			{ color:0xFF928fb8, thickness:1 },
			{ smoothing: false }
		);
		box.x = (FlxG.width  - box.width ) / 2;
		box.y = (FlxG.height - box.height) / 2;
		box.scrollFactor.set();
		FlxG.stage.quality = oldQuality;
		
		add(label = new FlxBitmapText(new NokiaFont()));
		label.alignment = CENTER;
		label.scrollFactor.set();
		
		if (this.forceMouse) {
			
			if (singleButton)
				add(yesMouse = new OkButton((FlxG.width - 28) / 2, 0));
			else {
				add(yesMouse = new YesButton(FlxG.width / 2 - 28 - 16, 0));
				add(noMouse  = new NoButton (FlxG.width / 2      + 16, 0));
			}
			
		} else {
			
			// keyButtons = new ButtonGroup(0, false);
			// keyButtons.keysNext = RIGHT;
			// keyButtons.keysPrev = LEFT;
			// if (singleButton) {
			// 	keyButtons.addButton(yesKeys = new BitmapText(0, 0, "OK"), null);
			// 	yesKeys.centerXOnStage();
			// } else {
			// 	keyButtons.addButton(yesKeys = new BitmapText(FlxG.width / 2 - 28 - 4, 0, "YES"), null);
			// 	keyButtons.addButton(noKeys  = new BitmapText(FlxG.width / 2 + 4, 0, "NO"), null);
			// }
			// add(keyButtons);
		}
	}
	
	public function setup(text:String, onYes:Void->Void, ?onNo:Void->Void, ?onChoose:Void->Void):Void {
		
		label.text = text;
		label.x = (FlxG.width - label.width) / 2 + 1;
		label.y = box.y + 8;
		
		if (forceMouse) {
			
			// if(!FlxG.onMobile)
			// 	FlxG.mouse.visible = true;
			
			yesMouse.y = box.y + box.height - yesMouse.height - 4;
			yesMouse.onUp.callback = onDecide.bind(onYes, onChoose);
			
			if (noMouse != null) {
				noMouse.y = yesMouse.y;
				noMouse.onUp.callback = onDecide.bind(onNo , onChoose);
			}
			
		} else {
			
			// yesKeys.y = label.y + label.lineHeight * 3 + 2;
			// keyButtons.setCallback(yesKeys, onDecide.bind(onYes, onChoose));
			
			// if (noKeys != null) {
			// 	noKeys .y = label.y + label.lineHeight * 3 + 2;
			// 	keyButtons.setCallback(noKeys , onDecide.bind(onNo , onChoose));
			// }
		}
	}
	
	function onDecide(callback:Void->Void, onChoose:Void->Void) {
		
		if (forceMouse) {
			
			yesMouse.onUp.callback = null;
			if (noMouse != null)
				noMouse.onUp.callback = null;
			
			// if(!FlxG.onMobile)
			// 	FlxG.mouse.visible = false;
			
		} else {
			
			// keyButtons.setCallback(yesKeys, null);
			// if (noKeys != null)
			// 	keyButtons.setCallback(noKeys , null);
		}
		
		// Sounds.play(MENU_SELECT);
		
		if (callback != null)
			callback();
		
		if (onChoose != null)
			onChoose();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		var goBack = false;
		if (FlxG.keys.anyPressed([X, ESCAPE]))
			goBack = true;
		
		if (!goBack && FlxG.gamepads.lastActive != null)
			goBack = FlxG.gamepads.lastActive.anyPressed([B, BACK]);
		
		if (goBack)
			cancel();
	}
	
	function cancel():Void
	{
		if (forceMouse)
		{
			if (noMouse != null)
				noMouse.onUp.fire();
			else // single button prompt
				yesMouse.onUp.fire();
		}
		// else
		//	
	}
	
	/**
	 * Shows a single-button prompt and enables/disables the specified button group
	 * @param text    the dialog messsage.
	 * @param buttons the active ui group being interrupted.
	 */
	static public function showOKInterrupt(text:String, ?interruptee:FlxBasic):Void {
		
		var prompt = new Prompt(true);
		var parent = FlxG.state;
		parent.add(prompt);
		
		if (interruptee != null)
			interruptee.active = false;
		
		prompt.setup(text, null, null,
			function () {
				
				parent.remove(prompt);
				
				if (interruptee != null)
					interruptee.active = true;
			}
		);
	}
}