//Native HolyC startup, read from RedSea by the console task before its first prompt.
//Add definitions and commands here to customize the initial interactive scope.
//The compiler executes this source on the target; it is not an AOT startup module.
//Successful definitions persist for subsequent commands. A failed input unwinds
//its private definitions but does not undo side effects already executed.
//Only the currently integrated native language and runtime providers are available.
#define NULL 0
#define TRUE 1
#define FALSE 0
