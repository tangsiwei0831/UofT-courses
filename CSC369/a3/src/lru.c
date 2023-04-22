#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "pagetable_generic.h"

/* Page to evict is chosen using the accurate LRU algorithm.
 * Returns the page frame number (which is also the index in the coremap)
 * for the page that is to be evicted.
 */
extern struct frame *coremap;

struct frame* head_of_lru;
struct frame* tail_of_lru;

int
lru_evict(void)
{
  struct frame *new_frame = head_of_lru->next;
  frame_list_delete(new_frame);
  return new_frame - coremap;
}

/* This function is called on each access to a page to update any information
 * needed by the LRU algorithm.
 * Input: The page table entry for the page that is being accessed.
 */
void
lru_ref(int frame)
{
  struct frame *check = &coremap[frame];
  if(check->in_use == true){
    if(check->next){
      frame_list_delete(check);
    }
  }
  frame_list_insert(check, tail_of_lru->prev, tail_of_lru);
}

/* Initialize any data structures needed for this replacement algorithm. */
void
lru_init(void)
{
  head_of_lru = (struct frame*)malloc(sizeof(struct frame));
  tail_of_lru = (struct frame*)malloc(sizeof(struct frame));
  frame_list_init_head(head_of_lru);
  frame_list_insert(tail_of_lru, head_of_lru, tail_of_lru);
}

/* Cleanup any data structures created in lru_init(). */
void
lru_cleanup(void)
{
  free(head_of_lru);
  free(tail_of_lru);
}