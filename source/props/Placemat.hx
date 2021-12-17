package props;

import states.OgmoState;

import flixel.FlxG;
import flixel.FlxSprite;

typedef NamedEntity = { name:String };

@:forward
abstract Placemat(FlxSprite) to FlxSprite
{
    inline static var NUM_BITES = 5;
    inline static var NUM_FRAMES = 2;
    
    public function new (x, y)
    {
        this = new FlxSprite(x, y);
        setup();
    }
    
    function setup()
    {
        this.loadGraphic("assets/images/props/cafe/placemat.png", true, 18, 7);
        
        for (i in 0...NUM_BITES)
        {
            for (j=>order in Order.list)
            {
                final bite = NUM_BITES - i - 1;
                final frame = Math.ceil(bite / NUM_BITES * NUM_FRAMES);
                this.animation.add('${order}_${bite}', [NUM_FRAMES * j]);
            }
        }
        
        this.visible = false;
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
        this.animation.play('${order}_${NUM_BITES - 1}');
        this.visible = true;
    }
    
    public function getOrder() return this.animation.curAnim.name.split("_")[0];
    public function getBitesLeft() return this.animation.curAnim.name.split("_")[1];
    
    static public function fromEntity(data:OgmoEntityData<NamedEntity>)
    {
        var placemat:Placemat = cast OgmoEntityData.createFlxSprite(data);
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