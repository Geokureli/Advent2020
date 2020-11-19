package states;

import vfx.Inline;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;

import states.OgmoState;
import props.InfoBox;
import props.InputPlayer;

/**
 * ...
 * @author NInjaMuffin99
 */
class BaseState extends OgmoState 
{
    static var outlineShader = new Inline();
    
    var camOffset = 0.0;
    var camFollow = new FlxObject();
    
    var player:InputPlayer;
    
    var colliders = new FlxGroup();
    var characters = new FlxGroup();
    var touchable = new FlxTypedGroup<FlxObject>();
    var infoBoxes = new Map<FlxObject, InfoBox>();
    var infoBoxGroup = new FlxTypedGroup<InfoBox>();
    var lastTouched:FlxObject = null;
    
    public var geom(default, null):FlxTilemap;
    public var props(default, null):OgmoEntityLayer;
    public var foreground(default, null):OgmoDecalLayer;
    public var background(default, null):OgmoDecalLayer;
    
    override public function create():Void 
    {
        super.create();
        
        FlxG.mouse.visible = !FlxG.onMobile;
        // #if debug FlxG.debugger.drawDebug = true; #end
        
        entityTypes["Player"] = InputPlayer.new.bind(0, 0, 0xFFFFFF);
        entityTypes["TvBubble"] = FlxSprite.new.bind(0, 0, "assets/images/props/cabin/tv_bubble.png");
        entityTypes["Teleport"] = FlxObject.new.bind(0, 0, 0, 0);
        loadLevel();
        initEntities();
        initCamera();
        
        add(infoBoxGroup);
    }
    
    function loadLevel() { }
    
    function initEntities()
    {
        props = getByName("Props");
        foreground = getByName("Foreground");
        background = getByName("Background");
        
        geom = getByName("Geom");
        colliders.add(geom);
        
        player = cast props.getByName("Player");
        for (child in props.members)
        {
            var sorting = Sorting.Y;
            if (Std.is(child, ISortable))
                sorting = (cast child:ISortable).sorting;
            
            switch(sorting)
            {
                case Sorting.Top, Sorting.None:
                case Sorting.Y: foreground.add(cast props.remove(child));
                case Sorting.Bottom: background.add(cast props.remove(child));
            }
        }
        
        characters.add(player);
    }
    
    function addHoverText(target:String, ?text:String, ?callback:Void->Void, hoverDis = 20)
    {
        var decal:FlxObject = foreground.getByName(target);
        if (decal == null)
            decal = cast props.getByName(target);
        if (decal == null)
            throw 'can\'t find $target in foreground or props';
        
        addHoverTextTo(decal, text, callback, hoverDis);
    }
    
    function safeAddHoverText(target:String, ?text:String, ?callback:Void->Void, hoverDis = 20)
    {
        var decal:FlxObject = foreground.getByName(target);
        if (decal == null)
            decal = cast props.getByName(target);
        if (decal != null)
            addHoverTextTo(decal, text, callback, hoverDis);
    }
    
    function addHoverTextTo(target:FlxObject, ?text:String, ?callback:Void->Void, hoverDis = 20)
    {
        addHoverTo(target, cast new InfoTextBox(text, callback), hoverDis);
    }
    
    inline function addThumbnailTo(target:FlxObject, ?asset, ?callback:Void->Void)
    {
        var thumbnail:FlxSprite = null;
        if (asset != null)
        {
            thumbnail = new FlxSprite(0, 0, asset);
            thumbnail.x = -thumbnail.width / 2;
            thumbnail.y = -thumbnail.height - 8;
            //hoverDis += Std.int(thumbnail.height);
        }
        
        return addHoverTo
            ( target
            , new InfoBox(thumbnail, callback)
            , 0
            );
    }
    
    inline function addHoverTo(target:FlxObject, box:InfoBox, hoverDis = 20)
    {
        inline removeHoverFrom(target);
        
        touchable.add(target);
        box.updateFollow(target);
        box.hoverDis = hoverDis;
        infoBoxGroup.add(infoBoxes[target] = cast box);
        return box;
    }
    
    function removeHoverFrom(target:FlxObject)
    {
        if (infoBoxes.exists(target))
        {
            var box = infoBoxes[target];
            infoBoxes.remove(target);
            touchable.remove(target);
            infoBoxGroup.remove(box);
        }
    }
    
    function initCamera()
    {
        // if (FlxG.onMobile)
        // {
        //     var button = new FullscreenButton(10, 10);
        //     button.scrollFactor.set();
        //     add(button);
        // }
        
        camFollow.setPosition(player.x, player.y - camOffset);
        FlxG.camera.follow(camFollow, FlxCameraFollowStyle.LOCKON, 0.03);
        FlxG.camera.focusOn(camFollow.getPosition());
        FlxG.camera.fade(FlxG.stage.color, 2.5, true);
    }
    
    override public function update(elapsed:Float):Void 
    {
        FlxG.watch.addMouse();
        
        camFollow.setPosition(player.x, player.y - camOffset);
        
        FlxG.collide(characters, colliders);
        
        for (child in touchable.members)
        {
            if (infoBoxes.exists(child))
            {
                infoBoxes[child].updateFollow(child);
            }
        }
        
        var firstTouched:FlxObject = null;
        FlxG.overlap(player.hitbox, touchable,
            function(box:FlxObject, touched:FlxObject)
            {
                if (firstTouched == null && infoBoxes.exists(touched))
                {
                    firstTouched = touched;
                    
                    if (player.interacting)
                        infoBoxes[touched].interact();
                }
            }
        );
        
        
        if (lastTouched != firstTouched)
        {
            if (lastTouched != null)
            {
                infoBoxes[lastTouched].alive = false;
                if (Std.is(lastTouched, FlxSprite))
                {
                    final sprite = Std.downcast(lastTouched, FlxSprite);
                    sprite.shader = null;
                }
            }
            
            lastTouched = firstTouched;
            
            if (lastTouched != null)
            {
                infoBoxes[lastTouched].alive = true;
                if (Std.is(lastTouched, FlxSprite))
                {
                    final sprite = Std.downcast(lastTouched, FlxSprite);
                    sprite.shader = outlineShader;
                }
            }
        }
        
        foreground.sort(FlxSort.byY);
        
        super.update(elapsed);
        
        #if debug
        if (FlxG.keys.justPressed.B)
            FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
        #end
    }
    
    override function destroy()
    {
        super.destroy();
        
        infoBoxes.clear();
    }
}