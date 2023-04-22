#include "csc369_thread.h"
#define _GNU_SOURCE 
#include <ucontext.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/time.h>

// TODO: You may find this useful, otherwise remove it
//#define DEBUG_USE_VALGRIND // uncomment to debug with valgrind
#ifdef DEBUG_USE_VALGRIND
#include <valgrind/valgrind.h>
#endif

#include "csc369_interrupts.h"

//****************************************************************************
// Private Definitions
//****************************************************************************
// TODO: You may find this useful, otherwise remove it
typedef enum
{
  CSC369_THREAD_FREE = 0,
  CSC369_THREAD_READY = 1,
  CSC369_THREAD_RUNNING = 2,
  CSC369_THREAD_ZOMBIE = 3,
  CSC369_THREAD_BLOCKED = 4
} CSC369_ThreadState;

/**
 * The Thread Control Block.
 */
typedef struct TCB
{
  int exit_code; // TODO: You may find this useful, otherwise remove it

  /**
   * The queue of threads that are waiting on this thread to finish.
   */
  CSC369_WaitQueue* join_threads; // TODO: You may find this useful, otherwise remove it

  ucontext_t context_content;  
  Tid tid;  
  int state;  
  struct TCB *next; 
} TCB;

/**
 * A wait queue.
 */
typedef struct csc369_wait_queue_t
{
  TCB* head;
  TCB* owner;
  // struct csc369_wait_queue_t* next;
}csc369_wait_queue_t;

struct TCB *current = NULL;  
int ids[CSC369_MAX_THREADS]; 
struct TCB *join_TCB[CSC369_MAX_THREADS]; 
struct TCB *Ready_Start = NULL;  
struct TCB *Exit_Start = NULL;  
#define BLOCK 3
#define RUNNING 2  
#define READY 1  
#define EXIT 0  


//**************************************************************************************************
// Private Global Variables (Library State)
//**************************************************************************************************
/**
 * All possible threads have their control blocks stored contiguously in memory.
 */
TCB threads[CSC369_MAX_THREADS]; // TODO: you may find this useful, otherwise remove it

/**
 * Threads that are ready to run in FIFO order.
 */
CSC369_WaitQueue ready_threads; // TODO: you may find this useful, otherwise remove it

/**
 * Threads that need to be cleaned up.
 */
CSC369_WaitQueue zombie_threads; // TODO: you may find this useful, otherwise remove it

//**************************************************************************************************
// Helper Functions
//**************************************************************************************************
int // TODO: You may find this useful, otherwise remove it
Queue_IsEmpty(csc369_wait_queue_t* queue)
{
  if(queue->head == NULL){
    return 0;
  }
  return 1;
}

int // TODO: You may find this useful, otherwise remove it
Queue_Enqueue(csc369_wait_queue_t* queue, TCB* tcb)
{
	struct TCB *head = queue->head;
  if (head == NULL){
      queue->head = tcb;
  } else {
      struct TCB *temp = head;
      while (temp->next != NULL)
          temp = temp->next;
      temp->next = tcb;
  }
}

TCB* // TODO: You may find this useful, otherwise remove it
Queue_Dequeue(csc369_wait_queue_t* queue)
{
  struct TCB* temp = queue->head;
  if(queue->head == NULL){
    return NULL;
  }
  if(queue->head->next == NULL){
    queue->head = NULL;
  }else{
    queue->head = queue->head->next;
    temp->next = NULL;
  }
  return temp;
}

// TODO: You may find it useful to create a helper function to create a context
// TODO: You may find it useful to create a helper function to switch contexts
void insert_thread_to_ready(struct TCB* new_thread) {
  new_thread->state = READY;
  join_TCB[new_thread->tid] = NULL;
  if (Ready_Start == NULL){
      Ready_Start = new_thread; 
  }
  else {
      struct TCB *temp = Ready_Start;
      while (temp->next != NULL){
        temp = temp->next;
      }
      temp->next = new_thread;
  }
  struct TCB *temp2 = new_thread;
  while(temp2->next != NULL){
    temp2->next->state = READY;
    temp2 = temp2->next;
  }
}

