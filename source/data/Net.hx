package data;

import utils.Log;

import schema.GameState;
import states.rooms.RoomState;

import io.colyseus.Room;
import io.colyseus.Client;

typedef JoinCallback = (error:String, room:Room<GameState>)->Void;

class Net
{
    static var netRooms:Array<RoomName> = [Hallway, Entrance, Outside, Arcade, Studio, Movie, Dance];
    
    static public var client(default, null):Client;
    static public var room(default, null):Room<GameState>;
    static public var roomName(default, null):RoomName;
    static public var connecting(default, null) = false;
    
    static public function isNetRoom(name:RoomName):Bool
    {
        return netRooms.contains(name);
    }
    
    inline static public function joinRoom(roomName:RoomName, onJoin:JoinCallback)
    {
        joinRoomWithMeta(roomName, null, onJoin);
    }
    
    static public function joinRoomWithMeta(roomName:RoomName, meta:Dynamic = null, onJoin:JoinCallback)
    {
        if (client == null)
        {
            final serverPath = 
                #if USE_LOCAL_SERVER
                'ws://localhost:2567';
                #elseif USE_DEBUG_SERVER
                'wss://advent-colyseus-test.herokuapp.com';
                #else
                'wss://advent2020server.herokuapp.com';
                #end
            log("Connecting to: " + serverPath);
            client = new Client(serverPath);
        }
        else if (room != null)
            leaveCurrentRoom();
        
        NGio.logEvent(attempt_connect);
        Net.roomName = roomName;
        connecting = true;
        
        var callback:JoinCallback = function(error, room)
        {
            onRoomJoin(error, room);
            onJoin(error, room);
        }
        
        client.getAvailableRooms(roomName,
            function (name, rooms)
            {
                var joined = false;
                if (rooms != null)
                {
                    for (i=>room in rooms)
                    {
                        // trace('$roomName=>$name, $i:${room.roomId}, ${room.metadata}');
                        if (matchesMetadata(meta, room.metadata))
                        {
                            joined = true;
                            client.joinById(room.roomId, [], GameState, callback);
                            return;
                        }
                    }
                }
                
                if (!joined)
                {
                    client.create(roomName, [], GameState, function(error, room)
                        {
                            if (meta != null)
                                room.send({ type:"meta", data:meta });
                            
                            callback(error, room);
                        }
                    );
                }
            });
        
        // client.joinOrCreate(roomName, ["version"=>"0.2.5"], GameState, 
        // client.joinOrCreate(roomName, [], GameState, onRoomJoin);
    }
    
    static function matchesMetadata(target:Dynamic, room:Dynamic)
    {
        if (target == null)
            return true;
        
        if (room == null)
            return false;
        
        var hasField = false;
        for (field in Reflect.fields(target))
        {
            hasField = true;
            if (Reflect.field(room, field) != Reflect.field(target, field))
                return false;
        }
        
        if (!hasField)
            throw "invalid metadata:{}, use null";
        
        return true;
    }
    
    static function onRoomJoin(error:String, room:Room<GameState>)
    {
        if (error == null)
        {
            log("joined:" + room.id);
            NGio.logEventOnce(first_connect);
            NGio.logEvent(connect);
        }
        
        Net.room = room;
        connecting = false;
    }
    
    inline static public function safeLeaveCurrentRoom(consented = true)
    {
        if (client != null && room != null)
            room.leave(consented);
    }
    
    static public function leaveCurrentRoom(consented = true)
    {
        if (client == null)
            throw "Attempting to leave current room before client is setup";
        
        if (room != null)
            room.leave(consented);
        
        room = null;
        roomName = null;
    }
    
    inline static public function send(type:String, data:Dynamic)
    {
        Net.logVerbose('sending type:$type=>$data)');
        room.send({ type:type, data:data });
    }
    
    inline static public function logDebug(msg:String) Log.netDebug(msg);
    inline static public function logVerbose(msg:String) Log.netVerbose(msg);
    inline static public function log(msg:String) Log.net(msg);
}