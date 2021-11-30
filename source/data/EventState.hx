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
    Dressed;
    Hallway;
}

enum LuciaDayState
{
    Started;
    Finding;
    Present;
}