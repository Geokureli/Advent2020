package rig;

enum abstract Limb(String) to String
{
    inline static public var Head    :Limb = cast "Head";
    inline static public var ArmRight:Limb = cast "ArmRight";
    inline static public var Torso   :Limb = cast "Torso";
    inline static public var LegRight:Limb = cast "LegRight";
    inline static public var LegLeft :Limb = cast "LegLeft";
    inline static public var ArmLeft :Limb = cast "ArmLeft";
    
    inline public function toLowerCase() return this.toLowerCase();
    
    public function isLeg() return this == LegRight || this == LegLeft;
    public function isArm() return this == ArmRight || this == ArmLeft;
    
    static public function is(value:String)
    {
        return switch value
        {
            case ArmLeft | ArmRight | LegLeft | LegRight | Torso | Head: true;
            default: false;
        }
    }
    
    static public function as(value:String):Null<Limb>
    {
        return switch value
        {
            case ArmLeft | ArmRight | LegLeft | LegRight | Torso | Head: cast value;
            default: null;
        }
    }
    
    @:pure
    inline static public function toTitleCase(str:String)
    {
        return str.charAt(0).toUpperCase() + str.substr(1);
    }
    
    static public function lowerCaseAs(str:String)
    {
        return as(toTitleCase(str));
    }
    
    static public function lowerCaseIs(str:String)
    {
        return is(toTitleCase(str));
    }
    
    /** Ordered front to back */
    static public function getAll():Array<Limb>
    {
        return 
            [ Head
            , ArmRight
            , Torso
            , LegRight
            , LegLeft
            , ArmLeft
            ];
    }
}