int count(struct csc369_wait_queue_t* queue){
  struct TCB* temp = queue->head;

  /* Initialize count variable  */
  int count=0;
  /* Traverse the linked list and maintain the count */
  while(temp != NULL){

      temp = temp->next;

      count++;
  }
  return count;
}

Tid id_assignment()  
{  
  for (int i = 0; i < CSC369_MAX_THREADS; i++)  
  {  
    if (ids[i] == 0)  
      return i;  
  }  
  return -1;  
}  
  
void thread_stub(void (*f)(void *), void *arg) {  
  CSC369_InterruptsEnable();
  f(arg);  
  CSC369_ThreadExit(CSC369_EXIT_CODE_NORMAL);  
}  
  
struct TCB *exit_node(int flag, Tid tid){  
  if(flag == 0){  
    struct TCB *temp = Ready_Start;  
    struct TCB *prev = Ready_Start;  
    while (temp->tid != tid) {  
      prev = temp;  
      temp = temp->next;  
    }  
    if (temp != NULL){  
      if (Ready_Start->tid == tid){  
        Ready_Start = Ready_Start->next;  
      } else {  
        prev->next = temp->next;  
      }  
      return temp;  
    }  
    return NULL;  
  }else{  
    if(!Exit_Start){  
      return NULL;  
    }  
    struct TCB *temp = Exit_Start;  
    struct TCB *prev = Exit_Start;  
    while (temp->tid != tid) {  
      prev = temp;  
      temp = temp->next;  
    }  
    if (temp != NULL){  
      if (Exit_Start->tid == tid){  
        Exit_Start = Exit_Start->next;  
      } else {  
        prev->next = temp->next;  
      }  
      return temp;  
    }  
    return NULL;  
  }  
}  
//**************************************************************************************************
// thread.h Functions
//**************************************************************************************************
int
CSC369_ThreadInit(void)
{
  if(ids[0]){
    return CSC369_ERROR_OTHER;  
  }
  struct TCB *init_thread = (struct TCB *) malloc(sizeof (struct TCB));  
  struct csc369_wait_queue_t *init_queue = CSC369_WaitQueueCreate(); 
  getcontext(&(init_thread->context_content));  
  init_thread->tid = 0;  
  init_thread->state = RUNNING;  
  init_thread->next = NULL;  
  init_thread->join_threads = init_queue;
  for (int i = 0; i < CSC369_MAX_THREADS; i++) {  
      ids[i] = 0;  
      join_TCB[i] = NULL;
  }  
  Ready_Start = NULL;
  current = init_thread; 
  init_queue->owner = init_thread; 
  ids[0] = 1;  
  return 0;  
}

Tid
CSC369_ThreadId(void)
{
  int const prev_state =  CSC369_InterruptsDisable();
  if (current != NULL){  
    return current->tid;  
  }  
  // invalid  
  CSC369_InterruptsSet(prev_state);
  return -1;  
}

