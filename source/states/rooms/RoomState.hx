package states.rooms;

import data.*;
import data.Content;
import props.*;
import props.InfoBox;
import props.Npc;
import states.OgmoState;
import ui.Button;
import ui.Font;
import ui.LuciaUi;
import ui.MedalPopup;
import ui.MusicPopup;
import ui.SkinPopup;
import ui.Prompt;
import utils.Log;
import vfx.Inline;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;
import flixel.tile.FlxTilemap;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;

import Types;
import io.colyseus.Room;
import io.colyseus.error.MatchMakeError;
import schema.Avatar;
import schema.GameState;

typedef RoomConstructor = (String)->RoomState;

class RoomState extends OgmoState 
{
    public static var roomOrder:Array<RoomName> = [];
    
    var camOffset = 0.0;
    var camFollow = new FlxObject();
    var topWorldCamera:FlxCamera;
    #if debug
    public var debugCamera:FlxCamera;
    #end
    
    var player:InputPlayer;
    var ghostsById:Map<String, GhostPlayer> = [];
    var npcs = new FlxTypedGroup<Npc>();
    var npcsByName = new Map<String, Npc>();
    var avatars = new FlxTypedGroup<Player>();
    var ghosts:FlxTypedGroup<GhostPlayer> = new FlxTypedGroup();
    var teleports = new FlxTypedGroup<Teleport>();
    var presents = new FlxTypedGroup<Present>();
    var colliders = new FlxGroup();
    var characters = new FlxGroup();
    var infoBoxes = new Map<FlxObject, InfoBox>();
    var infoBoxGroup = new FlxTypedGroup<InfoBox>();
    var topGround = new FlxGroup();
    var ui = new FlxGroup();
    
    var spawnTeleport:Teleport;
    var medalPopup:MedalPopup;
    var musicPopup:MusicPopup;
    var skinPopup:SkinPopup;
    var instrument:FlxButton;
    
    public var name(default, null):RoomName;
    public var spawnId(default, null):String = null;
    public var forceDay(default, null) = -1;
    public var roomDay(default, null) = 0;
    
    public var geom(default, null):FlxTilemap;
    public var props(default, null):OgmoEntityLayer;
    public var foreground(default, null):OgmoDecalLayer;
    public var background(default, null):OgmoDecalLayer;
    
    public function new(target:String)
    {
        if (target.indexOf(".") != -1)
        {
            final split = target.split(".");
            spawnId = split.pop();
            target = split.join(".");
        }
        else
            spawnId = "";
        
        name = cast target;
        
        super();
    }
    
    override public function create():Void 
    {
        super.create();
        
        camera = FlxG.camera;
        
        topWorldCamera = new FlxCamera();
        topWorldCamera.bgColor = 0x0;
        FlxG.cameras.add(topWorldCamera);
        
        FlxG.mouse.visible = !FlxG.onMobile;
        // #if debug FlxG.debugger.drawDebug = true; #end
        
        function addDoor(data)
        {
            var door = Door.fromEntity(data);
            colliders.add(door);
            return door;
        }
        entityTypes["Door"] = cast addDoor;
        entityTypes["BigDoor"] = cast addDoor;
        entityTypes["Teleport"] = cast function(data)
        {
            var teleport = Teleport.fromEntity(data);
            
            if (teleport.id == "" && teleport.target != "")
                teleport.id = teleport.target;
            
            if (teleport.target != "" && teleport.target.indexOf(".") == -1)
                teleport.target += "." + name;
            
            teleports.add(teleport);
            return teleport;
        }
        entityTypes["Present"] = cast function(data)
        {
            var present = Present.fromEntity(data);
            
            if (Content.isArtUnlocked(present.id))
                initArtPresent(present, onOpenPresent);
            else
                present.kill();
            
            return present;
        }
        
        entityTypes["Npc"] = cast initNpc.bind(_);
        entityTypes["PBot"] = cast initNpc.bind(_);
        entityTypes["MaleMailMan"] = cast initNpc.bind(_);
        entityTypes["Carousel"] = cast Carousel.fromEntity;
        Log.ogmo('loading level');
        loadLevel();
        Log.ogmo('initing entities');
        initEntities();
        Log.ogmo('initing UI');
        initUi();
        Log.ogmo('initing camera');
        initCamera();
        Log.ogmo('initing client');
        initClient();
        
        NGio.logEventOnce(enter);
        
        FlxG.camera.fade(0xD8000022, 0.5, true);
    }
    
