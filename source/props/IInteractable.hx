package props;

import flixel.FlxObject;

interface IInteractable
{
    var canInteract:Bool;
    var hitTarget(get, never):FlxObject;
}