package data;

import utils.Log;

import schema.GameState;
import states.rooms.RoomState;

import flixel.util.FlxTimer;

import io.colyseus.Room;
import io.colyseus.Client;

class Net
{
    @:allow(data.Game)
    static var netRooms:Array<RoomName> = [];
    
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
            if (false == NGio.validMajorVersion)
            {
                log('Cancelling client connect, version mismatch. client:${NGio.clientVersion} server:${NGio.serverVersion}');
                return;
            }
            
            final serverPath = 
                #if USE_LOCAL_SERVER
                'ws://localhost:2567';
                // #elseif USE_DEBUG_SERVER
                // 'wss://advent-colyseus-test.herokuapp.com';
                #else
                'wss://tankmas2021.herokuapp.com';
                // 'wss://advent2020server.herokuapp.com';
                #end
            log("Connecting to: " + serverPath);
            client = new Client(serverPath);
        }
        else if (room != null)
            leaveCurrentRoom();
        
        if (false == NGio.validMajorVersion)
        {
            log('Cancelling room join, version mismatch. client:${NGio.clientVersion} server:${NGio.serverVersion}');
            return;
        }
        
        NGio.logEvent(attempt_connect);
        Net.roomName = roomName;
        connecting = true;
        
        // client.getAvailableRooms(roomName,
        //     function (name, rooms)
        //     {
        //         for (i=>room in rooms)
        //         {
        //             trace('$roomName=>$name, $i:${room.roomId}, ${room.metadata}');
        //             // if (room.metadata && room.metadata.friendlyFire)
        //             // {
                        
        //                 // join the room with `friendlyFire` by id:
                        
        //                 // var room = client.join(room.roomId);
        //                 // return;
        //             // }
        //         }
        //     });
        
        // client.joinOrCreate(roomName, ["version"=>"0.2.5"], GameState, 
        client.joinOrCreate(roomName, [], GameState, 
            (error, room)->
            {
                if (error == null)
                {
                    log("joined:" + room.id);
                    NGio.logEventOnce(first_connect);
                    NGio.logEvent(connect);
                    
                    function checkServerVersion(?timer:FlxTimer)
                    {
                        if (false == NGio.validMajorVersion)
                        {
                            leaveCurrentRoom();
                            if (timer != null)
                                timer.cancel();
                        }
                    }
                    
                    new FlxTimer().start(30, (t)->NGio.updateServerVersion(checkServerVersion.bind(t)), 0);
                    NGio.updateServerVersion(checkServerVersion.bind());
                }
                
                Net.room = room;
                connecting = false;
                callback(error, room);
            }
        );
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
        room.send(type, data);
    }
    
    inline static public function logDebug(msg:String) Log.netDebug(msg);
    inline static public function logVerbose(msg:String) Log.netVerbose(msg);
    inline static public function log(msg:String) Log.net(msg);
}