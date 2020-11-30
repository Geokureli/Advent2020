package data;

enum EventState
{
    NoEvent;
    Day1Intro(event:Day1IntroState);
}

enum Day1IntroState
{
    Started;
    Dressed;
    Finished;
}