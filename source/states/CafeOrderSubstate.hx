package states;

import data.Order;
import data.PlayerSettings;
import data.Save;
import ui.Controls;
import ui.Button;
import props.Placemat;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

class CafeOrderSubstate extends flixel.FlxSubState
{
    inline static var BAR_MARGIN = 8;
    inline static var SIDE_GAP = 48;
    inline static var SPACING = 28;
    
    var sprites = new FlxTypedSpriteGroup<OrderDisplay>();
    var current = 0;
    var nameText = new FlxBitmapText();
    var descText = new FlxBitmapText();
    var arrowLeft:Button;
    var arrowRight:Button;
    var ok:OkButton;
    // prevents instant selection
    var wasAReleased = false;
    
    var currentSprite(get, never):OrderDisplay;
    inline function get_currentSprite() return sprites.members[current];
    var currentOrder(get, never):OrderData;
    inline function get_currentOrder() return OrderData.list[current];
    
    override function create()
    {
        super.create();
        
        camera = new FlxCamera().copyFrom(camera);
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera, false);
        
        var bg = new FlxSprite();
        add(bg);
        add(sprites);
        
        var instructions = new FlxBitmapText();
        instructions.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        instructions.text = "Select your order";
        instructions.screenCenter(X);
        instructions.y = 32;
        instructions.scrollFactor.set(0, 0);
        instructions.alignment = CENTER;
        instructions.scale.set(2, 2);
        add(instructions);
        
        createMenu();
        
        var top:Float = FlxG.height;
        var bottom:Float = 0;
        for (sprite in sprites)
        {
            top = Math.min(top, sprite.y);
            bottom = Math.max(bottom, sprite.y + sprite.height);
        }
        
        top -= BAR_MARGIN;
        
        nameText.text = currentOrder.name;
        nameText.screenCenter(X);
        nameText.y = top - nameText.height;
        nameText.scrollFactor.set(0, 0);
        top -= nameText.height + BAR_MARGIN;
        add(nameText);
        
        descText.text = currentOrder.description;
        descText.alignment = CENTER;
        descText.fieldWidth = Std.int(FlxG.width * .75);
        descText.width = descText.fieldWidth;
        descText.height = 1000;
        descText.wordWrap = true;
        descText.screenCenter(X);
        descText.y = bottom + BAR_MARGIN;
        descText.scrollFactor.set(0, 0);
        bottom += descText.height + BAR_MARGIN * 2;
        add(descText);
        
        if (!FlxG.onMobile)
        {
            var keysText = new FlxBitmapText();
            keysText.text = "Arrow Keys to Select, Space to confrim";
            keysText.x = 10;
            keysText.y = FlxG.height - keysText.height;
            keysText.scrollFactor.set(0, 0);
            keysText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            add(keysText);
        }
        
        bg.y = top;
        bg.makeGraphic(FlxG.width, Std.int(bottom - top), 0xFF555555);
        bg.scrollFactor.set(0, 0);
        
        add(arrowLeft  = new Button(0, 0, toPrev, "assets/images/ui/leftArrow.png"));
        arrowLeft.x  = (FlxG.width - arrowLeft.width  - SIDE_GAP - SPACING) / 2;
        arrowLeft.y  = bg.y + (bg.height - arrowLeft.height ) / 2;
        arrowLeft.scrollFactor.set(0, 0);
        add(arrowRight = new Button(0, 0, toNext, "assets/images/ui/rightArrow.png"));
        arrowRight.x = (FlxG.width - arrowRight.width + SIDE_GAP + SPACING) / 2;
        arrowRight.y = bg.y + (bg.height - arrowRight.height) / 2;
        arrowRight.scrollFactor.set(0, 0);
        add(ok = new OkButton(0, 0, select));
        ok.screenCenter(X);
        ok.y = bottom + BAR_MARGIN;
        ok.scrollFactor.set(0, 0);
        