Tid
CSC369_ThreadCreate(void (*f)(void*), void* arg)
{
  int const prev_state = CSC369_InterruptsDisable();
    
  Tid new_id = id_assignment();  
  if (new_id == -1){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_SYS_THREAD;  
  }  
  struct TCB *new_thread = (struct TCB *) malloc(sizeof (struct TCB));  
  struct csc369_wait_queue_t *new_queue = CSC369_WaitQueueCreate();
  if (!new_thread){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_SYS_MEM; 
  } 
  getcontext(&(new_thread->context_content));  
  new_thread->tid = new_id;  
  ids[new_id] = 1;  
  new_thread->state = READY;  
  new_thread->next = NULL;  
  new_thread->join_threads = new_queue;
  new_queue->owner = new_thread;
  void *s = malloc(CSC369_THREAD_STACK_SIZE + 32);  
  if (s == NULL){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_SYS_MEM;
  }  

  new_thread->context_content.uc_mcontext.gregs[REG_RBP] = (unsigned long) s;  
  new_thread->context_content.uc_mcontext.gregs[REG_RDI] = (unsigned long) f;  
  new_thread->context_content.uc_mcontext.gregs[REG_RSI] = (unsigned long) arg;  
  new_thread->context_content.uc_mcontext.gregs[REG_RIP] = (unsigned long) thread_stub;  
  
  new_thread->context_content.uc_stack.ss_sp = s;                                
  new_thread->context_content.uc_stack.ss_size = CSC369_THREAD_STACK_SIZE;                          
  
  new_thread->context_content.uc_mcontext.gregs[REG_RSP] = (unsigned long) (s + CSC369_THREAD_STACK_SIZE - 8); 
  if(Ready_Start == NULL){
    Ready_Start = new_thread; 
  }else{  
    struct TCB *temp = Ready_Start;  
    while(temp->next != NULL){
      temp = temp->next;
    }  
    temp->next = new_thread;  
  }  
  CSC369_InterruptsSet(prev_state);
  return new_thread->tid;  
}
 
// add a input parameter!!!
void
CSC369_ThreadExit(int exit_code)
{
  int const prev_state = CSC369_InterruptsDisable();
  struct TCB *temp = current;
  CSC369_ThreadWakeAll(temp->join_threads);
  if(Ready_Start == NULL){
    exit(exit_code);
  }
  struct TCB *new_current = Ready_Start;  
  Ready_Start = Ready_Start->next;  
  temp->next = NULL;  
  temp->state = EXIT;  
  temp->exit_code = exit_code;
  ids[temp->tid] = 0;  
  if (Exit_Start == NULL){
    Exit_Start = temp;
  } else {  
    struct TCB *index = Exit_Start;  
    while (index->next != NULL){
      index = index->next;
    }    
    index->next = temp;  
  }  
  
  new_current->state = RUNNING;  
  new_current->next = NULL;  
  current = new_current;  
  int err = setcontext(&(new_current->context_content));  
  if(!err){  
    exit(CSC369_EXIT_CODE_FATAL);  
  } 
  
  CSC369_InterruptsSet(prev_state);
}

Tid
CSC369_ThreadKill(Tid tid)
{
  int const prev_state = CSC369_InterruptsDisable();
  if (!(tid >= 0 && tid < CSC369_MAX_THREADS)){  
    return CSC369_ERROR_TID_INVALID;  
  }  
  if (tid == CSC369_ThreadId()){  
    return CSC369_ERROR_THREAD_BAD;  
  } 
  if(join_TCB[tid] != NULL){
    struct csc369_wait_queue_t *wq = join_TCB[tid]->join_threads;
    struct TCB *temp_kill_1 = wq->head;
    struct TCB *temp_kill_2 = wq->head;  
    while (temp_kill_2->tid != tid && temp_kill_2 != NULL) {  
      temp_kill_1 = temp_kill_2;  
      temp_kill_2 = temp_kill_2->next;  
    }
    temp_kill_1->next = temp_kill_2->next;
    join_TCB[tid] = NULL;
    ids[temp_kill_2->tid] = 0;
    free(temp_kill_2->join_threads);
    free(temp_kill_2->context_content.uc_stack.ss_sp);
    free(temp_kill_2); 
    return tid;
  }
  if (!(ids[tid] != 0 && Ready_Start )){  
    return CSC369_ERROR_SYS_THREAD;  
  } 
  struct TCB *temp2;  
  struct TCB *res = exit_node(0, tid);  
  struct TCB *exit = exit_node(1, tid);  
  if(res){  
    temp2 = res;  
  }  
  if(exit){  
    temp2 = exit;  
  }  
  if(!temp2){  
    return CSC369_ERROR_THREAD_BAD;  
  }  
  free(temp2->join_threads);
  free(temp2->context_content.uc_stack.ss_sp);
  free(temp2);  
  ids[tid] = 0;  
  CSC369_InterruptsSet(prev_state);
  return tid;
}

