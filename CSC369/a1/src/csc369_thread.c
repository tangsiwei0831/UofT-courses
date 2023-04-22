#include "csc369_thread.h"
#define _GNU_SOURCE
#include <ucontext.h>

#include <stdlib.h>
#include <stdio.h>
//****************************************************************************
// Private Definitions
//****************************************************************************
/**
 * The Thread Control Block.
 */
typedef struct TCB
{
  ucontext_t context_content;
  Tid tid;
  int state;
  void *stk;
  struct TCB *next;
} TCB;

// 1- running
//**************************************************************************************************
// Private Global Variables (Library State)
//**************************************************************************************************
struct TCB *current = NULL;
int ids[CSC369_MAX_THREADS];
struct TCB *Ready_Start = NULL;
struct TCB *Exit_Start = NULL;
#define RUNNING 2
#define READY 1
#define EXIT 0
//**************************************************************************************************
// Helper Functions
//**************************************************************************************************
Tid id_assignment()
{
  for (int i = 0; i < CSC369_MAX_THREADS; i++)
  {
    if (!ids[i])
      return i;
  }
  return -1;
}

void thread_stub(void (*f)(void *), void *arg) {
  f(arg);
  CSC369_ThreadExit();
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
  if(ids[0])
    return CSC369_ERROR_OTHER;
  struct TCB *init_thread = (struct TCB *) malloc(sizeof (struct TCB));
  getcontext(&(init_thread->context_content));
  init_thread->tid = 0;
  init_thread->state = RUNNING;
  init_thread->next = NULL;
  init_thread->stk= NULL;
  for (int i = 0; i < CSC369_MAX_THREADS; i++) {
      ids[i] = 0;
  }
  current = init_thread;
  ids[0] = 1;
  return 0;
}

Tid
CSC369_ThreadId(void)
{
  if (current != NULL)
  {
    Tid tid = current->tid;
    return tid;
  }
  // invalid
  return -1;
}

Tid
CSC369_ThreadCreate(void (*f)(void*), void* arg)
{
  int count = 0;
  for(int i = 0; i < CSC369_MAX_THREADS; i++){
    if(ids[i]){
      count += 1;
    }
  }
  if(count == 256)
    return CSC369_ERROR_SYS_THREAD;
  
  Tid new_id = id_assignment();
  if (new_id == -1)
    return CSC369_ERROR_OTHER;
  struct TCB *new_thread = (struct TCB *) malloc(sizeof (struct TCB));
  if (!new_thread)
    return CSC369_ERROR_SYS_MEM;
  
  getcontext(&(new_thread->context_content));
  new_thread->tid = new_id;
  ids[new_id] = 1;
  new_thread->state = READY;
  new_thread->next = NULL;
  void *s = malloc(CSC369_THREAD_STACK_SIZE);
  if (s == NULL)
    return CSC369_ERROR_SYS_MEM;
  new_thread->stk = s;

  new_thread->context_content.uc_mcontext.gregs[REG_RBP] = (unsigned long) s;
  new_thread->context_content.uc_mcontext.gregs[REG_RDI] = (unsigned long) f;
  new_thread->context_content.uc_mcontext.gregs[REG_RSI] = (unsigned long) arg;
  new_thread->context_content.uc_mcontext.gregs[REG_RIP] = (unsigned long) thread_stub;

  new_thread->context_content.uc_stack.ss_sp = s;                              
  new_thread->context_content.uc_stack.ss_size = CSC369_ERROR_SYS_MEM;                        

  new_thread->context_content.uc_mcontext.gregs[REG_RSP] = (unsigned long) (s + CSC369_THREAD_STACK_SIZE - 8);
  if (Ready_Start == NULL)
      Ready_Start = new_thread;
  else {
      struct TCB *temp = Ready_Start;
      while (temp->next != NULL)
          temp = temp->next;
      temp->next = new_thread;
  }
  return new_thread->tid;
}

void
CSC369_ThreadExit()
{
  if(Ready_Start == NULL)
    exit(0);
  struct TCB *temp = current;
  struct TCB *new_current = Ready_Start;
  Ready_Start = Ready_Start->next;
  temp->next = NULL;
  temp->state = EXIT;
  ids[temp->tid] = 0;
  
  if (Exit_Start == NULL)
    Exit_Start = temp;
  else {
    struct TCB *index = Exit_Start;
    while (index->next != NULL)
        index = index->next;
    index->next = temp;
  }

  new_current->state = RUNNING;
  new_current->next = NULL;
  current = new_current;
  int err = setcontext(&(new_current->context_content));
  if(!err){
    exit(-1);
  }
}

Tid
CSC369_ThreadKill(Tid tid)
{
  if (!(tid >= 0 && tid < CSC369_MAX_THREADS)){
    return CSC369_ERROR_TID_INVALID;
  }
  if (tid == CSC369_ThreadId()){
    return CSC369_ERROR_THREAD_BAD;
  }
  if (!(ids[tid] != 0 && Ready_Start)){
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
  if (!temp2){
    return CSC369_ERROR_THREAD_BAD;
  }
  free(temp2->stk);
  free(temp2);
  ids[tid] = 0;
  return tid;
}

int
CSC369_ThreadYield()
{ 
  if (Ready_Start == NULL){
    return current->tid;
  } else {
    struct TCB *temp = Ready_Start;
    Ready_Start = Ready_Start->next;
    temp->next = NULL;
    current->state = READY;
    if (Ready_Start == NULL)
        Ready_Start = current;
    else {
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
          return CSC369_ERROR_OTHER;
        }
    }
    return res;
  }
}

int
CSC369_ThreadYieldTo(Tid tid)
{
  if (!(tid >= 0 && tid < CSC369_MAX_THREADS))
    return CSC369_ERROR_TID_INVALID;
  
  if (tid == current->tid)
    return current->tid;
  
  if (Exit_Start != NULL){
    struct TCB *temp_exit = Exit_Start;
    struct TCB *prev_exit = Exit_Start;
    while (temp_exit->tid != tid && temp_exit != NULL) {
      prev_exit = temp_exit;
      temp_exit = temp_exit->next;
    }
    if (temp_exit != NULL){
      return CSC369_ERROR_THREAD_BAD;
    } 
  }
  struct TCB *temp_ready = Ready_Start;
  struct TCB *prev_ready = Ready_Start;
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
      return CSC369_ERROR_OTHER;
    }
  }
  return res;
}