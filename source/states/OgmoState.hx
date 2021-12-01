package states;

import utils.Log;

import haxe.PosInfos;
import haxe.Json;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;

typedef EntityTypeMap = Map<String, (OgmoEntityData<Dynamic>)->FlxObject>;

class OgmoState extends FlxState
{
    var byName:Map<String, FlxBasic> = new Map();
    var entityTypes:EntityTypeMap = new Map();
    
    function parseLevel(levelPath:String)
    {
        var levelString = openfl.Assets.getText(levelPath)
            .split("\\\\").join("/");
        var data:OgmoLevelData = Json.parse(levelString);
        
        var bounds = FlxG.worldBounds.set(data.offsetX, data.offsetY, data.width, data.height);
        FlxG.camera.setScrollBounds(bounds.left, bounds.right, bounds.top, bounds.bottom);
        
        data.layers.reverse();
        for (layerData in data.layers)
        {
            Log.ogmoVerbose('layer: ${layerData.name}');
            var layer = createLayer(layerData);
            add(layer);
            byName[layerData.name] = layer;
        }
    }
    
    function createLayer(data:OgmoLayerData):FlxBasic
    {
        if (Reflect.hasField(data, "tileset"))
            return new OgmoTilemap(cast data);
        
        if (Reflect.hasField(data, "entities"))
            return new OgmoEntityLayer(cast data, entityTypes);
        
        if (Reflect.hasField(data, "decals"))
            return new OgmoDecalLayer(cast data);
        
        throw 'unhandled layer: ${data.name}';
    }
    
    public function getByName<T:FlxBasic>(name:String):Null<T>
    {
        return cast byName[name];
    }
}

class OgmoTilemap extends FlxTilemap
{
    public var name:String;
    public function new (data:OgmoTileLayerData)
    {
        super();
        
        name = data.name;
        x = data.offsetX;
        y = data.offsetY;
        final map = data.data.map(i->i == -1 ? 0 : i);
        loadMapFromArray
            ( map
            , data.gridCellsX
            , data.gridCellsY
            , new openfl.display.BitmapData(data.gridCellWidth * 2, data.gridCellHeight, true, 0x40ff0000)
            , data.gridCellWidth
            , data.gridCellHeight
            , 0
            , 1
            , 1
            );
        this.useScaleHack = false;
    }
}

class OgmoObjectLayer<T:FlxBasic> extends FlxTypedGroup<T>
{
    public var name:String;
    
    var byName:Map<String, T> = new Map();
    
    inline public function setAnimFrameRate(name:String, frameRate):Null<FlxSprite>
    {
        var sprite = cast(getByName(name), FlxSprite);
        sprite.animation.curAnim.frameRate = frameRate;
        return sprite;
    }
    
    inline public function safeSetAnimFrameRate(name:String, frameRate):Null<FlxSprite>
    {
        var sprite = getByName(name);
        if (sprite == null && Std.is(sprite, FlxSprite))
            (cast sprite:FlxSprite).animation.curAnim.frameRate = frameRate;
        else
            sprite = null;
        return (cast sprite:FlxSprite);
    }
    
    public function getByName(name:String):Null<T>
    {
        return cast byName[name];
    }
    
    public function existsByName(name:String):Bool
    {
        return cast byName.exists(name);
    }
    
    public function getObjectNameIndex(suffix:String, maxValue:Int):Null<Int>
    {
        var value = maxValue;
        while(value >= 0)
        {
            if (byName.exists(suffix + value))
                return value;
            
            value--;
        }
        return null;
    }
    
    public function getIndexNamedObject(suffix:String, maxValue:Int):Null<T>
    {
        return getByName(suffix + getObjectNameIndex(suffix, maxValue));
    }
}

typedef IOgmoDecal = IOgmoObject<OgmoDecalData, OgmoDecalLayer>;
class OgmoDecalLayer extends OgmoObjectLayer<OgmoDecal>
{
    public function new (data:OgmoDecalLayerData, path:String = "")
    {
        super();
        
        for (decalData in data.decals)
        {
            Log.ogmo("creating decal:" + decalData.texture);
            
            final name = getName(decalData.texture);
            final decal = new OgmoDecal(decalData);
            add(decal);
            if (!byName.exists(name))
                byName[name] = decal;
            Log.ogmoVerbose('decal: $name x:${decal.x} y:${decal.y}');
        }
        
        for (i in 0...data.decals.length)
        {
            if (Std.is(members[i], IOgmoDecal))
                (cast members[i]:IOgmoDecal).ogmoInit(data.decals[i], this);
        }
    }
    
