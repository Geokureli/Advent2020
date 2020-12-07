package data;

import io.newgrounds.NG;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.components.ScoreBoardComponent.Period;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.GetDateTimeResult;

import openfl.display.Stage;

import flixel.FlxG;
import flixel.util.FlxSignal;

class NGio
{
	inline static var DEBUG_SESSION = #if NG_DEBUG true #else false #end;
	
	inline static public var DAY_MEDAL_0 = 61304;
	inline static public var DIGGING_BOARD = 9728;
	
	public static var isLoggedIn(default, null):Bool = false;
	public static var userName(default, null):String;
	public static var scoreboardsLoaded(default, null):Bool = false;
	public static var ngDate(default, null):Date;
	public static var isContributor(default, null) = false;
	
	public static var scoreboardArray:Array<Score> = [];
	
	public static var ngDataLoaded(default, null):FlxSignal = new FlxSignal();
	public static var ngScoresLoaded(default, null):FlxSignal = new FlxSignal();
	
	static var loggedEvents = new Array<NgEvent>();
	
	static public function attemptAutoLogin(callback:Void->Void) {
		
		#if NG_BYPASS_LOGIN
		NG.create(APIStuff.APIID, null, DEBUG_SESSION);
		NG.core.requestScoreBoards(onScoreboardsRequested);
		callback();
		return;
		#end
		
		if (isLoggedIn)
		{
			log("already logged in");
			return;
		}
		
		ngDataLoaded.addOnce(callback);
		
		function onSessionFail(e:Error)
		{
			log("session failed:" + e.toString());
			ngDataLoaded.remove(callback);
			callback();
		}
		
		logDebug("connecting to newgrounds");
		NG.createAndCheckSession(APIStuff.APIID, DEBUG_SESSION, APIStuff.DebugSession, onSessionFail);
		NG.core.initEncryption(APIStuff.EncKey);
		NG.core.onLogin.add(onNGLogin);
		#if NG_VERBOSE NG.core.verbose = true; #end
		logEventOnce(view);
		
		// Load scoreboards even if not logging in
		NG.core.requestScoreBoards(onScoreboardsRequested);
		
		if (!NG.core.attemptingLogin)
			callback();
	}
	
	static public function startManualSession(callback:ConnectResult->Void, onPending:((Bool)->Void)->Void):Void
	{
		if (NG.core == null)
			throw "call NGio.attemptLogin first";
		
		function onClickDecide(connect:Bool):Void
		{
			if (connect)
				NG.core.openPassportUrl();
			else
			{
				NG.core.cancelLoginRequest();
				callback(Cancelled);
			}
		}
		
		NG.core.requestLogin(
			callback.bind(Succeeded),
			onPending.bind(onClickDecide),
			(error)->callback(Failed(error)),
			callback.bind(Cancelled)
		);
	}
	
	static function onNGLogin():Void
	{
		isLoggedIn = true;
		userName = NG.core.user.name;
		logDebug('logged in! user:${NG.core.user.name}');
		NG.core.requestMedals(onMedalsRequested);
		
		
		#if debug
		isContributor = true;
		#else
		isContributor = Content.isContributor(userName.toLowerCase());
		#end
		
		ngDataLoaded.dispatch();
	}
	
	static public function checkNgDate(onComplete:Void->Void):Void
	{
		NG.core.calls.gateway.getDatetime()
		.addDataHandler(
			function(response)
			{
				if (response.success && response.result.success) 
					ngDate = Date.fromString(response.result.data.dateTime.substring(0, 10));
			}
		).addSuccessHandler(onComplete)
		.addErrorHandler((_)->onComplete())
		.send();
	}
	
	// --- SCOREBOARDS
	static function onScoreboardsRequested():Void
	{
		for (board in NG.core.scoreBoards)
		{
			log('Scoreboard loded ${board.name}:${board.id}');
		}
		
		ngScoresLoaded.dispatch();
	}
	
