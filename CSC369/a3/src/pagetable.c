/*
 * This code is provided solely for the personal and private use of students
 * taking the CSC369H course at the University of Toronto. Copying for purposes
 * other than this use is expressly prohibited. All forms of distribution of
 * this code, including but not limited to public repositories on GitHub,
 * GitLab, Bitbucket, or any other online platform, whether as given or with
 * any changes, are expressly prohibited.
 *
 * Authors: Andrew Peterson, Karen Reid, Alexey Khrabrov
 *
 * All of the files in this directory and all subdirectories are:
 * Copyright (c) 2019, 2021 Karen Reid
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pagetable.h"
#include "pagetable_generic.h"
#include "sim.h"
#include "swap.h"

pdpt_entry_t pdpt_dic[PTRS_PER_PDPT];

// Counters for various events.
// Your code must increment these when the related events occur.
size_t hit_count = 0;
size_t miss_count = 0;
size_t ref_count = 0;
size_t evict_clean_count = 0;
size_t evict_dirty_count = 0;

/*
 * Allocates a frame to be used for the virtual page represented by p.
 * If all frames are in use, calls the replacement algorithm's evict_func to
 * select a victim frame. Writes victim to swap if needed, and updates
 * page table entry for victim to indicate that virtual page is no longer in
 * (simulated) physical memory.
 *
 * Counters for evictions should be updated appropriately in this function.
 */
static int
allocate_frame(pt_entry_t* pte)
{
  int frame = -1;
  // printf("memsize: %ld\n", memsize);
  for (size_t i = 0; i < memsize; ++i) {
    if (!coremap[i].in_use) {
      frame = i;
      break;
    }
  }

  if (frame == -1) { // Didn't find a free page.
    // Call replacement algorithm's evict function to select victim
    frame = evict_func();
    assert(frame != -1);

    // All frames were in use, so victim frame must hold some page
    // Write victim page to swap, if needed, and update page table

    // Get the page table entry for the victim page
    pt_entry_t* pte = coremap[frame].pte;

    // Write victim page to swap, if needed, and update page table entry
    if (pte->frame & PAGE_DIRTY) {
      evict_dirty_count++;
      int swap_offset = swap_pageout(frame, pte->swap_offset);

      if (swap_offset == -1) {
        perror("Error swapping out page");
        exit(1);
      }

      pte->swap_offset = swap_offset;
    } else {
      evict_clean_count++;
    }

    // Update page table entry for victim to indicate that it is no longer in physical memory
    pte->frame = (pte->frame | PAGE_ONSWAP);
    pte->frame = (pte->frame & ~PAGE_VALID);
    pte->frame = (pte->frame & ~PAGE_DIRTY);
  }

  // Record information for virtual page that will now be stored in frame
  coremap[frame].in_use = true;
  coremap[frame].pte = pte;
  // printf("frame in coremap: %d\n", frame);
  return frame;
}

/*
 * Initializes your page table.
 * This function is called once at the start of the simulation.
 * For the simulation, there is a single "process" whose reference trace is
 * being simulated, so there is just one overall page table.
 *
 * In a real OS, each process would have its own page table, which would
 * need to be allocated and initialized as part of process creation.
 *
 * The format of the page table, and thus what you need to do to get ready
 * to start translating virtual addresses, is up to you.
 */
void
init_pagetable(void)
{
  int i;
  for(i=0; i < PTRS_PER_PDPT; i++){
    pdpt_dic[i].pdp = 0;
  }
}

/*
 * Initializes the content of a (simulated) physical memory frame when it
 * is first allocated for some virtual address. Just like in a real OS, we
 * fill the frame with zeros to prevent leaking information across pages.
 */
static void
init_frame(int frame)
{
  // Calculate pointer to start of frame in (simulated) physical memory
  unsigned char* mem_ptr = &physmem[frame * SIMPAGESIZE];
  memset(mem_ptr, 0, SIMPAGESIZE); // zero-fill the frame
}

/*
 * Locate the physical frame number for the given vaddr using the page table.
 *
 * If the page table entry is invalid and not on swap, then this is the first
 * reference to the page and a (simulated) physical frame should be allocated
 * and initialized to all zeros (using init_frame).
 *
 * If the page table entry is invalid and on swap, then a (simulated) physical
 * frame should be allocated and filled by reading the page data from swap.
 *
 * When you have a valid page table entry, return the start of the page frame
 * that holds the requested virtual page.
 *
 * Counters for hit, miss and reference events should be incremented in
 * this function.
 */