    inline static function getName(texture:String):String
    {
        return texture.substring(texture.lastIndexOf("/") + 1, texture.lastIndexOf("."))
            .split("_ogmo").join("");
    }
    
    public function getAllWithPrefix(prefix:String):Array<OgmoDecal>
    {
        var all:Array<OgmoDecal> = [];
        for (child in members)
        {
            if (child.graphic != null && child.graphic.assetsKey.indexOf(prefix) != -1)
                all.push(child);
        }
        return all;
    }
    
    public function getAllWithName(name:String):FlxTypedGroup<OgmoDecal>
    {
        var nameLength = name.length + 4;
        var all = new FlxTypedGroup<OgmoDecal>();
        for (child in members)
        {
            if (child.graphic != null)
            {
                final key = child.graphic.assetsKey;
                if (key.lastIndexOf(name) != -1 && key.lastIndexOf(name) + nameLength == key.length)
                    all.add(child);
            }
        }
        return all;
    }
}

typedef IOgmoEntity<T> = IOgmoObject<OgmoEntityData<T>, OgmoEntityLayer>;
class OgmoEntityLayer extends OgmoObjectLayer<FlxObject>
{
    public function new (data:OgmoEntityLayerData, types:EntityTypeMap)
    {
        super();
        
        for (entityData in data.entities)
        {
            Log.ogmoVerbose('Creating entity: $entityData');
            var entity = add(create(entityData, types));
            if (entityData.values != null && entityData.values.id != "" && entityData.values.id != null)
            {
                Log.ogmoVerbose("entity:" + entityData.values.id);
                byName[entityData.values.id] = entity;
            }
            else if (!byName.exists(name))
            {
                Log.ogmoVerbose("entity:" + entityData.name);
                byName[entityData.name] = entity;
            }
        }
    }

    function create(data:OgmoEntityData<Dynamic>, types:EntityTypeMap):FlxObject
    {
        if (!types.exists(data.name))
            throw 'unhandled entity name: $name';
        
        return types[data.name](data);
    }
}

typedef OgmoLevelData =
{
    width     :Int,
    height    :Int,
    offsetX   :Int,
    offsetY   :Int,
    layers    :Array<OgmoLayerData>,
    exportMode:Int,
    arrayMode :Int
}

typedef OgmoLayerData = 
{
    name          :String,
    offsetX       :Int,
    offsetY       :Int,
    gridCellWidth :Int,
    gridCellHeight:Int,
    gridCellsX    :Int,
    gridCellsY    :Int
}

typedef OgmoTileLayerData
= OgmoLayerData
& {
    tileset:String,
    data   :Array<Int>
}

typedef OgmoDecalLayerData
= OgmoLayerData
& { decals: Array<OgmoDecalData> }

typedef OgmoEntityLayerData
= OgmoLayerData
& { entities:Array<OgmoEntityData<Dynamic>> }

typedef OgmoObjectData = { x:Int, y:Int }

typedef RawOgmoEntityData<T>
= OgmoObjectData & {
    name     :String,
    id       :Int,
    ?rotation:Float,
    ?originX :Int,
    ?originY :Int,
    ?width   :Int,
    ?height  :Int,
    ?flippedX:Bool,
    ?flippedY:Bool,
    values   :T
}

@:forward
abstract OgmoEntityData<T>(RawOgmoEntityData<T>) from RawOgmoEntityData<T> to RawOgmoEntityData<T>
{
    static public function createFlxObject(entityData:OgmoEntityData<Dynamic>):FlxObject
    {
        var object = new FlxObject();
        entityData.applyToObject(object);
        return object;
    }
    
    static public function createFlxSprite(entityData:OgmoEntityData<Dynamic>):FlxSprite
    {
        var sprite = new FlxSprite();
        entityData.applyToSprite(sprite);
        return sprite;
    }
    
    public function applyToObject(object:FlxObject)
    {
        object.x = this.x;
        object.y = this.y;
        
        if (this.rotation != null)
            object.angle = this.rotation;
        
        if (this.width != null)
            object.width = this.width;
        
        if (this.height != null)
            object.height = this.height;
        
        object.immovable = true;//make the bounds green
        // object.ignoreDrawDebug = true;
    }
    
    public function applyToSprite(sprite:FlxSprite)
    {
        applyToObject(sprite);
        
        if (this.originX != 0)
            sprite.offset.x = this.originX;
        if (this.originY != 0)
            sprite.offset.y = this.originY;
        if (this.flippedX == true)
            sprite.facing = (sprite.facing == FlxObject.LEFT) ? FlxObject.RIGHT : FlxObject.LEFT;
    }
}

