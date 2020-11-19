package;

import zero.utilities.Vec2;
import zero.utilities.IntPoint;
import zero.utilities.Vec2;

using Util;
using Math;
using zero.extensions.FloatExt;
using zero.extensions.ArrayExt;

class Util {

  public static var directions = [
    IntPoint.get(1, 0),
    IntPoint.get(1, 1),
    IntPoint.get(0, 1),
    IntPoint.get(-1, 1),
    IntPoint.get(-1, 0),
    IntPoint.get(-1, -1),
    IntPoint.get(0, -1),
    IntPoint.get(1, -1)
  ];
  /**
   * From https://gist.github.com/ciscoheat/4b1797fa56648adac163f44186f1823a
   */
   public static function uuid() {
		var uid = new StringBuf(), a = 8;
		uid.add(StringTools.hex(Std.int(Date.now().getTime()), 8));
		while((a++) < 36) {
			uid.add(a*51 & 52 != 0
				? StringTools.hex(a^15 != 0 ? 8^Std.int(Math.random() * (a^20 != 0 ? 16 : 4)) : 4)
				: "-"
			);
		}
		return uid.toString().toLowerCase();
	}
	
	public static inline function in_circle(p:Vec2, c:Vec2, r:Float) {
    return p.distance(c) < r;
  }

  public static inline function rad_between(v1:Vec2, v2:Vec2):Float {
    return Math.atan2(v2.y - v1.y, v2.x - v1.x);
	}
	
	public static inline function set_rect(arr:Array<Array<Int>>, x:Int, y:Int, width:Int, height:Int, index:Int) {
		for (row in 0...arr.length) {
			if (row >= y && row <= y + height) for (col in 0...arr[row].length) {
				if(col >= x && col <= x + width) arr[row][col] = index;
			}
		}
	}

	public static inline function set_circle(arr:Array<Array<Int>>, x:Int, y:Int, radius:Int, index:Int) {
		for (row in 0...arr.length) for (col in 0...arr[row].length) {
			// ((x1 - start_X) * (x1 - start_X) + (y1 - start_Y) * (y1 - start_Y)) <= r * r
			if ((col - x) * (col - x) + (row - y) * (row - y) <= radius * radius) arr[row][col] = index;
		}
  }
  
  public static function surrounding_tiles_match(arr:Array<Array<Int>>, index:Int, x:Int, y:Int) {
    for (direction in directions) {
      var tile = arr.get_xy(x + direction.x, y + direction.y);
      if (tile == null || tile != index) return false;

    }
    return true;
  } 

	public static function generate_map(width:Float, height:Float, tile_width:Float, tile_height:Float):Array<Array<Int>> {
    var width_in_tiles = width / tile_width;
    var height_in_tiles = height / tile_height;

    // Generate Base
    var map = [for (y in 0...height_in_tiles.to_int()) [for (x in 0...width_in_tiles.to_int()) 1]];

    // Generate Treeline

    // Generate Water
    var center = IntPoint.get(width_in_tiles.half().to_int(), height_in_tiles.half().to_int());
    
    // for (i in 0...3) {
    //   var ran_w = 6.get_random(14).to_int();
    //   var ran_h = 6.get_random(14).to_int();
    //   var ran_x = ((center.x - 7).get_random(center.x + 7) - ran_w.half()).to_int();
    //   var ran_y = ((center.y - 7).get_random(center.y + 7) - ran_h.half()).to_int();
    //   map.set_rect(ran_x , ran_y, ran_w, ran_h, 0);
    // }

    for (i in 0...6) {
      var ran_r = 4.get_random(8).to_int();
      var ran_x = ((center.x - 6).get_random(center.x + 6)).to_int();
      var ran_y = ((center.y - 6).get_random(center.y + 6)).to_int();
      map.set_circle(ran_x , ran_y, ran_r, 0);
    }

    var tree_count = 15;
    var rock_count = 15;
    
    // Generate Trees
		for (i in 0...tree_count) {
      var x = (width_in_tiles - 1).get_random(1).to_int();
      var y = (height_in_tiles - 1).get_random(1).to_int();
      if (map.get_xy(x, y) != 1) continue;
      map.set_xy(x, y, 2);
    }

    // Generate Rocks
    for (i in 0...rock_count) {
      var x = (width_in_tiles - 1).get_random(1).to_int();
      var y = (height_in_tiles - 1).get_random(1).to_int();
      if (map.get_xy(x, y) != 1) continue;
      map.set_xy(x, y, 3);
    }

		return map;
	}

}