package utils;

import haxe.PosInfos;

class Log
{
    inline static public function ogmo       (msg:String, ?info:PosInfos) { #if OGMO_LOG         trace(msg, info); #end }
    inline static public function ogmoDebug  (msg:String, ?info:PosInfos) { #if debug            ogmo(msg, info);  #end }
    inline static public function ogmoVerbose(msg:String, ?info:PosInfos) { #if OGMO_LOG_VERBOSE ogmo(msg, info);  #end }
    inline static public function ogmoError  (msg:String, ?info:PosInfos) { ogmo("Error: " + msg, info); }
    
    inline static public function ng       (msg:String, ?info:PosInfos) { #if NG_LOG         trace(msg, info); #end }
    inline static public function ngDebug  (msg:String, ?info:PosInfos) { #if debug          ng(msg, info);    #end }
    inline static public function ngVerbose(msg:String, ?info:PosInfos) { #if NG_LOG_VERBOSE ng(msg, info);    #end }
    inline static public function ngError  (msg:String, ?info:PosInfos) { ng("Error: " + msg, info); }
    
    inline static public function boot       (msg:String, ?info:PosInfos) { #if BOOT_LOG         trace(msg, info); #end }
    inline static public function bootDebug  (msg:String, ?info:PosInfos) { #if debug            boot(msg, info);  #end }
    inline static public function bootVerbose(msg:String, ?info:PosInfos) { #if BOOT_LOG_VERBOSE boot(msg, info);  #end }
    inline static public function bootError  (msg:String, ?info:PosInfos) { boot("Error: " + msg, info); }
    
    inline static public function net       (msg:String, ?info:PosInfos) { #if NET_LOG         trace(msg, info); #end }
    inline static public function netDebug  (msg:String, ?info:PosInfos) { #if debug           net(msg, info);   #end }
    inline static public function netVerbose(msg:String, ?info:PosInfos) { #if NET_LOG_VERBOSE net(msg, info);   #end }
    inline static public function netError  (msg:String, ?info:PosInfos) { net("Error: " + msg, info); }
}