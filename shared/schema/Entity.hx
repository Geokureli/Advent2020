// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 0.5.36
// 

package schema;
import io.colyseus.serializer.schema.Schema;

class Entity extends Schema
{
	@:type("string")
	public var id: String = "";

	@:type("number")
	public var x: Dynamic = 0;

	@:type("number")
	public var y: Dynamic = 0;

	@:type("number")
	public var rotation: Dynamic = 0;

	@:type("uint8")
	public var type: UInt = 0;

	@:type("uint8")
	public var state: UInt = 0;

	@:type("number")
	public var color: Dynamic = 0;

}
