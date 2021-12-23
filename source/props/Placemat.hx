package props;

import data.Order;
import props.GhostPlayer;
import states.OgmoState;
import states.rooms.RoomState;
import utils.DebugLine;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef NamedEntity = { name:String };

class Placemat extends FlxSprite
    implements IInteractable
{
    inline static var MAX_BITE_TIME = 30.0;
    inline static var MIN_BITE_TIME = 1.0;
    
    inline static var NUM_BITES = 5;
    inline static var NUM_FRAMES = 2;
    
    public var seat:FlxObject;
    public var patron:Player;
    public var name:String;
    public var hitTarget(get, never):FlxObject;
    inline function get_hitTarget() return seat;
    public var canInteract = true;
    public var needsService = false;
    public var timer = FlxG.random.float(MIN_BITE_TIME, MAX_BITE_TIME);
    
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
                animation.add('${order}_${bite}', [order.toFrame(bite / NUM_BITES)]);
            }
        }
        
        visible = false;
    }
    
    public function checkServiceNeeds()
    {
        final isPatronSeated = getSeatedPatron() != null;
        needsService = isPatronSeated != getHasFood();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var patron = getSeatedPatron();
        if (patron != null
        && patron is GhostPlayer
        && visible
        && canInteract
        && getOrder() == COFFEE
        && getBitesLeft() > 0)
        {
            timer -= elapsed;
            if (timer < 0)
            {
                bite();
                timer = FlxG.random.float(MIN_BITE_TIME, MAX_BITE_TIME);
            }
        }
        
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
    
    public function service(waiter:Waiter)
    {
        final patronSeated = getSeatedPatron();
        final isPatronSeated = patronSeated != null;
        final hasFood = getHasFood();
        
        if (isPatronSeated && hasFood == false)
        {
            orderUp(patronSeated.state.order);
            waiter.onServe.dispatch(this);
        }
        
        if (isPatronSeated == false && hasFood)
        {
            var isRefill = visible;
            bus();
            
            if (isRefill)
                waiter.onBus.dispatch(this);
            else
                waiter.onRefill.dispatch(this);
        }
    }
    
    public function getHasFood()
    {
        return visible
            && getBitesLeft() > 0
            &&  (  patron == null
                || patron.state.order == getOrder()
                || patron.state.order == RANDOM
                );
    }
    
    public function orderUp(order:Order)
    {
        if (order == RANDOM)
            order = Order.random();
        animation.play('${order}_${NUM_BITES - 1}');
        visible = true;
    }
    
    public function bus()
    {
        timer = FlxG.random.float(MIN_BITE_TIME, MAX_BITE_TIME);
        patron = null;
        visible = false;
    }
    
    public function bite()
    {
        var bitesLeft = getBitesLeft();
        if (bitesLeft > 0)
        {
            canInteract = false;
            var anim = switch(getOrder())
            {
                case COFFEE: { y: patron.y - patron.frameHeight + 8, x: patron.x + (patron.width - width) / 2 };
                case DINNER: { y: y - 4 };
                case order: throw 'Unexpected order:$order';
            }
            
            FlxTween.tween(this, anim, 0.25,
                { ease:FlxEase.cubeOut
                , loopDelay: 1.0
                , type: PINGPONG
                ,   onComplete: (tween)->
                    {
                        if (tween.executions == 2)
                        {
                            canInteract = true;
                            tween.cancel();
                        }
                        else
                            animation.play(getOrder() + "_" + (bitesLeft - 1));
                    }
                ,   onUpdate: (_)->
                    {
                        x = Std.int(x);
                        y = Std.int(y);
                    }
                }
            );
        }
    }
    
    public function getOrder():Order return cast animation.curAnim.name.split("_")[0];
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