    function initNpc(data, ?skin, ?name, isUser = false)
    {
        var npc = Npc.fromEntity(data, skin, name, isUser);
        npc.nameText.camera = topWorldCamera;
        npcs.add(npc);
        npcsByName[npc.name] = npc;
        return npc;
    }
    
    function onOpenPresent(present) { }
    
    function loadLevel()
    {
        roomDay = Calendar.day;
        
        if(Game.state.match(LuciaDay(_)))
            forceDay = 13;
        
        if (forceDay > 0)
            roomDay = forceDay;
        
        var levelPath = 'assets/data/ogmo/$name$roomDay.json';
        while(roomDay > 0 && !Manifest.exists(levelPath))
        {
            levelPath = 'assets/data/ogmo/$name$roomDay.json';
            roomDay--;
        }
        
        Log.ogmo('parsing $levelPath');
        parseLevel(levelPath);
    }
    
    function initEntities()
    {
        props = getByName("Props");
        foreground = getByName("Foreground");
        background = getByName("Background");
        add(topGround);
        topGround.add(infoBoxGroup);
        
        geom = getByName("Geom");
        colliders.add(geom);
        #if debug
        add(geom);
        debugCamera = new FlxCamera().copyFrom(FlxG.camera);
        debugCamera.bgColor = 0x0;
        debugCamera.visible = FlxG.debugger.drawDebug;
        FlxG.cameras.add(debugCamera, false);
        geom.camera = debugCamera;
        #else
        geom.visible = false;
        #end
        
        for (teleport in teleports.members)
        {
            if (spawnId == teleport.id)
                spawnTeleport = teleport;
        }
        
        if (spawnTeleport == null)
        {
            throw spawnId != ""
                ? 'Could not find a teleport with a id of $spawnId'
                : 'Missing the default spawn point'
                ;
        }
        
        player = new InputPlayer();
        player.x = spawnTeleport.x + (spawnTeleport.width - player.width) / 2;
        player.y = spawnTeleport.y + (spawnTeleport.height - player.height) / 2;
        if(player.x < FlxG.worldBounds.width/2) player.flipX = true;
        player.last.set(player.x, player.y);
        player.nameText.camera = topWorldCamera;
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
        var uiCamera = new FlxCamera();
        uiCamera.bgColor = 0x0;
        FlxG.cameras.add(uiCamera);
        ui.camera = uiCamera;
        
        ui.add(instrument = new FlxButton(FlxG.width, 0, onInstrumentClick));
        Instrument.onChange.add(updateInstrument);
        updateInstrument();
        ui.add(medalPopup = MedalPopup.getInstance());
        ui.add(musicPopup = MusicPopup.getInstance());
        ui.add(skinPopup = SkinPopup.getInstance());
        
        final MARGIN = 4;
        var settings = new SettingsButton(openSettings);
        settings.updateHitbox();
        settings.x = FlxG.width - settings.width - MARGIN;
        settings.y = MARGIN;
        ui.add(settings);
        
        // if (FlxG.onMobile)
            ui.add(new EmoteButton(MARGIN, MARGIN, player.mobileEmotePressed));
        
        add(ui);
    }
    
    function openSettings():Void
    {
        ui.visible = false;
        var oldShowName = Save.showName;
        var settings = new SettingsSubstate();
        settings.closeCallback = function()
        {
            ui.visible = true;
            if (oldShowName != Save.showName)
                player.updateNameText(NGio.userName);
        }
        openSubState(settings);
    }
    
    function openComicPresent(present:Present, data:ArtCreation)
    {
        present.animateOpen(function()
        {
            updatePresentMedal(data);
            
            playOverlay(new ComicSubstate(present.id), data.comic.audioPath != null);
            if (!Calendar.isDebugDay)
                Save.presentOpened(present.id);
        });
    }
    
