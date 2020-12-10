package ui;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.keyboard.FlxKey;

class Controls extends flixel.FlxBasic
{
    static public var pressed     (default, null):ControlsList;
    static public var justPressed (default, null):ControlsList;
    static public var justReleased(default, null):ControlsList;
    static public var released    (default, null):ControlsList;
    
    @:allow(ui.Controls.ControlsList)
    static public var useKeys(default, null) = true;
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        trace(FlxG.gamepads.numActiveGamepads == 0, FlxG.keys.pressed.ANY, !FlxG.gamepads.anyPressed(ANY));
        useKeys = FlxG.gamepads.numActiveGamepads == 0 || FlxG.keys.pressed.ANY || !FlxG.gamepads.anyPressed(ANY);
    }
    
    static var instance:Controls = null;
    static public function init()
    {
        if (instance != null)
            FlxG.plugins.remove(instance);
        
        pressed      = new ControlsList(PRESSED);
        justPressed  = new ControlsList(JUST_PRESSED);
        justReleased = new ControlsList(JUST_RELEASED);
        released     = new ControlsList(RELEASED);
        
        instance = new Controls();
        FlxG.plugins.add(instance);
    }
}

class ControlsList
{
    static var keys:Map<Action, Array<FlxKey>> =
        [ UP    => [W, UP   ]
        , DOWN  => [S, DOWN ]
        , LEFT  => [A, LEFT ]
        , RIGHT => [D, RIGHT]
        , A     => [Z, J, SPACE]
        , B     => [X, K, ESCAPE]
        , PAUSE => [P, ENTER]
        ];
    
    static var buttons:Map<Action, Array<FlxGamepadInputID>> =
        [ UP    => [DPAD_UP   , LEFT_STICK_DIGITAL_UP   ]
        , DOWN  => [DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN ]
        , LEFT  => [DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT ]
        , RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]
        , A     => [A, X]
        , B     => [B, Y]
        , PAUSE => [START]
        ];
    
    var state:FlxInputState;
    
    public function new (state:FlxInputState)
    {
        this.state = state;
    }
    
    public function check(action:Action)
    {
        return Controls.useKeys ? checkKeys(action) : checkButtons(action);
    }
    
    function checkKeys(action:Action)
    {
        @:privateAccess
        return FlxG.keys.checkKeyArrayState(keys[action], state);
    }
    
    function checkButtons(action:Action)
    {
        for (buttonId in buttons[action])
        {
            @:privateAccess
            if (FlxG.gamepads.anyHasState(buttonId, state))
                return true;
        }
        return false;
    }
    
    public var UP   (get, never):Bool; inline function get_UP   () return check(Action.UP   );
    public var DOWN (get, never):Bool; inline function get_DOWN () return check(Action.DOWN );
    public var LEFT (get, never):Bool; inline function get_LEFT () return check(Action.LEFT );
    public var RIGHT(get, never):Bool; inline function get_RIGHT() return check(Action.RIGHT);
    public var A    (get, never):Bool; inline function get_A    () return check(Action.A    );
    public var B    (get, never):Bool; inline function get_B    () return check(Action.B    );
    public var PAUSE(get, never):Bool; inline function get_PAUSE() return check(Action.PAUSE);
}

private enum Action
{
    UP;
    DOWN;
    LEFT;
    RIGHT;
    A;
    B;
    PAUSE;
}