        hiliteCurrent();
    }
    
    public function createMenu()
    {
        for (i=>data in OrderData.list)
        {
            var sprite = new OrderDisplay(data);
            sprites.add(sprite);
            sprite.scale.set(2, 2);
            sprite.updateHitbox();
            sprite.scrollFactor.set(0, 0);
            
            sprite.x = SPACING * i;
            
            if (i == current)
            {
                sprite.x += SIDE_GAP;
                camera.follow(sprite);
            }
            else if (i > current && current > -1)
                sprite.x += SIDE_GAP * 2;
            
            sprite.y = (FlxG.height - sprites.members[0].height) / 2;
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!wasAReleased && Controls.released.A)
            wasAReleased = true;
        
        if (Controls.justPressed.RIGHT)
            toNext();
        if (Controls.justPressed.LEFT)
            toPrev();
        if (Controls.justPressed.A && wasAReleased)
            select();
        if (Controls.justPressed.B)
            close();
    }
    
    function toNext():Void
    {
        if(current >= sprites.length - 1)
            return;
        
        unhiliteCurrent();
        currentSprite.x -= SIDE_GAP;
        current++;
        currentSprite.x -= SIDE_GAP;
        hiliteCurrent();
    }
    
    function toPrev():Void
    {
        if(current <= 0)
            return;
        
        unhiliteCurrent();
        currentSprite.x += SIDE_GAP;
        current--;
        currentSprite.x += SIDE_GAP;
        hiliteCurrent();
    }
    
    function unhiliteCurrent()
    {
    }
    
    function hiliteCurrent()
    {
        sprites.x = (current+1) * -SPACING - BAR_MARGIN*2 + (FlxG.width - currentSprite.width) / 2;
        
        nameText.text = currentOrder.name;
        descText.text = currentOrder.description;
        nameText.screenCenter(X);
        descText.screenCenter(X);
    }
    
    function select():Void
    {
        Save.setOrder(currentOrder.order);
        PlayerSettings.user.order = currentOrder.order;
        close();
    }
    
    override function close()
    {
        FlxG.cameras.remove(camera);
        super.close();
    }
}

@:forward
private abstract OrderDisplay(FlxSprite) to FlxSprite
{
    public function new (data:OrderData)
    {
        this = new FlxSprite();
        this.loadGraphic("assets/images/props/cafe/placemat.png", true, 12, 8);
        
        this.animation.add('anim', [data.order.toFrame()]);
        this.animation.play('anim');
    }
}

@:forward
private abstract DrinkData(OrderData) to OrderData
{
    inline public function new (name:String, description:String)
    {
        this = new OrderData(COFFEE, name, description);
    }
}

@:forward
private abstract DinnerData(OrderData) to OrderData
{
    inline public function new (name:String, description:String)
    {
        this = new OrderData(DINNER, name, description);
    }
}

