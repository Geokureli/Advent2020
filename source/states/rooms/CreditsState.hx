package states.rooms;

import data.NGio;
import data.Game;
import ui.DjUi;
import ui.Controls;
import ui.Font;
import flixel.text.FlxBitmapText;
import ui.Button;
import flixel.FlxSubState;
import data.Manifest;
import states.OgmoState;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import data.Content;
import props.Teleport;
import flixel.FlxG;
import flixel.FlxSprite;

class CreditsState extends RoomState
{
    var sections:FlxTypedGroup<Section>;
    var sectionsWidth = 0;
    var exitTeleport:Teleport;
    var prevSong:String;
    
    override function create()
    {
        sections = new FlxTypedGroup();
        add(sections);
        
        super.create();
        
        prevSong = Game.chosenSong;
        Manifest.playMusic("heyopc");
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var section = new Section();
        var floor = background.getByName("credits");
        background.remove(floor);
        var candle = background.getByName("candle");
        background.remove(candle);
        var frame = background.getByName("portrait");
        background.remove(frame);
        section.fromExisting(floor, candle, frame);
        sections.add(section);
        function addSection()
        {
            section = new Section(sections.length * Section.floorWidth);
            section.create();
            sections.add(section);
            return section;
        }
        
        while((sections.length - 1) * Section.floorWidth < FlxG.width)
            addSection();
        
        sectionsWidth = sections.length * Std.int(Section.floorWidth);
        FlxG.worldBounds.right = Content.creditsOrdered.length * Section.floorWidth;
        FlxG.worldBounds.top = floor.y + 55 - 4;
        FlxG.worldBounds.bottom = floor.y + floor.height - 2;
        FlxG.camera.maxScrollX = FlxG.worldBounds.right;
        
        for (teleport in teleports.members)
        {
            if ("outside" == teleport.id)
            {
                exitTeleport = teleport;
                break;
            }
        }
        
        if (exitTeleport == null)
            throw "missing teleport";
        
        exitTeleport.x = FlxG.worldBounds.right - exitTeleport.width;
        setPortraits(true);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (player.y > FlxG.worldBounds.bottom - player.width)
            player.y = FlxG.worldBounds.bottom - player.width;
        
        if (player.y < FlxG.worldBounds.top)
            player.y = FlxG.worldBounds.top;
        
        setPortraits();
    }
    
    function setPortraits(forceRedraw = false)
    {
        var camX = FlxG.camera.scroll.x;
        var leftIndex = Math.floor(Math.max(0, camX / Section.floorWidth));
        var rightIndex = leftIndex + sections.length;
        var leftmostSection = leftIndex % sections.length;
        for (i=>section in sections.members)
        {
            var moved = forceRedraw;
            while(section.x + Section.floorWidth < camX && section.x + sectionsWidth <= FlxG.worldBounds.right)
            {
                moved = true;
                section.x += sectionsWidth;
            }
            
            while(section.x > camX + FlxG.width && section.x - sectionsWidth >= 0)
            {
                moved = true;
                section.x -= sectionsWidth;
            }
            
            if (moved)
            {
                final index = leftIndex + (i - leftmostSection + sections.length) % sections.length;
                if (index < Content.creditsOrdered.length)
                {
                    if (index == Content.creditsOrdered.length - 1 && !NGio.hasMedalByName("credits"))
                        NGio.unlockMedalByName("credits");
                    var data = Content.creditsOrdered[index];
                    section.portrait.setImage(data.portraitPath);
                    addHoverTextTo(section.picFrame, data.proper, ()->openSubState(new PopupCredits(data)));
                }
            }
        }
    }
    
    override function activateTeleport(target:String)
    {
        super.activateTeleport(target);
        Manifest.playMusic(prevSong);
    }
}

class PopupCredits extends FlxSubState
{
    var data:CreditContent;
    public function new(data)
    {
        super();
        this.data = data;
    }
    
