package ui;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class Controls extends flixel.FlxBasic
{
    static public var pressed     (default, null):ControlsList;
    static public var justPressed (default, null):ControlsList;
    static public var justReleased(default, null):ControlsList;
    static public var released    (default, null):ControlsList;
    
    static public var mode(default, null) = Keys;
    static public var useKeys (get, never):Bool; inline static function get_useKeys () return mode == Keys;
    static public var useTouch(get, never):Bool; inline static function get_useTouch() return mode == Touch;
    static public var usePad  (get, never):Bool; inline static function get_usePad  () return mode == Gamepad;
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        mode = switch (mode)
        {
            case Keys if (FlxG.keys.pressed.ANY): Keys;
            case Keys if (FlxG.gamepads.anyPressed(ANY)): Gamepad;
            case Gamepad if (FlxG.gamepads.anyPressed(ANY)): Gamepad;
            case Gamepad if (FlxG.keys.pressed.ANY): Gamepad; 
            case _: mode;
        }
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
        instance.active = !FlxG.onMobile;
        FlxG.plugins.add(instance);
    }
}

class ControlsList
{
    static var keys:Map<Action, Array<FlxKey>> =
        [ UP       => [W, UP   ]
        , DOWN     => [S, DOWN ]
        , LEFT     => [A, LEFT ]
        , RIGHT    => [D, RIGHT]
        , A        => [Z, J, SPACE]
        , B        => [X, K, ESCAPE]
        , PAUSE    => [P, ENTER]
        , ZOOM_IN  => [PERIOD]
        , ZOOM_OUT => [COMMA]
        ];
    
    static var buttons:Map<Action, Array<FlxGamepadInputID>> =
        [ UP       => [DPAD_UP   , LEFT_STICK_DIGITAL_UP   ]
        , DOWN     => [DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN ]
        , LEFT     => [DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT ]
        , RIGHT    => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]
        , A        => [A, X]
        , B        => [B, Y]
        , PAUSE    => [START]
        , ZOOM_IN  => [RIGHT_TRIGGER, RIGHT_STICK_DIGITAL_UP]
        , ZOOM_OUT => [RIGHT_TRIGGER, RIGHT_STICK_DIGITAL_UP]
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
    
    public var UP      (get, never):Bool; inline function get_UP      () return check(Action.UP      );
    public var DOWN    (get, never):Bool; inline function get_DOWN    () return check(Action.DOWN    );
    public var LEFT    (get, never):Bool; inline function get_LEFT    () return check(Action.LEFT    );
    public var RIGHT   (get, never):Bool; inline function get_RIGHT   () return check(Action.RIGHT   );
    public var A       (get, never):Bool; inline function get_A       () return check(Action.A       );
    public var B       (get, never):Bool; inline function get_B       () return check(Action.B       );
    public var PAUSE   (get, never):Bool; inline function get_PAUSE   () return check(Action.PAUSE   );
    public var ZOOM_IN (get, never):Bool; inline function get_ZOOM_IN () return check(Action.ZOOM_IN );
    public var ZOOM_OUT(get, never):Bool; inline function get_ZOOM_OUT() return check(Action.ZOOM_OUT);
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
    ZOOM_IN;
    ZOOM_OUT;
}

enum ControlMode
{
    Touch;
    Keys;
    Gamepad;
}