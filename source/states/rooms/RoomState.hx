package states.rooms;

import data.NGio;
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

import data.Game;
import data.Net;
import data.PlayerSettings;
import props.GhostPlayer;
import props.InfoBox;
import props.InputPlayer;
import props.Player;
import props.Present;
import props.Teleport;
import states.OgmoState;
import vfx.Inline;

import Types;
import io.colyseus.Room;
import schema.GameState;

typedef RoomConstructor = (String)->RoomState;

class RoomState extends OgmoState 
{
    static var outlineShader = new Inline();
    
    var camOffset = 0.0;
    var camFollow = new FlxObject();
    
    var player:InputPlayer;
    var avatars = new FlxTypedGroup<Player>();
    var ghosts:Map<String, GhostPlayer> = [];
    var teleports = new FlxTypedGroup<Teleport>();
    var spawnTeleport:Teleport;
    
    var colliders = new FlxGroup();
    var characters = new FlxGroup();
    var touchable = new FlxTypedGroup<FlxObject>();
    var infoBoxes = new Map<FlxObject, InfoBox>();
    var infoBoxGroup = new FlxTypedGroup<InfoBox>();
    var lastTouched:FlxObject = null;
    
    public var name(default, null):RoomName;
    public var spawnId(default, null) = -1;
    
    public var geom(default, null):FlxTilemap;
    public var props(default, null):OgmoEntityLayer;
    public var foreground(default, null):OgmoDecalLayer;
    public var background(default, null):OgmoDecalLayer;
    
    public function new(target:String)
    {
        if (target.indexOf(".") != -1)
        {
            final split = target.split(".");
            spawnId = Std.parseInt(split.pop());
            target = split.join(".");
        }
        
        name = cast target;
        
        super();
    }
    
    override public function create():Void 
    {
        super.create();
        
        FlxG.mouse.visible = !FlxG.onMobile;
        // #if debug FlxG.debugger.drawDebug = true; #end
        
        // No @:arrayAccess function for Map<String, (OgmoEntityData<Dynamic>)->FlxObject> accepts arguments of String and (OgmoEntityData<Dynamic>)->Void
        entityTypes["Teleport"] = cast function(data)
        {
            var teleport = Teleport.fromEntity(data);
            teleports.add(teleport);
            return teleport;
        }
        entityTypes["Present"] = cast Present.fromEntity;
        loadLevel();
        initEntities();
        initCamera();
        initClient();
        
        add(infoBoxGroup);
    }
    
    function loadLevel()
    {
        parseLevel('assets/data/ogmo/${name}1.json');
    }
    
    function initEntities()
    {
        props = getByName("Props");
        foreground = getByName("Foreground");
        background = getByName("Background");
        
        geom = getByName("Geom");
        colliders.add(geom);
        
        for (teleport in teleports.members)
        {
            if (spawnId == teleport.id)
                spawnTeleport = teleport;
        }
        
        if (spawnTeleport == null)
        {
            throw spawnId != -1
                ? 'Could not find a teleport with a id of $spawnId'
                : 'Missing the default spawn point'
                ;
        }
        
        player = new InputPlayer();
        player.x = spawnTeleport.x + (spawnTeleport.width - player.width) / 2;
        player.y = spawnTeleport.y + (spawnTeleport.height - player.height) / 2;
        foreground.add(player);
        
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
    }
    
    function initClient()
    {
        if (Net.isNetRoom(name))
            Net.joinRoom(name, onRoomJoin);
    }
    
    function onRoomJoin(error:String, room:Room<GameState>)
    {
        if (error != null)
        {
            trace("JOIN ERROR: " + error);
            return;
        }
        
        room.state.avatars.onAdd = (avatarData, key) ->
        {
            // trace("avatar added at " + key + " => " + avatar);
            trace(room.sessionId + ' added: $key=>${avatarData.name} ${avatarData.skin}@(${avatarData.x}, ${avatarData.y})');
            
            if (key != room.sessionId)
            {
                // trace(room.sessionId + ' this AINT you');
                if (!ghosts.exists(key))
                {
                    var settings = new PlayerSettings(avatarData.skin);
                    var ghost = new GhostPlayer(key, avatarData.name, avatarData.x, avatarData.y, settings);
                    ghosts[key] = ghost;
                    avatars.add(ghost);
                    foreground.add(ghost);
                    avatarData.onChange = ghost.onChange;
                }
            }
            // else
            //     trace(room.sessionId + " this is you!");
        }
        
        room.state.avatars.onRemove = (avatarData, key) ->
        {
            if (ghosts.exists(key))
            {
                var ghost = ghosts[key];
                ghosts.remove(key);
                avatars.remove(ghost);
                avatarData.onChange = null;
            }
        }
        
        // room.state.entities.onChange = function onEntityChange(entity, key)
        // {
        //     trace("entity changed at " + key + " => " + entity);
        // }
        
        // room.onStateChange += process_state_change;
        Net.send("avatar", 
            { x:Std.int(player.x)
            , y:Std.int(player.y)
            , skin:player.settings.skin
            , name:NGio.userName
            , state:Idle
            }
        );
    }
    
    override public function update(elapsed:Float):Void 
    {
        var touchingSpawn = false;
        FlxG.overlap(player, teleports,
            function(_, teleport)
            {
                if (teleport == spawnTeleport)
                    touchingSpawn = true;
                else if (teleport.target != "")
                    activateTeleport(teleport.target);
            }
        );
        
        if (!touchingSpawn)
            spawnTeleport = null;
        
        if (player.x < FlxG.worldBounds.left)
            player.x = FlxG.worldBounds.left;
        
        if (player.x > FlxG.worldBounds.right - player.width)
            player.x = FlxG.worldBounds.right - player.width;
        
        if (player.y < FlxG.worldBounds.top)
            player.y = FlxG.worldBounds.top;
        
        if (player.y > FlxG.worldBounds.bottom - player.height)
            player.y = FlxG.worldBounds.bottom - player.height;
        
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
            function(_, touched:FlxObject)
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
        
        if (Net.room != null)
        {
            final moved = Std.int(player.x) != player.lastSend.x || Std.int(player.y) != player.lastSend.y;
            if (!moved)
            {
                player.timer = 0;
            }
            else if (moved && player.timer > player.sendDelay)
            {
                final data = { x:Std.int(player.x), y:Std.int(player.y) };
                // trace('sending: (${data.x}, ${data.y})');
                Net.send("avatar", data);
                player.networkUpdate();
            }
        }
        
        #if debug
        if (FlxG.keys.justPressed.B)
            FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
        
        FlxG.watch.addMouse();
        #end
    }
    
    function activateTeleport(target)
    {
        Game.goToRoom(target);
    }
    
    override function destroy()
    {
        super.destroy();
        
        infoBoxes.clear();
    }
}

enum abstract RoomName(String) to String
{
    var Bedroom  = "bedroom";
    var Hallway  = "hallway";
    var Entrance = "entrance";
    var Outside  = "outside";
}