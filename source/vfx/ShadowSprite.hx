package vfx;

class ShadowSprite extends flixel.FlxSprite
{
    public var shadow(default, null):ShadowShader;
    
    public function new (x = 0.0, y = 0.0, ?graphic, pixelSize = 1)
    {
        shadow = new ShadowShader(0x0, pixelSize, false);
        super(x, y, graphic);
    }
    
    override function graphicLoaded()
    {
        super.graphicLoaded();
        if (shader == null)
            shader = shadow;
    }
}