int
CSC369_ThreadYield()
{
  int const prev_state = CSC369_InterruptsDisable();
  if (Ready_Start == NULL){  
    CSC369_InterruptsSet(prev_state);
    return current->tid;  
  } else {  
    struct TCB *temp = Ready_Start;  
    Ready_Start = Ready_Start->next;  
    temp->next = NULL;  
    current->state = READY;  
    if (Ready_Start == NULL){
      Ready_Start = current; 
    } else {  
        struct TCB *temp = Ready_Start;  
        while (temp->next != NULL)  
            temp = temp->next;  
        temp->next = current;  
    }  
    getcontext(&(current->context_content));  
    Tid res = temp->tid;  
    if (temp->state == READY && current->state != RUNNING) {  
        temp->state = RUNNING;  
        current = temp;  
        int error = setcontext(&(temp->context_content));  
        if(!error){  
          CSC369_InterruptsSet(prev_state);
          return CSC369_ERROR_OTHER;  
        }  
    }  
    CSC369_InterruptsSet(prev_state);
    return res;  
  } 
}

int
CSC369_ThreadYieldTo(Tid tid){
  int const prev_state = CSC369_InterruptsDisable();
  if (!(tid >= 0 && tid < CSC369_MAX_THREADS)){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_TID_INVALID; 
  } 
  if (ids[tid] == 0){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_THREAD_BAD; 
  } 
  
  if (tid == current->tid){
    CSC369_InterruptsSet(prev_state);
    return current->tid;
  }  
    
  if (Exit_Start != NULL){  
    struct TCB *temp_exit = Exit_Start;  
    struct TCB *prev_exit = Exit_Start;  
    while (temp_exit->tid != tid && temp_exit != NULL) {  
      prev_exit = temp_exit;  
      temp_exit = temp_exit->next;  
    }  
    if (temp_exit != NULL){  
      CSC369_InterruptsSet(prev_state);
      return CSC369_ERROR_THREAD_BAD;  
    }   
  }  
  struct TCB *temp_ready = Ready_Start;  
  struct TCB *prev_ready = Ready_Start;  
  if (temp_ready == NULL){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_THREAD_BAD;
  }
  while (temp_ready->tid != tid && temp_ready != NULL) {  
    prev_ready = temp_ready;  
    temp_ready = temp_ready->next;  
  }  
  if (Ready_Start->tid == tid){  
    Ready_Start = Ready_Start->next;  
  } else {  
    prev_ready->next = temp_ready->next;  
  }  
  temp_ready->next = NULL;  
  current->state = READY;  
  
  if (Ready_Start == NULL){  
    Ready_Start = current;  
  }else{  
    struct TCB *temp_ready = Ready_Start;  
    while (temp_ready->next != NULL)  
        temp_ready = temp_ready->next;  
    temp_ready->next = current;  
  }  
  getcontext(&(current->context_content));  
  int res = temp_ready->tid;  
  if (temp_ready->state == READY && current->state != RUNNING){  
    temp_ready->state = RUNNING;  
    current = temp_ready;  
    int error = setcontext(&(current->context_content));  
    if(!error){  
      CSC369_InterruptsSet(prev_state);
      return CSC369_ERROR_OTHER;  
    }  
  }  
  CSC369_InterruptsSet(prev_state);
  return res; 
}

//****************************************************************************
// New Assignment 2 Definitions - Task 2
//****************************************************************************
csc369_wait_queue_t*
CSC369_WaitQueueCreate(void)
{
  struct csc369_wait_queue_t* wq = malloc(sizeof(struct csc369_wait_queue_t));

	wq->head = NULL;
  wq->owner = NULL;
  return wq;
}

