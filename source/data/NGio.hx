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
	
	static public function attemptAutoLogin(callback:Void->Void) {
		
		#if BYPASS_LOGIN
		NG.create(APIStuff.APIID);
		callback();
		return;
		#end
		
		if (isLoggedIn)
		{
			trace("already logged in");
			return;
		}
		
		ngDataLoaded.addOnce(callback);
		
		function onSessionFail(e)
		{
			ngDataLoaded.remove(callback);
			callback();
		}
		
		trace("connecting to newgrounds");
		NG.createAndCheckSession(APIStuff.APIID, APIStuff.DebugSession, onSessionFail);
		NG.core.initEncryption(APIStuff.EncKey);
		NG.core.onLogin.add(onNGLogin);
		#if debug NG.core.verbose = true; #end
		
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
		trace ('logged in! user:${NG.core.user.name}');
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
			trace("unlocking " + id);
			var medal = NG.core.medals.get(id);
			if (!medal.unlocked)
				medal.sendUnlock();
			else if (showDebugUnlock)
				#if debug medal.onUnlock.dispatch();
				#else trace("already unlocked");
				#end
		}
		else
			trace('no medal unlocked, loggedIn:$isLoggedIn');
	}
	
	static public function hasDayMedal(date:Int):Bool
	{
		return false;//hasMedal(MEDAL_0 + date);
	}
	
	static public function hasMedal(id:Int):Bool
	{
		return isLoggedIn && NG.core.medals.get(id).unlocked;
	}
}

enum ConnectResult
{
	Succeeded;
	Failed(error:Error);
	Cancelled;
}