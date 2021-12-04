package data;

import haxe.Json;

class Dialogue{
    public static var characters:Array<String> = ["pico"];
    public static var contentByCharacter:Map<String, DialogueContent>;

    public static function init(){
        contentByCharacter = new Map<>();
        for(character in characters){
            var content:DialogueContent = Json.parse('assets/data/dialogue/$character.json');
            contentByCharacter.set(character, content);
        }
    }
}

typedef DialogueContent = {
    var messages:Map<String,DialogueMessage>;
}

typedef DialogueMessage = {
    var text:Array<String>;
    var weight:Float;
    var fromDay:Int;
    var toDay:Int;
}