unsigned char*
find_physpage(vaddr_t vaddr, char type)
{
  int frame = -1; // Frame used to hold vaddr
  // printf("translate starts\n");
  // IMPLEMENTATION NEEDED

  // Use your page table to find the page table entry (pte) for the
  // requested vaddr.
  int i, j;
  pd_entry_t* pd_table = (pd_entry_t*)(pdpt_dic[PDPT_INDEX(vaddr)].pdp);  
  if (!pd_table){  
    if (posix_memalign((void **)&pd_table, PAGE_SIZE, 
			   PTRS_PER_PD*sizeof(pd_entry_t)) != 0) {
      perror("Failed to allocate aligned memory for page directory table");
      exit(1);
    } 
    for (i=0; i < PTRS_PER_PD; i++){  
      pd_table[i].pde = 0;  
    }
  }
  pdpt_dic[PDPT_INDEX(vaddr)].pdp = (uintptr_t)pd_table;  
  pt_entry_t* pte_table = (pt_entry_t*)(pd_table[PD_INDEX(vaddr)].pde);  
  if (!pte_table) {  
    if (posix_memalign((void **)&pte_table, PAGE_SIZE, 
			   PTRS_PER_PT*sizeof(pt_entry_t)) != 0) {
      perror("Failed to allocate aligned memory for page table entry");
      exit(1);
    }
    for (j = 0; j < PTRS_PER_PT; j++) {   
      pte_table[j].swap_offset = INVALID_SWAP; 
    } 
  }  
  pd_table[PD_INDEX(vaddr)].pde = (uintptr_t)pte_table;
  pt_entry_t *pte = &(pte_table[PT_INDEX(vaddr)]);  

  // Check if pte is valid or not, on swap or not, and handle appropriately.
  // You can use the allocate_frame() and init_frame() functions here,
  // as needed.

  int flag_1 = 0;
	int flag_2 = 0;

  if((pte->frame & PAGE_VALID)&& ((pte->frame & PAGE_ONSWAP) == 0)){
    hit_count++;
  }
  else if ((pte->frame & PAGE_VALID) && (pte->frame & PAGE_ONSWAP)) {
		hit_count++;
	}
  else if((pte->frame & PAGE_VALID) == 0 && (pte->frame & PAGE_ONSWAP)){
      frame = allocate_frame(pte);
      int swap_in_page = swap_pagein(frame, pte->swap_offset);
      if (swap_in_page != 0) {
        perror("Swap page in Error.\n");
        exit(1);
      }
      pte->frame = frame << PAGE_SHIFT;
      pte->frame = pte->frame | PAGE_ONSWAP;
      pte->frame = pte->frame & (~PAGE_DIRTY);
      miss_count++;
      flag_1 = 1;
    }
  else {
    if ((pte->frame & PAGE_REF) == 0) {
			pte->frame = pte->frame | PAGE_DIRTY;
			flag_2 = 1;
		}
    frame = allocate_frame(pte);
    init_frame(frame);
    
    pte->frame = frame << PAGE_SHIFT;
    pte->frame = pte->frame | PAGE_ONSWAP;
    if (flag_2 == 1) {
			pte->frame = pte->frame | PAGE_DIRTY;
		}
    miss_count++;
  }
  
  // Make sure that pte is marked valid and referenced. Also mark it
  // dirty if the access type indicates that the page will be written to.
  // (Note that a page should be marked DIRTY when it is first accessed,
  // even if the type of first access is a read (Load or Instruction type).
  if (flag_1 == 1) {
    if (type == 'M' || type == 'S') {
      pte->frame = pte->frame | PAGE_DIRTY;
    }
  }
	
	pte->frame = pte->frame | PAGE_VALID;
	pte->frame = pte->frame | PAGE_REF;
	
	ref_count ++;

  // Call replacement algorithm's ref_func for this page.
  frame = pte->frame >> PAGE_SHIFT;
  assert(frame != -1);
  ref_func(frame);
  // Return pointer into (simulated) physical memory at start of frame
  return &physmem[frame * SIMPAGESIZE];
}


void
print_pagetable(void)
{
  int i, j, k;
  for(i = 0; i < PTRS_PER_PDPT; i++){
    pd_entry_t *page_directory_table = (pd_entry_t*)(pdpt_dic[i].pdp);
    if(page_directory_table){
      for(j = 0; j < PTRS_PER_PD; j++){
      pd_entry_t *pd = pd = &page_directory_table[j];
      if(pd){
          pt_entry_t *page_table = (pt_entry_t*)(pd->pde);
          for(k = 0; k <PTRS_PER_PT; k++){
            pt_entry_t *pte = &page_table[k];
            if(pte){
              printf("page frame number: %d\n", pte->frame);
              printf("page offset: %ld\n", pte->swap_offset);
            }
          }
        }
      }
    }
  }
}

void  
free_pagetable(void)  
{  
  for (int i = 0; i < PTRS_PER_PDPT; i++) {  
    if (pdpt_dic[i].pdp) {  
      pd_entry_t *page_directory = (pd_entry_t *)(pdpt_dic[i].pdp);  
      if (page_directory) {  
      for (int j = 0; j < PTRS_PER_PD; j++) {   
        pt_entry_t *pt = (pt_entry_t *)(page_directory[j].pde);  
        if(pt){
          free(pt); 
        } 
      }  
    }
    free(page_directory);  
    }
  }  
}  