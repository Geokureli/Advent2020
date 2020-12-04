package states.rooms;

import data.Calendar;
import data.Manifest;
import data.Save;
import data.Skins;
import data.Content;
import data.Game;
import data.NGio;
import data.Net;
import data.PlayerSettings;
import props.GhostPlayer;
import props.InfoBox;
import props.InputPlayer;
import props.Player;
import props.Present;
import props.Teleport;
import states.OgmoState;
import ui.MedalPopup;
import ui.MusicPopup;
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

import Types;
import io.colyseus.Room;
import schema.Avatar;
import schema.GameState;

typedef RoomConstructor = (String)->RoomState;

class RoomState extends OgmoState 
{
    static var outlineShader = new Inline();
    
    var camOffset = 0.0;
    var camFollow = new FlxObject();
    var uiCamera:FlxCamera;
    
    var player:InputPlayer;
    var ghostsById:Map<String, GhostPlayer> = [];
    var avatars = new FlxTypedGroup<Player>();
    var ghosts:FlxTypedGroup<GhostPlayer> = new FlxTypedGroup();
    var teleports = new FlxTypedGroup<Teleport>();
    var presents = new FlxTypedGroup<Present>();
    var colliders = new FlxGroup();
    var characters = new FlxGroup();
    var touchable = new FlxTypedGroup<FlxObject>();
    var infoBoxes = new Map<FlxObject, InfoBox>();
    var infoBoxGroup = new FlxTypedGroup<InfoBox>();
    var topGround = new FlxGroup();
    var ui = new FlxGroup();
    
    var spawnTeleport:Teleport;
    var medalPopup:MedalPopup;
    var musicPopup:MusicPopup;
    
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
        entityTypes["Present"] = cast function(data)
        {
            var present = Present.fromEntity(data);
            if (Content.isArtUnlocked(present.id))
            {
                presents.add(present);
                colliders.add(present);
                initArtPresent(present, onOpenPresent);
            }
            else
                present.kill();
            
            return present;
        }
        loadLevel();
        initEntities();
        initUi();
        initCamera();
        initClient();
        
        NGio.logEventOnce(enter);
    }
    
    function onOpenPresent(present)
    {
        
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
        add(topGround);
        
        geom = getByName("Geom");
        colliders.add(geom);
        add(geom);
        
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
    
    function initUi()
    {
        ui.add(infoBoxGroup);
        ui.add(medalPopup = MedalPopup.getInstance());
        ui.add(musicPopup = MusicPopup.getInstance());
        ui.forEach(
            function(obj)
            {
                if (Std.is(obj, FlxSprite))
                    (cast obj:FlxSprite).scrollFactor.set(0,0);
            }
        );
        add(ui);
    }
    
	function openArtPresent(present:Present, ?callback:(Present)->Void):Void
	{
        // Start loading now, hopefully it finishes during the animation
        Manifest.loadArt(present.id);
        
        FlxG.sound.play("assets/sounds/present_open.mp3");
        present.animateOpen(function ()
            {
                var data = Content.artwork[present.id];
                var medal = data.medal;
                if (!Calendar.isDebugDay
                &&  (data.day == 1 || Calendar.day == data.day)
                &&  medal != null && medal != false)
                    NGio.unlockDayMedal(data.day);
                
                function onOpenComplete()
                {
                    infoBoxes[present].sprite.visible = true;
                    if (callback != null)
                        callback(present);
                }
                openSubState(new GallerySubstate(present.id, onOpenComplete));
                if (!Calendar.isDebugDay)
                    Save.presentOpened(present.id);
            }
        );
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
    
    inline function initArtPresent(present:Present, ?callback:(Present)->Void)
    {
        var data = Content.artwork[present.id];
        var box = addThumbnailTo(present, data.thumbPath, openArtPresent.bind(present, callback));
        box.sprite.visible = present.isOpen;
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
        removeHoverFrom(target);
        
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
            Net.log("JOIN ERROR: " + error);
            return;
        }
        
        room.state.avatars.onAdd = onAvatarAdd;
        room.state.avatars.onRemove = onAvatarRemove;
        
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
    
    function onAvatarAdd(data:Avatar, key:String)
    {
        Net.logVerbose("avatar added at " + key + " => " + data);
        Net.logVerbose(Net.room.sessionId + ' added: $key=>${data.name} ${data.skin}@(${data.x}, ${data.y})');
        
        if (key != Net.room.sessionId)
        {
            Net.logVerbose(Net.room.sessionId + ' this AINT you');
            if (!ghostsById.exists(key))
            {
                // check if skin is available in this version
                var skin = data.skin;
                if (!Skins.isValidSkin(skin))
                    skin = 0;
                var settings = new PlayerSettings(skin);
                var ghost = new GhostPlayer(key, data.name, data.x, data.y, settings);
                ghostsById[key] = ghost;
                ghosts.add(ghost);
                foreground.add(ghost);
                avatars.add(ghost);
                data.onChange = ghost.onChange;
            }
        }
        else
            Net.logVerbose(Net.room.sessionId + " this is you!");
    }
    
    function onAvatarRemove(data:Avatar, key:String)
    {
        if (ghostsById.exists(key))
        {
            var ghost = ghostsById[key];
            ghostsById.remove(key);
            ghosts.remove(ghost);
            foreground.remove(ghost);
            avatars.remove(ghost);
            data.onChange = null;
        }
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
            if (child != null && infoBoxes.exists(child))
                infoBoxes[child].updateFollow(child);
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
        
        if (player.touched != firstTouched)
        {
            if (player.touched != null)
            {
                infoBoxes[player.touched].alive = false;
                if (Std.is(player.touched, FlxSprite))
                {
                    final sprite = Std.downcast(player.touched, FlxSprite);
                    sprite.shader = null;
                }
            }
            
            player.touched = firstTouched;
            
            if (player.touched != null)
            {
                infoBoxes[player.touched].alive = true;
                if (Std.is(player.touched, FlxSprite))
                {
                    final sprite = Std.downcast(player.touched, FlxSprite);
                    sprite.shader = outlineShader;
                }
            }
        }
        
        foreground.sort(byYNullSafe);
        
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
                Net.send("avatar", data);
                player.networkUpdate();
            }
        }
        
        #if debug
        if (FlxG.keys.justPressed.B)
            FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
        
        if (FlxG.keys.justPressed.M)
        {
            var music = FlxG.sound.music;
            var endTime = music.endTime != null || music.endTime > 0 ? music.endTime : music.length;
            music.time = endTime - 3000;
        }
        
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
    
    
	public static inline function byYNullSafe(order:Int, a:Null<FlxObject>, b:Null<FlxObject>):Int
	{
        if (a == null || b == null)
            return 0;
		return FlxSort.byValues(order, a.y, b.y);
	}
}

enum abstract RoomName(String) to String
{
    var Bedroom  = "bedroom";
    var Hallway  = "hallway";
    var Entrance = "entrance";
    var Outside  = "outside";
}