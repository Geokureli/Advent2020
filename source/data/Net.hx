package data;

import schema.GameState;

import io.colyseus.Room;
import io.colyseus.Client;

class Net
{
    static public var client(default, null):Client;
    static public var room(default, null):Room<GameState>;
    static public var roomName(default, null):RoomName;
    static public var connecting(default, null) = false;
    
    static public function joinRoom(roomName:RoomName, callback)
    {
        if (client == null)
        {
            #if debug
            client = new Client('ws://localhost:2567');
            #else
            client = new Client('wss://advent-colyseus-test.herokuapp.com');
            #end
        }
        else if (room != null)
            leaveCurrentRoom();
        
        Net.roomName = roomName;
        connecting = true;
        client.joinOrCreate(roomName, [], GameState, 
            (err, room)->
            {
                Net.room = room;
                connecting = false;
                callback(err, room);
            }
        );
    }
    
    static public function leaveCurrentRoom(consented = true)
    {
        if (client == null)
            throw "Attempting to leave current room before client is setup";
        
        if (room != null)
            room.leave();
        
        room = null;
        roomName = null;
    }
    
    inline static public function send(type:String, data:Dynamic)
    {
        room.send({ type:type, data:data });
    }
}

enum abstract RoomName(String) to String
{
    var Cabin = "cabin";
    var Outside = "outside";
}