@:forward
abstract OgmoDecal(FlxSprite) to FlxSprite from FlxSprite
{
    public function new(data:OgmoDecalData):Void
    {
        var path = "assets/images/props/" + data.texture;
        this = new FlxSprite(path);
        this.x = data.x;
        this.y = data.y;
        
        if (path.indexOf("_ogmo.") != -1)
        {
            var oldSize = FlxPoint.get(this.frameWidth, this.frameHeight);
            this.loadGraphic
                ( path.split("_ogmo").join("")
                , true
                , this.frameWidth
                , this.frameHeight
                );
            this.animation.add("anim", [for (i in 0...this.animation.frames) i], 12);
            this.animation.play("anim");
            
            if (this.graphic.bitmap.width % oldSize.x != 0 || this.graphic.bitmap.height % oldSize.y != 0)
                throw 'Size mismatch on animation: $path expected '
                    + 'frameSize:(${oldSize.x}, ${oldSize.y}) got (${this.graphic.bitmap.width}, ${this.graphic.bitmap.height})';
            
        }
        
        if (this.graphic == null)
            throw "error loading " + path;
        // convert from center pos
        this.x -= Math.round(this.width / 2);
        this.y -= Math.round(this.height / 2);
        // allow player to go behind stuff
        if (data.values != null)
        {
            var values = data.values;
            if (values.bottomHeight != null && values.bottomHeight > 0)
                setBottomHeight(values.bottomHeight);
            else
                setBottomHeight(this.height / 3);
            
            this.ignoreDrawDebug = values.ignoreDebugDraw != false;// can be true or null
        }
        else
            this.ignoreDrawDebug = true;
    }
    
    public function setBottomHeight(value:Float)
    {
        var oldHeight = this.height;
        this.height = value;
        this.y += oldHeight - value;
        this.offset.y += oldHeight - value;
    }
    
    public function setMiddleWidth(value:Float)
    {
        var oldWidth = this.width;
        this.width = value;
        this.x += (oldWidth - value) / 2;
        this.offset.x += (oldWidth - value) / 2;
    }
}

typedef OgmoDecalData = OgmoObjectData &
{
    var texture:String;
    var values:Null<{ bottomHeight:Null<Int>, ignoreDebugDraw:Null<Bool> }>;
}

interface IOgmoObject<Data:OgmoObjectData, Layer>
{
    function ogmoInit(data:Data, parent:Layer):Void;
}

abstract OgmoValue(String) from String to String
{
    public var isEmpty(get, never):Bool;
    inline function get_isEmpty() return this == "-1";
        
    inline public function getColor():Null<Int>
    {
        return isEmpty ? null : (Std.parseInt("0x" + this.substr(1)) >> 8);
    }
    
    inline public function getInt  ():Int   return isEmpty ? null : Std.parseInt(this);
    inline public function getFloat():Float return isEmpty ? null : Std.parseFloat(this);
    inline public function getBool ():Bool  return isEmpty ? null : this == "true";
}

@:forward abstract OgmoInt(OgmoValue) from String to String
{
    public var value(get, never):Int; inline function get_value() return this.getInt();
}

@:forward abstract OgmoFloat(OgmoValue) from String to String
{
    public var value(get, never):Float; inline function get_value() return this.getFloat();
}

@:forward abstract OgmoBool(OgmoValue) from String to String
{
    public var value(get, never):Bool; inline function get_value() return this.getBool();
}

@:forward abstract OgmoColor(OgmoValue) from String to String
{
    public var value(get, never):Int; inline function get_value() return this.getColor();
}

interface ISortable { var sorting:Sorting; }

enum abstract Sorting(String)
{
    var Top;
    var Y;
    var Bottom;
    var None;
}