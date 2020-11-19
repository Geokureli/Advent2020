package data;

import openfl.utils.Assets;
import openfl.utils.AssetType;
import lime.utils.AssetManifest;

class Manifest
{
    static public var noPreload:AssetManifest = null;
    static public function init(onComplete:()->Void):Void
    {
        final manifestHttp = new haxe.Http("manifest/noPreload.json");
        manifestHttp.onError = function (msg) throw msg;
        manifestHttp.onData = function (data)
        {
            noPreload = AssetManifest.parse(data, "./");
            onComplete();
        }
        manifestHttp.request();
    }
    
    static public function exists(id:String, ?type:AssetType):Bool
    {
        if (Assets.exists(id, type))
            return true;
        
        if (noPreload != null)
        {
            for (asset in (cast noPreload.assets:Array<AssetData>))
            {
                if (asset.id == id && (type == null || type == asset.type))
                    return true;
            }
        }
        
        return false;
    }
}

private typedef AssetData =
{
    path:String,
    size:Int,
    type:AssetType,
    id:String,
    preload:Bool
};
