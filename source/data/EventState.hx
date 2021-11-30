package data;

enum EventState
{
    NoEvent;
    Intro(event:IntroState);
    LuciaDay(event:LuciaDayState);
}

enum IntroState
{
    Started;
    Village;
}

enum LuciaDayState
{
    Started;
    Finding;
    Present;
}