package data;

import haxe.Json;

import openfl.utils.Assets;

import flixel.FlxSprite;

class Skins
{
    static var list:Array<SkinData>;
    
    static function init()
    {
        list = Json.parse(Assets.getText("assets/data/skins.json"));
    }
    
    static public function getData(id:Int)
    {
        if (list == null)
            init();
        
        if (id < 0 || list.length <= id)
            throw "Invalid id:" + id;
        
        return list[id];
    }
}

typedef SkinData =
{
    var id:String;
    var proper:String;
    var description:String;
    var unlockDay:Int;
}