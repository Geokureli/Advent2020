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
	public static var isLoggedIn(default, null):Bool = false;
	public static var userName(default, null):String;
	public static var scoreboardsLoaded(default, null):Bool = false;
	public static var ngDate(default, null):Date;
	public static var isWhitelisted(default, null) = false;
	
	public static var scoreboardArray:Array<Score> = [];
	
	public static var ngDataLoaded(default, null):FlxSignal = new FlxSignal();
	public static var ngScoresLoaded(default, null):FlxSignal = new FlxSignal();
	
	static var loggedEvents = new Array<NgEvent>();
	
	static public function attemptAutoLogin(callback:Void->Void) {
		
		#if NG_BYPASS_LOGIN
		NG.create(APIStuff.APIID);
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
		NG.createAndCheckSession(APIStuff.APIID, APIStuff.DebugSession, onSessionFail);
		NG.core.initEncryption(APIStuff.EncKey);
		NG.core.onLogin.add(onNGLogin);
		#if NG_VERBOSE NG.core.verbose = true; #end
		logEventOnce(view);
		
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
	
	static public function checkWhitelist():Void
	{
		if (isLoggedIn)
			isWhitelisted = false;//Calendar.checkWhitelisted(NG.core.user.name);
	}
	
	// --- MEDALS
	static function onMedalsRequested():Void
	{
		// Calendar.onMedalsRequested();
	}
	
	static public function unlockMedal(id:Int, showDebugUnlock = true):Void
	{
		if(isLoggedIn)
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
			log('no medal unlocked, loggedIn:$isLoggedIn');
	}
	
	static public function hasDayMedal(date:Int):Bool
	{
		return false;//hasMedal(MEDAL_0 + date);
	}
	
	static public function hasMedal(id:Int):Bool
	{
		return isLoggedIn && NG.core.medals.get(id).unlocked;
	}
	
	static public function logEvent(event:NgEvent, once = false)
	{
		if (loggedEvents.contains(event))
			if (once) return;
		else
			loggedEvents.push(event);
		
		NG.core.calls.event.logEvent(event + (FlxG.onMobile ? "_mobile" : "_desktop"));
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
		#if NG_NO_LOG trace(msg); #end
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
}