    function playOverlay(overlay:flixel.FlxSubState, stopMusic = true)
    {
        if (!stopMusic)
        {
            openSubState(overlay);
            return;
        }
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        overlay.closeCallback = ()->
        {
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();
            data.Manifest.playMusic(data.Game.chosenSong);
        }
        openSubState(overlay);
    }
    
    override function openSubState(substate)
    {
        super.openSubState(substate);
        ui.visible = false;
    }
    
    override function closeSubState()
    {
        super.closeSubState();
        ui.visible = true;
    }
    
    function openArtPresent(present:Present, ?callback:(Present)->Void):Void
    {
        // Start loading now, hopefully it finishes during the animation
        Manifest.loadArt(present.id);
        var data = Content.artwork[present.id];
        
        var sound = "present_open.mp3";
        if (data.sound != null && NGio.isLoggedIn && !NGio.hasDayMedal(data.day) && !present.isOpen)
            sound = data.sound;
        FlxG.sound.play("assets/sounds/" + sound);
        
        present.animateOpen(function ()
            {
                updatePresentMedal(data);
                
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
    
    function updatePresentMedal(data:ArtCreation)
    {
        final hasMedal = data.medal != null && data.medal != false;
        final canUnlock = Calendar.day == data.day || data.day == 1;
        if (Calendar.isDebugDay == false && canUnlock && hasMedal)
            NGio.unlockDayMedal(data.day);
    }
    
    function getDaySprite(layer:OgmoDecalLayer, name:String)
    {
        final index = layer.getObjectNameIndex(name, Calendar.day);
        if (index != null)
            return layer.getByName(name + index);
        
        return layer.getByName(name);
    }
    
    function addHoverText(target:String, ?text:String, ?callback:Void->Void, hoverDis = 0, xOffset = 0)
    {
        var decal:FlxSprite = foreground.getByName(target);
        if (decal == null)
            decal = cast (props.getByName(target), FlxSprite);
        
        if (decal == null)
            throw 'can\'t find $target in foreground or props';
        
        return addHoverTextTo(decal, text, callback, hoverDis);
    }
    
    function safeAddHoverText(target:String, ?text:String, ?callback:Void->Void, hoverDis = 0, xOffset = 0)
    {
        var decal:FlxSprite = foreground.getByName(target);
        if (decal == null)
            decal = cast (props.getByName(target), FlxSprite);
        
        if (decal != null)
            return addHoverTextTo(decal, text, callback, hoverDis, xOffset);
        
        return null;
    }
    
    function addHoverTextTo(target:FlxSprite, ?text:String, ?callback:Void->Void, hoverDis = 0, xOffset = 0)
    {
        return addHoverTo(cast new InfoTextBox(target, text, callback, hoverDis, xOffset));
    }
    
    inline function initArtPresent(present:Present, ?callback:(Present)->Void)
    {
        presents.add(present);
        colliders.add(present);
        var data = Content.artwork[present.id];
        if (data.comic != null)
        {
            present.embiggen();
            addHoverTextTo(present, data.name, ()->openComicPresent(present, data));
        }
        else
        {
            var box = addThumbnailTo(present, data.thumbPath, openArtPresent.bind(present, callback));
            box.sprite.visible = present.isOpen;
        }
    }
    
    inline function addThumbnailTo(target:FlxSprite, ?asset, ?callback:Void->Void, hoverDis = 0, xOffset = 0)
    {
        var thumbnail:FlxSprite = null;
        if (asset != null)
        {
            thumbnail = new FlxSprite(0, 0, asset);
            thumbnail.offset.x = -xOffset;
        }
        
        return addHoverTo(new InfoBox(target, thumbnail, callback, hoverDis));
    }
    
    function addHoverTo(box:InfoBox)
    {
        var target = box.target;
        #if debug
        if (target == null)
            throw "Cannot add hover to a null object";
        #end
        
        removeHoverFrom(target);
        
        box.updateFollow();
        infoBoxes[target] = box;
        infoBoxGroup.add(box);
        return box;
    }
    
    function removeHoverFrom(target:FlxObject)
    {
        if (infoBoxes.exists(target))
        {
            var box = infoBoxes[target];
            infoBoxes.remove(target);
            infoBoxGroup.remove(box, true);
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
    
    function onRoomJoin(error:MatchMakeError, room:Room<GameState>)
    {
        if (error != null)
        {
            Net.log("JOIN ERROR: " + error.code + " - " + error.message);
            return;
        }
        
        room.state.avatars.onAdd = onAvatarAdd;
        room.state.avatars.onRemove = onAvatarRemove;
        room.onLeave += function()
        {
            room.state.avatars.onAdd = null;
            room.state.avatars.onRemove = null;
        }
        
        // room.onStateChange += process_state_change;
        Net.send("avatar", 
            { x:Std.int(player.x)
            , y:Std.int(player.y)
            , skin:player.settings.skin
            , name:NGio.userName
            , netState:Idle
            , state:player.state
            }
        );
    }
    
    function onAvatarAdd(data:Avatar, key:String)
    {
        Net.logVerbose("avatar added at " + key + " => " + data);
        Net.logVerbose(Net.room.sessionId + ' added: $key=>${data.name} ${data.skin}@(${data.x}, ${data.y})');
        
        if (key == null)
            return;
        
        if (key != Net.room.sessionId)
        {
            Net.logVerbose(Net.room.sessionId + ' this AINT you');
            if (!ghostsById.exists(key))
            {
                //can be called while being destroyed
                if (this.members == null)
                    return;
                // check if skin is available in this version
                var skin = data.skin;
                if (!Skins.isValidSkin(skin))
                    skin = 0;
                
                var state = cast (data.state, PlayerState);
                var settings = new PlayerSettings(skin, null, state.order);
                var ghost = new GhostPlayer(key, data.name, data.x, data.y, settings);
                ghost.nameText.camera = topWorldCamera;
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
            ghostsById[key].leave(()->removeAvatar(data, key));
    }
    
    function removeAvatar(data:Avatar, key:String)
    {
        var ghost = ghostsById[key];
        ghostsById.remove(key);
        ghosts.remove(ghost);
        foreground.remove(ghost);
        avatars.remove(ghost);
        data.onChange = null;
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
        
        if (!touchingSpawn && spawnTeleport != null)
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
        
        for (infoBox in infoBoxGroup.members)
            infoBox.updateFollow();
        
        var firstBoxTouched:InfoBox = null;
        FlxG.overlap(player.hitbox, infoBoxGroup,
            function(_, box:InfoBox)
            {
                if (box.canInteract && firstBoxTouched == null)
                {
                    firstBoxTouched = box;
                    
                    if (player.interacting)
                        box.interact();
                }
            }
        );
        
        if (player.touched != firstBoxTouched)
        {
            if (player.touched != null)
                player.touched.deselect();
            
            player.touched = firstBoxTouched;
            
            if (player.touched != null)
                player.touched.select();
        }
        
        foreground.sort(byYNullSafe);
        
        super.update(elapsed);
        
        if (Net.room != null)
        {
            final changed
                =  Std.int(player.x) != player.lastSend.x
                || Std.int(player.y) != player.lastSend.y
                || player.emote.type != player.lastSendEmote
                || player.settings.skin != player.lastSkin
                || player.state != player.lastState
                ;
            
            if (!changed)
            {
                player.timer = 0;
            }
            else if (changed && player.timer > player.sendDelay)
            {
                final data = 
                    { x:Std.int(player.x)
                    , y:Std.int(player.y)
                    , skin:player.settings.skin
                    , emote:player.emote.type
                    , netState:player.netState
                    , state:player.state
                    };
                Net.send("avatar", data);
                player.networkUpdate();
            }
            
            checkKisses();
        }
        
        topWorldCamera.scroll.copyFrom(FlxG.camera.scroll);
        topWorldCamera.zoom = FlxG.camera.zoom;
        
        #if debug
        if (FlxG.keys.justPressed.B)
        {
            FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
            debugCamera.visible = FlxG.debugger.drawDebug;
        }
        
        if (FlxG.keys.justPressed.M)
        {
            var music = FlxG.sound.music;
            var endTime = music.endTime != null || music.endTime > 0 ? music.endTime : music.length;
            music.time = endTime - 3000;
        }
        
        FlxG.watch.addMouse();
        
        debugCamera.scroll.copyFrom(FlxG.camera.scroll);
        debugCamera.zoom = FlxG.camera.zoom;
        #end
    }
    
    inline static var KISS_DISTANCE = 56;
    inline static var KISS_DISTANCE_SQR = KISS_DISTANCE * KISS_DISTANCE;
    function checkKisses()
    {
        var dis = FlxVector.get();
        // check player kisses
        if (player.justEmoted)
        {
            for (ghost in ghosts)
            {
                dis.set(ghost.x - player.x, ghost.y - player.y);
                if (dis.lengthSquared < KISS_DISTANCE_SQR)
                {
                    player.showKissAnim();
                    break;
                }
            }
        }
        
        // check ghost kisses
        for (ghost in ghosts)
        {
            if (ghost.emote.visible && ghost.emote.animation.curAnim.curFrame < 2)
            {
                dis.set(ghost.x - player.x, ghost.y - player.y);
                if (dis.lengthSquared < KISS_DISTANCE_SQR)
                {
                    ghost.showKissAnim();
                    player.gotKissed(ghost);
                }
            }
        }
        dis.put();
    }
    
    function activateTeleport(target)
    {
        if (Net.room != null)
        {
            // This call is never received, the player is removed from the room before, TODO: fix
            // final data = { x:Std.int(player.x), y:Std.int(player.y), netState:PlayerNetState.Leaving };
            // Net.send("avatar", data);
        }
        player.active = false;
        FlxG.camera.fade(0xD8000022, 0.25, false, () -> Game.goToRoom(target));
    }
    
    function openUrl(url:String, ?customMsg:String, ?onYes:()->Void):Void
    {
        var prompt = new Prompt();
        add(prompt);
        
        if (customMsg == null)
            customMsg = "";
        else
            customMsg += "\n\n";
        customMsg += 'Open external page?\n${prettyUrl(url)}';
        
        prompt.setupYesNo
            ( customMsg
            , ()->
            {
                FlxG.openURL(url);
                if (onYes != null) onYes();
            }
            , null
            , remove.bind(prompt)
            );
    }
    
    
    function updateInstrument():Void
    {
        switch(Content.instruments[Save.getInstrument()])
        {
            case null:
                instrument.visible = false;
            case data:
            {
                instrument.visible = true;
                instrument.loadGraphic(data.iconPath);
                instrument.scale.set(2.0, 2.0);
                instrument.updateHitbox();
                instrument.x = FlxG.width - instrument.width - 36;
                instrument.y = (30 - instrument.height) / 2;
            }
        }
    }
    
    function onInstrumentClick():Void
    {
        openSubState(new PianoSubstate());
    }
    
    function prettyUrl(url:String)
    {
        if (url.indexOf("://") != -1)
            url = url.split("://").pop();
        
        return url.split("default.aspx").join("");
    }
    
    override function destroy()
    {
        Instrument.onChange.remove(updateInstrument);
        super.destroy();
        
        infoBoxes.clear();
    }
    
    
	public static function byYNullSafe(order:Int, a:Null<FlxObject>, b:Null<FlxObject>):Int
	{
        if (a == null && b == null)
            return 0;
        if (a == null)
            return -order;
        if (b == null)
            return order;
		return FlxSort.byValues(order, a.y, b.y);
	}
}

enum abstract RoomName(String) to String
{
    var Bedroom  = "bedroom";
    var Hallway  = "hallway";
    var Entrance = "entrance";
    var Arcade   = "arcade";
    var Studio   = "music";
    var Movie    = "movie";
    var Credits  = "credits";
    var Outside  = "outside";
    var PathLeft = "path_left";
    var PathCenter = "path_center";
    var PathRight = "path_right";
    var Village = "village";
    var PicosShop = "picos_shop";
    var Cafe = "cafe";
    var PostOffice = "post_office";
    var TheaterLobby = "theater_lobby";
    var TheaterScreen = "theater_screen";
}
