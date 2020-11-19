package;

import zero.utilities.Vec2;
import zero.utilities.IntPoint;
import zero.utilities.Vec2;

using Util;
using Math;
using zero.extensions.FloatExt;
using zero.extensions.ArrayExt;

class Util
{
    /**
     * From https://gist.github.com/ciscoheat/4b1797fa56648adac163f44186f1823a
     */
    public static function uuid()
    {
        var uid = new StringBuf(), a = 8;
        uid.add(StringTools.hex(Std.int(Date.now().getTime()), 8));
        while((a++) < 36)
        {
            uid.add(a*51 & 52 != 0
                ? StringTools.hex(a^15 != 0 ? 8^Std.int(Math.random() * (a^20 != 0 ? 16 : 4)) : 4)
                : "-"
            );
        }
        return uid.toString().toLowerCase();
    }
}