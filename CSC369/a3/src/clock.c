#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pagetable.h"
#include "pagetable_generic.h"

/* Page to evict is chosen using the CLOCK algorithm.
 * Returns the page frame number (which is also the index in the coremap)
 * for the page that is to be evicted.
 */
extern int memsize;

extern int debug;

extern struct frame *coremap;

int pt;

int
clock_evict(void)
{
  int selected;

  while (1) {
    // If the page has not been recently referenced
    if ((coremap[pt].pte->frame & PAGE_REF) == 0) {
      selected = pt;
      break;
    }
    // If the page has been recently referenced
    coremap[pt].pte->frame &= ~PAGE_REF; // Reset the reference bit

    // Move on to the next page
    pt = (pt + 1) % memsize;
  }

  // Move the pt to the next page
  pt = (pt + 1) % memsize;

  return selected;
}

/* This function is called on each access to a page to update any information
 * needed by the CLOCK algorithm.
 * Input: The page table entry for the page that is being accessed.
 */
void
clock_ref(int frame)
{
  frame = frame | PAGE_REF;
}

/* Initialize any data structures needed for this replacement algorithm. */
void
clock_init(void)
{
  pt = 0;
}

/* Cleanup any data structures created in clock_init(). */
void
clock_cleanup(void)
{}
