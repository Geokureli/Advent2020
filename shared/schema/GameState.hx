// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 1.0.28
// 

package schema;
import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class GameState extends Schema {
	@:type("map", Avatar)
	public var avatars: MapSchema<Avatar> = new MapSchema<Avatar>();

}
