//Fixed storage; callers serialize access. Only adjacent non-edge motion coalesces.
class CI386MouseEvent {I64 x,y,stamp;U32 buttons;Bool transition;};
class CI386MouseEvents {
  CI386MouseEvent events[64];
  U32 read,write,count,losses,last_buttons;
};
U0 I386MouseEventPush(CI386MouseEvents *queue,I64 x,I64 y,U32 buttons,I64 stamp)
{
  CI386MouseEvent *event;
  U32 slot;
  Bool transition=buttons!=queue->last_buttons;
  queue->last_buttons=buttons;
  if(!transition && queue->count) {
    slot=(queue->write+63)&63;event=&queue->events[slot];
    if(!event->transition && event->buttons==buttons)goto mouse_queue_store;
  }
  if(queue->count==64) {
    queue->losses++;
    queue->read=queue->write=queue->count=0;
  }
  slot=queue->write;queue->write=(slot+1)&63;queue->count++;
  event=&queue->events[slot];
mouse_queue_store:
  event->x=x;event->y=y;event->stamp=stamp;event->buttons=buttons;
  event->transition=transition;
}
Bool I386MouseEventPop(CI386MouseEvents *queue,CI386MouseEvent *event)
{
  if(!queue->count)return FALSE;
  MemCpy(event,&queue->events[queue->read],sizeof(CI386MouseEvent));
  queue->read=(queue->read+1)&63;queue->count--;return TRUE;
}
