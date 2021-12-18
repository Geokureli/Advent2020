package props;

import utils.DebugLine;
import states.OgmoState;
import states.rooms.RoomState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

typedef NamedEntity = { name:String };

class Placemat extends FlxSprite
{
    inline static var NUM_BITES = 5;
    inline static var NUM_FRAMES = 2;
    
    public var seat:FlxObject;
    public var patron:Player;
    public var name:String;
    public var hasFood(get, never):Bool;
    inline function get_hasFood() return visible;
    
    #if debug
    var line:DebugLine;
    #end
    
    public function new (x, y, name:String)
    {
        this.name = name;
        super(x, y);
        setup();
    }
    
    #if debug
    function initDebugLine()
    {
        line = new DebugLine(0,0,0,0, 1, 0xFFff0000);
        var room = Std.downcast(FlxG.state, RoomState);
        line.camera = room.debugCamera;
        @:privateAccess
        room.topGround.add(line);
        line.visible = false;
    }
    #end
    
    function setup()
    {
        loadGraphic("assets/images/props/cafe/placemat.png", true, 12, 8);
        
        for (i in 0...NUM_BITES)
        {
            for (j=>order in Order.list)
            {
                final bite = NUM_BITES - i - 1;
                final frame = Math.ceil(bite / NUM_BITES * NUM_FRAMES);
                animation.add('${order}_${bite}', [NUM_FRAMES * j]);
            }
        }
        
        visible = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        #if debug
        
        if (line == null && patron != null)
            initDebugLine();
        
        if (line != null)
        {
            line.visible = patron != null;
            if (line.visible)
            {
                line.x1 = seat.x;
                line.y1 = seat.y;
                line.x2 = patron.x;
                line.y2 = patron.y;
            }
        }
        #end
    }
    
    inline public function randomOrderUp(allowNothing = false)
    {
        var max = Order.list.length;
        if (allowNothing == false)
            max--;
            
        var ran = FlxG.random.int(0, max);
        if (ran < Order.list.length)
            orderUp(Order.list[ran]);
    }
    
    public function orderUp(order:Order)
    {
        animation.play('${order}_${NUM_BITES - 1}');
        visible = true;
    }
    
    public function bus()
    {
        patron = null;
        visible = false;
    }
    
    public function bite()
    {
        var bitesLeft = getBitesLeft();
        if (bitesLeft > 0)
            animation.play(getOrder() + "_" + (bitesLeft - 1));
    }
    
    public function getOrder() return animation.curAnim.name.split("_")[0];
    public function getBitesLeft() return Std.parseInt(animation.curAnim.name.split("_")[1]);
    
    public function getSeatedPatron()
    {
        if (patron != null && patron.overlaps(seat))
            return patron;
        return null;
    }
    
    static public function fromEntity(data:OgmoEntityData<NamedEntity>)
    {
        var placemat = new Placemat(data.x, data.y, data.values.name);
        // data.applyToSprite(placemat);
        placemat.flipX = data.flippedX;
        placemat.setup();
        return placemat;
    }
}

enum abstract Order(String) to String
{
    static public final list = [DINNER, COFFEE];
    
    var DINNER = "dinner";
    var COFFEE = "coffee";
}