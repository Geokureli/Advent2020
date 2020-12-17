// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 0.5.36
// 

package schema;
import io.colyseus.serializer.schema.Schema;

class DanceGameState extends GameState {
	@:type("map", "number")
	public var songs: MapSchema<Dynamic> = new MapSchema<Dynamic>();

	@:type("number")
	public var songStartTime: Dynamic = 0;

}
