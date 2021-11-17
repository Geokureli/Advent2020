// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 0.5.36
// 

package schema;
import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.MapSchema;

class GameState extends Schema {
	@:type("map", Avatar)
	public var avatars: MapSchema<Avatar> = new MapSchema<Avatar>();

}
