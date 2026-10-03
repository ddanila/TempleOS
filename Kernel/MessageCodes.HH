#help_index "Messages"
//See $LK,"::/Demo/MsgLoop.HC"$
#define MSG_NULL		0
#define MSG_CMD			1
#define MSG_KEY_DOWN		2  //($LK,"ASCII",A="MN:CH_CTRLA"$,$LK,"scan code",A="FI:::/Doc/CharOverview.DD"$) Press <CTRL-SHIFT-L>
#define MSG_KEY_UP		3  //($LK,"ASCII",A="MN:CH_CTRLA"$,$LK,"scan code",A="FI:::/Doc/CharOverview.DD"$) Press <CTRL-SHIFT-L>
#define MSG_MS_MOVE		4  //(x,y)
#define MSG_MS_L_DOWN		5  //(x,y)
#define MSG_MS_L_UP		6  //(x,y)
#define MSG_MS_L_D_DOWN 	7  //(x,y)
#define MSG_MS_L_D_UP		8  //(x,y)
#define MSG_MS_R_DOWN		9  //(x,y)
#define MSG_MS_R_UP		10 //(x,y)
#define MSG_MS_R_D_DOWN 	11 //(x,y)
#define MSG_MS_R_D_UP		12 //(x,y)

//Fake messages used to send both an up and down.
#define MSG_KEY_DOWN_UP		-2  //Down & UP
#define MSG_MS_L_DOWN_UP	-5  //Down & Up
#define MSG_MS_L_D_DOWN_UP	-7  //Down & Up
#define MSG_MS_R_DOWN_UP	-9  //Down & Up
#define MSG_MS_R_D_DOWN_UP	-11 //Down & Up