    override function create()
    {
        super.create();
        final EDGE = 16;
        var bg = new ui.DialogBg(EDGE, EDGE, FlxG.width - EDGE * 2, FlxG.height - EDGE * 2);
        add(bg);
        
        var path = data.portraitPath;
        if (!Manifest.exists(path, IMAGE))
            path = Portrait.MISSING_PATH;
        var portrait = new FlxSprite(path);
        portrait.y = bg.y + (bg.height - portrait.height) / 2;
        portrait.x = bg.x + portrait.y - bg.y;
        portrait.antialiasing = true;
        
        var border = new FlxSprite(portrait.x - 1, portrait.y - 1);
        border.makeGraphic(portrait.graphic.width + 2, portrait.graphic.height + 2, 0xFF928fb8);
        add(border);
        add(portrait);
        
        var name = new FlxBitmapText(new XmasFont());
        name.scale.set(2, 2);
        name.updateHitbox();
        name.text = data.proper;
        name.screenCenter(X);
        name.y = bg.y + ((portrait.y - bg.y) - name.height)/ 2;
        add(name);
        
        var roles = new FlxBitmapText(new NokiaFont());
        roles.x = portrait.y + portrait.width + 8;
        roles.lineSpacing += 6;
        roles.y = portrait.y;
        roles.text = data.roles.join("\n");
        add(roles);
        
        var back = new BackButton(0, 0, close);
        back.y = bg.y + 4;
        back.x = bg.x + bg.width - 4 - back.width;
        add(back);
        
        var profile = new ProfileButton(0, 0, ()->FlxG.openURL(data.newgrounds));
        profile.screenCenter(X);
        profile.y = portrait.y + portrait.height + ((bg.y + bg.height) - (portrait.y + portrait.height) - profile.height) / 2;
        add(profile);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (Controls.justPressed.B)
            close();
    }
}

class Section extends FlxSpriteGroup
{
    static public var template(default, null):Section = null;
    static public var floorWidth(get, never):Float;
    inline static public function get_floorWidth() return template.floor.width;
    
    public var floor(default, null):FlxSprite;
    public var candle(default, null):FlxSprite;
    public var picFrame(default, null):FlxSprite;
    public var portrait(default, null):Portrait;
    public function new(x = 0.0, y = 0.0)
    {
        super(x, y);
        portrait = new Portrait();
    }
    
    public function create()
    {
        floor = new FlxSprite(template.floor.x, template.floor.y);
        floor.loadGraphicFromSprite(template.floor);
        add(floor);
        candle = new FlxSprite(template.candle.x, template.candle.y);
        candle.loadGraphicFromSprite(template.candle);
        add(candle);
        picFrame = new FlxSprite(template.picFrame.x, template.picFrame.y);
        picFrame.loadGraphicFromSprite(template.picFrame);
        picFrame.height += 24;
        add(portrait);
        add(picFrame);
        initPortrait();
    }
    
    public function fromExisting(floor:OgmoDecal, candle:OgmoDecal, picFrame:OgmoDecal)
    {
        floor.setBottomHeight(floor.frameHeight);
        candle.setBottomHeight(candle.frameHeight);
        picFrame.setBottomHeight(picFrame.frameHeight);
        picFrame.height += 24;
        add(this.floor = floor);
        add(this.candle = candle);
        add(portrait);
        add(this.picFrame = picFrame);
        initPortrait();
        template = this;
    }
    
    inline function initPortrait()
    {
        portrait.x = picFrame.x + 4;
        portrait.y = picFrame.y + 9;
    }
}

@:forward
abstract Portrait(FlxSprite) from FlxSprite to FlxSprite
{
    inline public static var MISSING_PATH = "assets/images/portraits/missing.png";
    
    inline public function new (x = 0.0, y = 0.0, ?path:String)
    {
        this = new FlxSprite(x, y);
        this.scale.set(0.25, 0.25);
        this.antialiasing = true;
        if(path != null)
            setImage(path);
    }
    
    public function setImage(path:String)
    {
        if (Manifest.exists(path, IMAGE))
            this.loadGraphic(path);
        else
            this.loadGraphic(MISSING_PATH);
        
        this.updateHitbox();
    }
}

class ProfileButton extends Button
{
    public function new(x = 0.0, y = 0.0, ?onClick)
    {
        super(x, y, onClick, "assets/images/ui/buttons/profile.png");
    }
}