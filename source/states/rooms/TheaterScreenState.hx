package states.rooms;

import data.Net;
import props.CafeTable;
import props.GhostPlayer;
import props.Player;
import props.Placemat;
import props.SpeechBubble;
import props.Waiter;
import states.OgmoState;
import utils.DebugLine;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;

class TheaterScreenState extends RoomState
{
    var seats = new FlxTypedGroup<FlxObject>();
    var spots = new Map<FlxObject, Placemat>();
    var tableSeats = new Map<FlxObject, CafeTable>();
    var waiters = new Array<Waiter>();
    var waiterNodes:OgmoPath = null;
    var tables = new Array<CafeTable>();
    var patrons = new Map<Player, Placemat>();
    
    override function create()
    {
        super.create();
    }
}