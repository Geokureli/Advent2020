package states.rooms;

import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import data.*;
import data.Content;
import props.*;
import props.InfoBox;
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
    public static var roomOrder = [Bedroom, Hallway, Entrance, Outside, Arcade, Studio];
    
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
    var luciaBuns:FlxTypedGroup<OgmoDecal>;
    var luciaUi:LuciaUi;
    var cheese:OgmoDecal;
    
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
            
            if (present.id == "comic")
            {
                initComicPresent(present);
                return present;
            }
            
            final isLucia = Lucia.active && present.id == Lucia.USER;
            if (!isLucia && Content.isArtUnlocked(present.id))
                initArtPresent(present, onOpenPresent);
            else
                present.kill();
            
            return present;
        }
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
        add(geom);
        
        initLuciaBuns();
        
        cheese = background.getByName("cheese");
        if (cheese == null)
            cheese = foreground.getByName("cheese");
        
        if (cheese != null && NGio.hasMedal(61555))
        {
            cheese.kill();
            cheese = null;
        }
        
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
        player.last.set(player.x, player.y);
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
        camera = FlxG.camera;
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
        var fullscreen = new FullscreenButton();
        fullscreen.updateHitbox();
        fullscreen.x = FlxG.width - fullscreen.width - 4;
        fullscreen.y = 4;
        ui.add(fullscreen);
        add(ui);
        
        if (Lucia.finding)
            initLuciaUi();
    }
    
    function initLuciaBuns()
    {
        luciaBuns = foreground.getAllWithName("lucia_cat");
        var clearBuns = true;
        if (Lucia.present)
        {
            if (Lucia.presentLoc.room == name)
                initLuciaPresent();
        }
        else if (Lucia.active && !Lucia.isCleared(name))
        {
            clearBuns = false;
            Lucia.initRoom(name, luciaBuns.length);
            for (i=>bun in luciaBuns.members)
            {
                if (Lucia.isCollected(name, i))
                    bun.kill();
                else
                {
                    bun.setBottomHeight(bun.frameHeight);
                    bun.scale.set(0.5, 0.5);
                    bun.updateHitbox();
                    bun.x += bun.width / 4;
                    bun.y += bun.height / 4;
                }
            }
        }
        
        if (clearBuns)
        {
            var i = luciaBuns.members.length;
            while(i-- > 0)
                luciaBuns.members.shift().kill();
        }
    }
    
    function initLuciaUi()
    {
        ui.add(luciaUi = new LuciaUi());
    }
    
    function initLuciaPresent()
    {
        var present = new Present(Lucia.USER, Lucia.presentLoc.pos.x, Lucia.presentLoc.pos.y);
        initArtPresent(present, function(present)
            {
                if (Game.state.match(LuciaDay(Present)))
                    Game.state = NoEvent;
                onOpenPresent(present);
            }
        );
        foreground.add(present);
        return present;
    }
    
    function initComicPresent(present:Present)
    {
        present.scale.set(1, 1);
        present.width *= 2;
        present.offset.x -= 4;
        present.immovable = true;
        presents.add(present);
        colliders.add(present);
        addHoverTextTo(present, "Twas the Night Before Tankmas", ()->openComicPresent(present));
        return present;
    }
    
    function openComicPresent(present:Present)
    {
        present.animateOpen(()->playOverlay(new states.ComicSubstate("night_before")));
    }
    
    
    function playOverlay(overlay:flixel.FlxSubState)
    {
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
    
    function getDaySprite(layer:OgmoDecalLayer, name:String)
    {
        final index = layer.getObjectNameIndex(name, Calendar.day);
        if (index != null)
            return layer.getByName(name + index);
        
        return layer.getByName(name);
    }
    
    function addHoverText(target:String, ?text:String, ?callback:Void->Void, hoverDis = 20)
    {
        var decal:FlxObject = foreground.getByName(target);
        if (decal == null)
            decal = cast props.getByName(target);
        if (decal == null)
            throw 'can\'t find $target in foreground or props';
        
        return addHoverTextTo(decal, text, callback, hoverDis);
    }
    
    function safeAddHoverText(target:String, ?text:String, ?callback:Void->Void, hoverDis = 20)
    {
        var decal:FlxObject = foreground.getByName(target);
        if (decal == null)
            decal = cast props.getByName(target);
        if (decal != null)
            return addHoverTextTo(decal, text, callback, hoverDis);
        
        return null;
    }
    
    function addHoverTextTo(target:FlxObject, ?text:String, ?callback:Void->Void, hoverDis = 20)
    {
        return addHoverTo(target, cast new InfoTextBox(text, callback), hoverDis);
    }
    
    inline function initArtPresent(present:Present, ?callback:(Present)->Void)
    {
        presents.add(present);
        colliders.add(present);
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
            , state:Idle
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
        
        if (cheese != null && cheese.overlaps(player) && cheese.solid)
        {
            NGio.unlockMedalByName("cheese");
            FlxG.sound.play("assets/sounds/pickup2.mp3");
            cheese.solid = false;
            FlxTween.tween(cheese, { y: cheese.y - 32 }, 0.5,
                { ease:FlxEase.sineOut });
            FlxTween.tween(cheese, { alpha: 0 }, 0.25,
                { startDelay:0.75 });
        }
        
        if (Lucia.finding)
        {
            #if debug
            if (FlxG.keys.justPressed.L)
                Lucia.debugSkip();
            #end
            
            FlxG.overlap(player, luciaBuns,
                function(_, bun)
                {
                    Lucia.collect(name, luciaBuns.members.indexOf(bun));
                    FlxG.sound.play("assets/sounds/pickup.mp3");
                    foreground.remove(bun);
                    topGround.add(bun);
                    bun.solid = false;
                    var onTweenComplete:(FlxTween)->Void = (_)->bun.kill();
                    if (Lucia.collected >= Lucia.TOTAL)
                    {
                        if (Save.hasOpenedPresent(Lucia.USER))
                            Game.state = NoEvent;
                        else
                            Game.state = LuciaDay(Present);
                        
                        player.enabled = false;
                        onTweenComplete = function(_)
                        {
                            bun.kill();
                            Lucia.onComplete(name, FlxPoint.get(bun.x, bun.y));
                            luciaUi.onComplete(playLuciaCutscene);
                        }
                    }
                    
                    FlxTween.tween(bun, { y: bun.y - 16 }, 0.35,
                        { ease:FlxEase.sineOut });
                    FlxTween.tween(bun, { alpha: 0 }, 0.2,
                        { startDelay:0.3, onComplete:onTweenComplete });
                    
                }
            );
        }
        
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
            if (player.touched != null && infoBoxes.exists(player.touched) && infoBoxes[player.touched] != null)//todo: clear refs better in removeHoverFrom
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
            final changed
                =  Std.int(player.x) != player.lastSend.x
                || Std.int(player.y) != player.lastSend.y
                || player.emote.type != player.lastSendEmote
                ;
            
            if (!changed)
            {
                player.timer = 0;
            }
            else if (changed && player.timer > player.sendDelay)
            {
                final data = { x:Std.int(player.x), y:Std.int(player.y), emote:player.emote.type };
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
    
    function playLuciaCutscene()
    {
        var present = initLuciaPresent();
        final RISE = 16;
        present.alpha = 0;
        present.offset.y += RISE;
        FlxTween.tween(present, { alpha:1 }, 0.25);
        FlxTween.tween(present.offset, { y:present.offset.y - RISE }, 0.75,
            { startDelay:1.0, ease:FlxEase.circOut, onComplete:(_)->player.enabled = true });
    }
    
    function onOpenLuciaPresent(present:Present)
    {
        Game.state = NoEvent;
        onOpenPresent(present);
    }
    
    function activateTeleport(target)
    {
        if (Net.room != null)
        {
            // This call is never received, the player is removed from the room before, TODO: fix
            // final data = { x:Std.int(player.x), y:Std.int(player.y), state:PlayerState.Leaving };
            // Net.send("avatar", data);
        }
        Game.goToRoom(target);
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
        
        prompt.setup
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
    var Outside  = "outside";
    var Arcade   = "arcade";
    var Studio   = "music";
    var Movie    = "movie";
}