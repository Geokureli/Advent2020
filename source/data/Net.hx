package data;

import schema.GameState;
import states.rooms.RoomState;

import io.colyseus.Room;
import io.colyseus.Client;

class Net
{
    static var netRooms:Array<RoomName> = [Hallway, Entrance, Outside];
    
    static public var client(default, null):Client;
    static public var room(default, null):Room<GameState>;
    static public var roomName(default, null):RoomName;
    static public var connecting(default, null) = false;
    
    static public function isNetRoom(name:RoomName):Bool
    {
        return netRooms.contains(name);
    }
    
    static public function joinRoom(roomName:RoomName, callback)
    {
        if (client == null)
        {
            #if USE_LOCAL_SERVER
            client = new Client('ws://localhost:2567');
            #else
                #if USE_DEBUG_SERVER
                client = new Client('wss://advent-colyseus-test.herokuapp.com');
                #else
                client = new Client('wss://advent2020server.herokuapp.com');
                #end
            #end
        }
        else if (room != null)
            leaveCurrentRoom();
        
        NGio.logEvent(attempt_connect);
        Net.roomName = roomName;
        connecting = true;
        client.joinOrCreate(roomName, [], GameState, 
            (error, room)->
            {
                trace("joined:" + room.id);
                if (error == null)
                {
                    NGio.logEventOnce(first_connect);
                    NGio.logEvent(connect);
                }
                
                Net.room = room;
                connecting = false;
                callback(error, room);
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