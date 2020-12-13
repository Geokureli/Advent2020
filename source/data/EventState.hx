package data;

enum EventState
{
    NoEvent;
    Day1Intro(event:Day1IntroState);
    LuciaDay(event:LuciaDayState);
}

enum Day1IntroState
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