int
CSC369_WaitQueueDestroy(CSC369_WaitQueue* queue)
{
  if(queue->head != NULL){
    return CSC369_ERROR_OTHER;
  }
  free(queue);
  return 0;
}

void
CSC369_ThreadSpin(int duration)
{
  struct timeval start, end, diff;

  int ret = gettimeofday(&start, NULL);
  assert(!ret);

  while (1) {
    ret = gettimeofday(&end, NULL);
    assert(!ret);
    timersub(&end, &start, &diff);

    if ((diff.tv_sec * 1000000 + diff.tv_usec) >= duration) {
      return;
    }
  }
}

int
CSC369_ThreadSleep(CSC369_WaitQueue* queue)
{
  assert(queue != NULL);
  int const prev_state = CSC369_InterruptsDisable();
  if(Ready_Start == NULL){
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_SYS_THREAD;
  }else{
    struct TCB *temp = Ready_Start;
    Ready_Start = Ready_Start->next;
    temp->next = NULL;
    Tid returned_tid = current->tid;
    current->state = BLOCK;
    Queue_Enqueue(queue, current);

    join_TCB[current->tid] = queue->owner;
    
    getcontext(&(current->context_content));
    
    if(temp->state == READY && current->state != RUNNING){
      temp->state = RUNNING;
      current = temp;
      int error = setcontext(&(temp->context_content));  
      if(!error){  
        CSC369_InterruptsSet(prev_state);
        return CSC369_ERROR_OTHER;  
      } 
    }
    CSC369_InterruptsSet(prev_state);
    return returned_tid;
  }
}

int
CSC369_ThreadWakeNext(CSC369_WaitQueue* queue)
{
  // return -1;
  assert(queue != NULL);
  int count = 0;
  struct TCB* dropped = Queue_Dequeue(queue);
  dropped->state = READY;
  insert_thread_to_ready(dropped);
  count = 1 - Queue_IsEmpty(queue);
  return count;
}

int
CSC369_ThreadWakeAll(CSC369_WaitQueue* queue)
{
  assert(queue != NULL);
  if (queue->head == NULL){
    return 0;
  }
  int i = count(queue);
  insert_thread_to_ready(queue->head);
  queue->head = NULL;
  return i;
}

//****************************************************************************
// New Assignment 2 Definitions - Task 3
//****************************************************************************
int
CSC369_ThreadJoin(Tid tid, int* exit_code)
{
  int const prev_state = CSC369_InterruptsDisable();
  if (!(tid >= 0 && tid < CSC369_MAX_THREADS)){ 
    CSC369_InterruptsSet(prev_state); 
    return CSC369_ERROR_TID_INVALID;  
  }  
  if (tid == CSC369_ThreadId()){  
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_THREAD_BAD;  
  }  
  if (ids[tid] == 0){  
    CSC369_InterruptsSet(prev_state);
    return CSC369_ERROR_SYS_THREAD;  
  }
  struct TCB * temp_ready = Ready_Start;
  if(Ready_Start == NULL){
  }
  while(temp_ready!= NULL && temp_ready->tid != tid ){
    temp_ready = temp_ready->next;
  }
  if(temp_ready != NULL){
    CSC369_ThreadSleep(temp_ready->join_threads);
    *exit_code = temp_ready->exit_code;
    CSC369_InterruptsSet(prev_state);
    return temp_ready->tid;
  }else{
    struct TCB * temp_exit = Exit_Start;
    while(temp_exit!= NULL && temp_exit->tid != tid){
      printf("%d\n", 627);
      temp_exit = temp_exit->next;
    }
    if(temp_exit != NULL){
      CSC369_InterruptsSet(prev_state);
      return temp_exit->exit_code;
    }else{
      CSC369_InterruptsSet(prev_state);
      return CSC369_ERROR_SYS_THREAD;
    }
  }
}