private class OrderData
{
    static public var list:Array<OrderData> = 
    // coffee
    [ new DrinkData("Espresso"       , "Brewed by forcing a small amount of boiling pressurized water through finely ground coffee beans")
    , new DrinkData("Latte"          , "2 ounces of espresso and 10 ounces of steamed milk with a nice thin layer of foam across the top")
    , new DrinkData("Latte(Mocha)"   , "Chocolate syrup made in-house")
    , new DrinkData("Latte(Vanilla)" , "The crowd pleaser")
    , new DrinkData("Latte(Almond)"  , "Warm and cozy")
    , new DrinkData("Latte(Amaretto)", "Feeling adventurous?")
    , new DrinkData("Cappuccino"     , "2 ounces of espresso, 4 ounces of steamed milk, and a thicker layer of foam on top")
    , new DrinkData("Flat White"     , "\"like a latte with a little less milk and more espresso.\" - Hugh Jackman")
    , new DrinkData("Black Coffee"   , "You don't like to mess around, huh?")
    , new DrinkData("Americano"      , "Espresso shots topped with hot water")
    // tea
    , new DrinkData("English Breakfast", "Has a rich and hearty flavor and is often enjoyed with milk and sugar")
    , new DrinkData("Darjeeling"       , "A black tea with a light, nutty taste to it and a floral smell")
    , new DrinkData("Matcha"           , "A green tea, high in antioxidants and nutrients")
    , new DrinkData("Chai"             , "A milky, sugary, and spicy beverage originating from India")
    , new DrinkData("Earl Grey"        , "Made mostly with Black tea, Earl Grey has smoky, fragrant, and citrus tones")
    , new DrinkData("Jasmine"          , "Has a delicate aroma and a refreshing flavor")
    , new DrinkData("Chamomile"        , "Is known for its soothing properties with a floral flavoring")
    , new DrinkData("Oolong"           , "Falls between Green and Black Tea and is one of the top five true teas")
    , new DrinkData("Yerba Mate"       , "Includes high levels of caffeine and is often used as an alternative to coffee")
    , new DrinkData("Rooibos"          , "Light in flavor, this tea has health benefits for both the heart and liver")
    , new DrinkData("Pu’er"            , "Has earthy, mellow, and balanced undertones and has become popular over the last few years")
    , new DrinkData("Lapsang Souchong" , "A black tea with a smoky aftertaste")
    , new DrinkData("Mint"             , "Tastes like mint leaves and helps to soothe upset stomachs")
    , new DrinkData("Sencha"           , "Most famous in Japan for its bitter taste")
    // misc drink
    , new DrinkData("Hot Choccy", "With tiny marshmallows")
    , new DrinkData("House Soda", "Why is it in a mug?")
    // french
    , new DinnerData("Steak frites"       , "this simple, yet impressive recipe is inspired by French bistro cuisine")
    , new DinnerData("Chicken confit"     , "Salted and seasoned with herbs, then slow-cooked in olive oil until rich and tender")
    , new DinnerData("Salmon en papillote", "Locks all the moisture and flavours by wrapping fish in paper before cooking")
    , new DinnerData("Boeuf bourguignon"  , "Stylish haute cuisine for the man on a budget")
    , new DinnerData("Cassoulet"          , "The most debated casserole in history")
    , new DinnerData("Lamb shank navarin" , "Cooked low and slow until it melts in the mouth")
    , new DinnerData("Duck a l'Orange"    , "Designed to walk the tightrope of flavor")
    // curry
    , new DinnerData("Mutton Dhansak"      , "A sweet and sour profile, with a decent amount of spice to it")
    , new DinnerData("Chicken Tikka Masala", "You know it, you love it, you want it")
    , new DinnerData("Lamb Saag"           , "with spinach and mustard greens. A pleasant but noticeable degree of heat")
    , new DinnerData("Chicken Korma"       , "Yogurt-marinated Chicken with cardamom and cinnamon, mixed with butter and cream. All the zest without the burn")
    , new DinnerData("Vegetable Jalfrezi"  , "A strong but not overpowering heat. green chiles stir-fried with tomato, onion, and coriander")
    , new DinnerData("Pork Vindaloo"       , "Those with iron-clad stomachs and palates will find vindaloos to be a delicious meal every time")
    // breakfast
    , new DinnerData("English Breakfast" , "Yup it's all in there, all 17 components.")
    , new DinnerData("Green Eggs and Ham", "Would you, could you, in a cafe? We'll bring them out without delay")
    , new DinnerData("French Toast"      , "The green bit is just garnish, you can pick it off")
    , new DinnerData("Three Egg Omelete" , "Masterfully crafted to, somehow, look exactly like Duck a l'Orange when you squint your eyes")
    ];
    
    public var order:Order;
    public var name:String;
    public var description:String;
    
    public function new (order:Order, name:String, description:String)
    {
        this.order = order;
        this.name = name;
        this.description = description;
    }
}