	static public function requestHiscores(id:String, limit = 10, skip = 0, social = false, ?callback:(Array<Score>)->Void)
	{
		if (!isLoggedIn)
			throw "Must log in to access player scores";
		
		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		
		var boardId = Content.arcades[id].scoreboard;
		if (!NG.core.scoreBoards.exists(boardId))
			throw "Invalid boardId:" + boardId;
		
		var board = NG.core.scoreBoards.get(boardId);
		if (callback != null)
			board.onUpdate.addOnce(()->callback(board.scores));
		board.requestScores(limit, skip, ALL, social);
	}
	
	static public function requestPlayerHiscore(id:String, callback:(Score)->Void)
	{
		if (!isLoggedIn)
			throw "Must log in to access player scores";
		
		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		
		var boardId = Content.arcades[id].scoreboard;
		if (!NG.core.scoreBoards.exists(boardId))
			throw "Invalid boardId:" + boardId;
		
		NG.core.scoreBoards.get(boardId).requestScores(1, 0, ALL, false, null, userName);
	}
	
	static public function requestPlayerHiscoreValue(id, callback:(Int)->Void)
	{
		requestPlayerHiscore(id, (score)->callback(score.value));
	}
	
	static public function postPlayerHiscore(id:String, value:Int, ?tag)
	{
		if (!isLoggedIn)
			throw "Must log in to access player scores";
		
		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		
		var boardId = Content.arcades[id].scoreboard;
		if (!NG.core.scoreBoards.exists(boardId))
			throw "Invalid boardId:" + boardId;
		
		NG.core.scoreBoards.get(boardId).postScore(value, tag);
	}
	
	// --- MEDALS
	static function onMedalsRequested():Void
	{
		#if NG_LOG
		var numMedals = 0;
		var numMedalsLocked = 0;
		for (medal in NG.core.medals)
		{
			trace('${medal.unlocked ? "unlocked" : "locked  "} - ${medal.name}');
			
			if (!medal.unlocked)
				numMedalsLocked++;
			
			numMedals++;
		}
		trace('loaded $numMedals medals, $numMedalsLocked locked ');
		#end
	}
	
	static public function unlockDayMedal(day:Int, showDebugUnlock = true):Void
	{
		unlockMedal(DAY_MEDAL_0 + day - 1, showDebugUnlock);
	}
	
	static public function unlockMedal(id:Int, showDebugUnlock = true):Void
	{
		#if NG_DEBUG_API_KEY
		if (isLoggedIn && !Calendar.isDebugDay)
		{
			log("unlocking " + id);
			var medal = NG.core.medals.get(id);
			if (!medal.unlocked)
				medal.sendUnlock();
			else if (showDebugUnlock)
				#if debug medal.onUnlock.dispatch();
				#else log("already unlocked");
				#end
		}
		else
			log('no medal unlocked, loggedIn:$isLoggedIn debugDay${!Calendar.isDebugDay}');
		#else
		log('no medal unlocked, using debug api key');
		#end
	}
	
	static public function hasDayMedal(date:Int):Bool
	{
		return hasMedal(DAY_MEDAL_0 + date - 1);
	}
	
	static public function hasMedal(id:Int):Bool
	{
		#if NG_DEBUG_API_KEY
		return false;
		#else
		return isLoggedIn && NG.core.medals.get(id).unlocked;
		#end
	}
	
	static public function logEvent(event:NgEvent, once = false)
	{
		#if !(NG_DEBUG_API_KEY)
		if (loggedEvents.contains(event))
		{
			if (once) return;
		}
		else
			loggedEvents.push(event);
		
		event += FlxG.onMobile ? "_mobile" : "_desktop";
		logDebug("logging event: " + event);
		NG.core.calls.event.logEvent(event).send();
		#end
	}
	
	static public function logEventOnce(event:NgEvent)
	{
		logEvent(event, true);
	}
	
	inline static function logDebug(msg:String)
	{
		#if debug trace(msg); #end
	}
	
	inline static function log(msg:String)
	{
		#if NG_LOG trace(msg); #end
	}
}

enum ConnectResult
{
	Succeeded;
	Failed(error:Error);
	Cancelled;
}

enum abstract NgEvent(String) from String to String
{
	var view;
	var enter;
	var attempt_connect;
	var first_connect;
	var connect;
	var daily_present;
	var intro_complete;
	var donate;
	var donate_yes;
}

