package ui;

import ui.Button;
import ui.Font;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;

using flixel.util.FlxSpriteUtil;

class Prompt extends flixel.group.FlxGroup
{
	inline static var BUFFER = 6;
	
	var box:FlxSprite;
	var label:FlxBitmapText;
	var yes:Button;
	var no:Button;
	
	public function new ()
	{
		super();
		
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
		
		add(yes = new YesButton(FlxG.width / 2 - 28 - 16, 0));
		add(no  = new NoButton (FlxG.width / 2      + 16, 0));
	}
	
	public function setupTextOnly(text)
	{
		label.text = text;
		label.x = (FlxG.width - label.width) / 2 + 1;
		label.y = box.y + 8;
		yes.visible = false;
		no.visible = false;
	}
	
	public function setupOk(text, onYes):Void
	{
		setupHelper(text, true, onYes);
	}
	
	public function setupYesNo(text, onYes, ?onNo, ?onChoose):Void
	{
		setupHelper(text, false, onYes, onNo, onChoose);
	}
	
	function setupHelper(text:String, singleButton:Bool, onYes:Void->Void, ?onNo:Void->Void, ?onChoose:Void->Void):Void
	{
		label.text = text;
		label.x = (FlxG.width - label.width) / 2 + 1;
		label.y = box.y + 8;
		
		yes.visible = true;
		yes.y = box.y + box.height - yes.height - 4;
		yes.onUp.callback = onDecide.bind(onYes, onChoose);
		
		if (singleButton)
		{
			no.visible = false;
			yes.x = (FlxG.width - 28) / 2;
			yes.setGraphic('assets/images/ui/buttons/ok.png');
		}
		else
		{
			yes.x = FlxG.width / 2 - 28 - 16;
			yes.setGraphic('assets/images/ui/buttons/yes.png');
			no.visible = true;
			no.x  = FlxG.width / 2      + 16;
			no.y = yes.y;
			no.onUp.callback = onDecide.bind(onNo , onChoose);
		}
	}
	
	function onDecide(callback:Void->Void, onChoose:Void->Void) {
		
		yes.onUp.callback = null;
		if (no != null)
			no.onUp.callback = null;
			
		// if(!FlxG.onMobile)
		// 	FlxG.mouse.visible = false;
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
		if (Controls.pressed.B)
			goBack = true;
		
		if (goBack)
			cancel();
	}
	
	function cancel():Void
	{
		if (no != null)
			no.onUp.fire();
		else // single button prompt
			yes.onUp.fire();
	}
	
	/**
	 * Shows a single-button prompt and enables/disables the specified button group
	 * @param text    the dialog messsage.
	 * @param buttons the active ui group being interrupted.
	 */
	static public function showOKInterrupt(text:String, ?interruptee:FlxBasic):Void {
		
		var prompt = new Prompt();
		var parent = FlxG.state;
		parent.add(prompt);
		
		if (interruptee != null)
			interruptee.active = false;
		
		prompt.setupOk(text,
			function () {
				
				parent.remove(prompt);
				
				if (interruptee != null)
					interruptee.active = true;
			}
		);
	}
}