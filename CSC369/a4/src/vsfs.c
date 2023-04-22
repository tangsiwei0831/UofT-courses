/*
 * This code is provided solely for the personal and private use of students
 * taking the CSC369H course at the University of Toronto. Copying for purposes
 * other than this use is expressly prohibited. All forms of distribution of
 * this code, including but not limited to public repositories on GitHub,
 * GitLab, Bitbucket, or any other online platform, whether as given or with
 * any changes, are expressly prohibited.
 *
 * Authors: Alexey Khrabrov, Karen Reid, Angela Demke Brown
 *
 * All of the files in this directory and all subdirectories are:
 * Copyright (c) 2022 Angela Demke Brown
 */

/**
 * CSC369 Assignment 4 - vsfs driver implementation.
 */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

// Using 2.9.x FUSE API
#define FUSE_USE_VERSION 29
#include <fuse.h>

#include "bitmap.h"
#include "fs_ctx.h"
#include "map.h"
#include "options.h"
#include "util.h"
#include "vsfs.h"

// NOTE: All path arguments are absolute paths within the vsfs file system and
// start with a '/' that corresponds to the vsfs root directory.
//
// For example, if vsfs is mounted at "/tmp/my_userid", the path to a
// file at "/tmp/my_userid/dir/file" (as seen by the OS) will be
// passed to FUSE callbacks as "/dir/file".
//
// Paths to directories (except for the root directory - "/") do not end in a
// trailing '/'. For example, "/tmp/my_userid/dir/" will be passed to
// FUSE callbacks as "/dir".

/**
 * Initialize the file system.
 *
 * Called when the file system is mounted. NOTE: we are not using the FUSE
 * init() callback since it doesn't support returning errors. This function must
 * be called explicitly before fuse_main().
 *
 * @param fs    file system context to initialize.
 * @param opts  command line options.
 * @return      true on success; false on failure.
 */
static bool
vsfs_init(fs_ctx* fs, vsfs_opts* opts)
{
  size_t size;
  void* image;

  // Nothing to initialize if only printing help
  if (opts->help) {
    return true;
  }

  // Map the disk image file into memory
  image = map_file(opts->img_path, VSFS_BLOCK_SIZE, &size);
  if (image == NULL) {
    return false;
  }

  return fs_ctx_init(fs, image, size);
}

/**
 * Cleanup the file system.
 *
 * Called when the file system is unmounted. Must cleanup all the resources
 * created in vsfs_init().
 */
static void
vsfs_destroy(void* ctx)
{
  fs_ctx* fs = (fs_ctx*)ctx;
  if (fs->image) {
    munmap(fs->image, fs->size);
    fs_ctx_destroy(fs);
  }
}

/** Get file system context. */
static fs_ctx*
get_fs(void)
{
  return (fs_ctx*)fuse_get_context()->private_data;
}

int find_entry(uint32_t inode_num, char *target_name, fs_ctx *fs){
  uint32_t dentry_per_block = VSFS_BLOCK_SIZE / sizeof(vsfs_dentry);
	vsfs_inode inode = fs->itable[inode_num];
  vsfs_blk_t block_dir;
  vsfs_dentry* root_entries = NULL;
  for(uint32_t i = 0; i < inode.i_blocks; i++) {
    if(i < VSFS_NUM_DIRECT){
      // use direct
      block_dir = inode.i_direct[i];
      for(uint32_t k = 0; k < dentry_per_block; k++){
        root_entries = (vsfs_dentry*)(fs->image + block_dir * VSFS_BLOCK_SIZE + k * sizeof(vsfs_dentry));
        if(root_entries!=NULL && root_entries->ino != VSFS_INO_MAX && (strcmp(root_entries->name,target_name)==0)){
          return root_entries->ino;
        }
      }
    }
    else{
      // use indirect
      vsfs_blk_t *indir_block = (vsfs_blk_t*)(fs->image + inode.i_indirect * VSFS_BLOCK_SIZE);
      vsfs_blk_t block_num = indir_block[i-VSFS_NUM_DIRECT];
      for(uint32_t k = 0; k < dentry_per_block; k++){
        root_entries = (vsfs_dentry*)(fs->image + block_num * VSFS_BLOCK_SIZE + k * sizeof(vsfs_dentry));
        if(root_entries!=NULL && root_entries->ino != VSFS_INO_MAX && (strcmp(root_entries->name,target_name)==0)){
          return root_entries->ino;
        }
      }
    }
  }
  return -ENOENT;
}

/* Returns the inode number for the element at the end of the path
 * if it exists.  If there is any error, return -1.
 * Possible errors include:
 *   - The path is not an absolute path
 *   - An element on the path cannot be found
 */
static int
path_lookup(const char* path, vsfs_ino_t* ino)
{
  if (strlen(path) >= VSFS_PATH_MAX){
    return -ENAMETOOLONG;
  } 
	if(path[0] != '/') {
		return -ENOTDIR; // there is not refernce to the root node in the path
  }

	char *path_copy = calloc(strlen(path), sizeof(char));
  strcpy(path_copy, &path[1]); // we do not include the root dir in our path as we know it exists
	char *stringp = strsep(&path_copy, "/");
	long curr_node = 0; // root node

  fs_ctx* fs = get_fs();

	while(path_copy != NULL){
		if(strlen(stringp) >= VSFS_NAME_MAX){
      return -ENAMETOOLONG; 
    }

		curr_node = find_entry(curr_node, stringp, fs);
		if (curr_node < 0){
				return curr_node; // error
		}
		stringp = strsep(&path_copy, "/");
	}

	// now we are in on the last element of the path
	free(path_copy);
  if(strlen(stringp) >= VSFS_NAME_MAX){
    return -ENAMETOOLONG;
  } 
	if(strcmp(stringp, "") != 0){
		curr_node = find_entry(curr_node, stringp, fs);	// the path is not the root node
	}
  *ino = curr_node;
	return curr_node; // could be an error message or a valid inode number
}

vsfs_blk_t get_final_block(vsfs_inode * file_inode, fs_ctx *fs){
	vsfs_blk_t final_block;
	if (file_inode->i_blocks < VSFS_NUM_DIRECT){
		final_block = file_inode->i_direct[file_inode->i_blocks - 1];
	}
	else{
    final_block = ((vsfs_blk_t *) (fs->image + file_inode->i_indirect * VSFS_BLOCK_SIZE))[file_inode->i_blocks - VSFS_NUM_DIRECT];
  }
	return final_block;
}

void set_parent_path(char *path){
	char *ptr = strrchr(path, '/');
	char *ptr2 = strchr(path, '/');

	if(ptr == ptr2){
    ptr[1] = '\0';
  }else{
    ptr[0] = '\0';
  }
}

char* get_last_part(const char *abs_path){
	char *ptr = strrchr(abs_path, '/');
	return &ptr[1]; // don't have to error check since we are assured that the path is valid
}

int delete_block(vsfs_inode *inode, fs_ctx *fs){
	vsfs_blk_t final_block = get_final_block(inode, fs);

  bitmap_set(fs->dbmap, fs->sb->num_blocks, final_block, false);

  final_block = 0;
	if (inode->i_blocks <= VSFS_NUM_DIRECT){
    inode->i_direct[inode->i_blocks - 1] = final_block; 
  }else{
    memcpy(fs->image + inode->i_indirect * VSFS_BLOCK_SIZE + (inode->i_blocks - VSFS_NUM_DIRECT ) * sizeof(vsfs_blk_t), &final_block, sizeof(vsfs_blk_t));
  }

  inode->i_blocks --;
  fs->sb->free_blocks++;

	return 1;
}

int create_inode(const char *path, mode_t mode, fs_ctx *fs){
	vsfs_inode *inode = calloc(1, sizeof(vsfs_inode));
	if(inode == NULL){
    return -ENOMEM;
  }
	inode->i_mode = mode;
	inode->i_nlink = 1; 
	inode->i_size = 0;
	clock_gettime(CLOCK_REALTIME, &inode->i_mtime);

  uint32_t index;
  int res = bitmap_alloc(fs->ibmap, fs->sb->num_inodes, &index);
	if(res < 0){
		free(inode);
		return -ENOSPC; 
	}	
  bitmap_set(fs->ibmap, fs->sb->num_inodes, (uint32_t)index, true);
  fs->itable[index] = *inode;

	char parent_path[strlen(path)];
	strcpy(parent_path, path);
	set_parent_path(parent_path);
  char *file = get_last_part(path);
  
  vsfs_ino_t parent_ino;
  path_lookup(parent_path, &parent_ino);

  vsfs_inode parent_inode = fs->itable[parent_ino];
  vsfs_blk_t block_num;
  for (uint32_t i = 0; i < parent_inode.i_blocks; i++){
    if (i < VSFS_NUM_DIRECT){
      block_num = parent_inode.i_direct[i];
    }
    else{
      vsfs_blk_t* indir = (vsfs_blk_t*)(fs->image + parent_inode.i_indirect * VSFS_BLOCK_SIZE);
      block_num = indir[i-VSFS_NUM_DIRECT];
    }
    for (uint32_t j = 0; j < VSFS_BLOCK_SIZE / sizeof(vsfs_dentry); j++){
      vsfs_dentry* dentry = (vsfs_dentry*)(fs->image + block_num * VSFS_BLOCK_SIZE + j * sizeof(vsfs_dentry));
      if (dentry->ino == VSFS_INO_MAX){
        dentry->ino = index;
        strcpy(dentry->name, file);
        parent_inode.i_nlink ++;
        fs->sb->free_inodes --;
        break;
      }
    }
  }

	return 0;
}

/**
 * Get file system statistics.
 *
 * Implements the statvfs() system call. See "man 2 statvfs" for details.
 * The f_bfree and f_bavail fields should be set to the same value.
 * The f_ffree and f_favail fields should be set to the same value.
 * The following fields can be ignored: f_fsid, f_flag.
 * All remaining fields are required.
 *
 * Errors: none
 *
 * @param path  path to any file in the file system. Can be ignored.
 * @param st    pointer to the struct statvfs that receives the result.
 * @return      0 on success; -errno on error.
 */
static int
vsfs_statfs(const char* path, struct statvfs* st)
{
  (void)path; // unused
  fs_ctx* fs = get_fs();
  vsfs_superblock* sb = fs->sb; /* Get ptr to superblock from context */

  memset(st, 0, sizeof(*st));
  st->f_bsize = VSFS_BLOCK_SIZE;  /* Filesystem block size */
  st->f_frsize = VSFS_BLOCK_SIZE; /* Fragment size */
  // The rest of required fields are filled based on the information
  // stored in the superblock.
  st->f_blocks = sb->num_blocks;  /* Size of fs in f_frsize units */
  st->f_bfree = sb->free_blocks;  /* Number of free blocks */
  st->f_bavail = sb->free_blocks; /* Free blocks for unpriv users */
  st->f_files = sb->num_inodes;   /* Number of inodes */
  st->f_ffree = sb->free_inodes;  /* Number of free inodes */
  st->f_favail = sb->free_inodes; /* Free inodes for unpriv users */

  st->f_namemax = VSFS_NAME_MAX; /* Maximum filename length */

  return 0;
}

/**
 * Get file or directory attributes.
 *
 * Implements the lstat() system call. See "man 2 lstat" for details.
 * The following fields can be ignored: st_dev, st_ino, st_uid, st_gid, st_rdev,
 *                                      st_blksize, st_atime, st_ctime.
 * All remaining fields are required.
 *
 * NOTE: the st_blocks field is measured in 512-byte units (disk sectors);
 *       it should include any metadata blocks that are allocated to the
 *       inode (for vsfs, that is the indirect block).
 *
 * NOTE2: the st_mode field must be set correctly for files and directories.
 *
 * Errors:
 *   ENAMETOOLONG  the path or one of its components is too long.
 *   ENOENT        a component of the path does not exist.
 *   ENOTDIR       a component of the path prefix is not a directory.
 *
 * @param path  path to a file or directory.
 * @param st    pointer to the struct stat that receives the result.
 * @return      0 on success; -errno on error;
 */
static int
vsfs_getattr(const char* path, struct stat* st)
{
  if (strlen(path) >= VSFS_PATH_MAX)
    return -ENAMETOOLONG;
  fs_ctx* fs = get_fs();

  memset(st, 0, sizeof(*st));

  // TODO: lookup the inode for given path and, if it exists, fill in the
  // required fields based on the information stored in the inode
  vsfs_ino_t ino;
  int ret = path_lookup(path,&ino);
  if(ret < 0){
    fprintf(stderr,"No such file or directory\n");
    return -ENOENT; 
  }
  vsfs_inode i_inode = fs->itable[ino];
  st->st_mode = i_inode.i_mode;
  st->st_nlink = i_inode.i_nlink;
  st->st_size = i_inode.i_size;
  if(i_inode.i_blocks > VSFS_NUM_DIRECT){
    st->st_blocks = (i_inode.i_blocks + 1) * VSFS_BLOCK_SIZE / 512;
  }else{
    st->st_blocks = i_inode.i_blocks * VSFS_BLOCK_SIZE / 512;
  }
  st->st_mtime = i_inode.i_mtime.tv_nsec;

  return 0;
}

/**
 * Read a directory.
 *
 * Implements the readdir() system call. Should call filler(buf, name, NULL, 0)
 * for each directory entry. See fuse.h in libfuse source code for details.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists and is a directory.
 *
 * Errors:
 *   ENOMEM  not enough memory (e.g. a filler() call failed).
 *
 * @param path    path to the directory.
 * @param buf     buffer that receives the result.
 * @param filler  function that needs to be called for each directory entry.
 *                Pass 0 as offset (4th argument). 3rd argument can be NULL.
 * @param offset  unused.
 * @param fi      unused.
 * @return        0 on success; -errno on error.
 */
static int
vsfs_readdir(const char* path,
             void* buf,
             fuse_fill_dir_t filler,
             off_t offset,
             struct fuse_file_info* fi)
{
  (void)offset; // unused
  (void)fi;     // unused
  fs_ctx* fs = get_fs();

  // TODO: lookup the directory inode for given path and iterate through its
  // directory entries
  vsfs_ino_t ino;
  int re = path_lookup(path,&ino);
  if(re < 0){
    return -1;
  }

  vsfs_inode inode = fs->itable[ino];

  uint32_t dentry_per_block = VSFS_BLOCK_SIZE / sizeof(vsfs_dentry);
  vsfs_dentry* dentries;

  for(uint32_t i = 0; i <inode.i_blocks; i++){
    if(i < VSFS_NUM_DIRECT){
      vsfs_blk_t i_block = inode.i_direct[i];
      for(uint32_t k =0; k < dentry_per_block; k++){
        dentries = (vsfs_dentry*)(fs->image + i_block*VSFS_BLOCK_SIZE + k*sizeof(vsfs_dentry));
        if(dentries->ino != VSFS_INO_MAX){
          if(filler(buf, dentries->name, NULL, 0)==1){
            return -ENOMEM;
          }
        }
      }
    }else{
      // indirect
      vsfs_blk_t block_num = ((vsfs_blk_t*)(fs->image + inode.i_indirect * VSFS_BLOCK_SIZE))[i-VSFS_NUM_DIRECT];;
      for(uint32_t k = 0; k < dentry_per_block; k++){
        dentries = (vsfs_dentry*)(fs->image + block_num * VSFS_BLOCK_SIZE + k * sizeof(vsfs_dentry));
        if(dentries->ino != VSFS_INO_MAX){
          if(filler(buf, dentries->name, NULL, 0)==1){
            return -ENOMEM;
          }
        }
      }
    }
  }

  return 0;
}

/**
 * Create a directory.
 *
 * Implements the mkdir() system call.
 *
 * You do NOT need to implement this function.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" doesn't exist.
 *   The parent directory of "path" exists and is a directory.
 *   "path" and its components are not too long.
 *
 * Errors:
 *   ENOMEM  not enough memory (e.g. a malloc() call failed).
 *   ENOSPC  not enough free space in the file system.
 *
 * @param path  path to the directory to create.
 * @param mode  file mode bits.
 * @return      0 on success; -errno on error.
 */
static int
vsfs_mkdir(const char* path, mode_t mode)
{
  mode = mode | S_IFDIR;
  fs_ctx* fs = get_fs();

  // OMIT: create a directory at given path with given mode
  (void)path;
  (void)mode;
  (void)fs;
  return -ENOSYS;
}

/**
 * Remove a directory.
 *
 * Implements the rmdir() system call.
 *
 * You do NOT need to implement this function.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists and is a directory.
 *
 * Errors:
 *   ENOTEMPTY  the directory is not empty.
 *
 * @param path  path to the directory to remove.
 * @return      0 on success; -errno on error.
 */
static int
vsfs_rmdir(const char* path)
{
  fs_ctx* fs = get_fs();

  // OMIT: remove the directory at given path (only if it's empty)
  (void)path;
  (void)fs;
  return -ENOSYS;
}

/**
 * Create a file.
 *
 * Implements the open()/creat() system call.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" doesn't exist.
 *   The parent directory of "path" exists and is a directory.
 *   "path" and its components are not too long.
 *
 * Errors:
 *   ENOMEM  not enough memory (e.g. a malloc() call failed).
 *   ENOSPC  not enough free space in the file system.
 *
 * @param path  path to the file to create.
 * @param mode  file mode bits.
 * @param fi    unused.
 * @return      0 on success; -errno on error.
 */
static int
vsfs_create(const char* path, mode_t mode, struct fuse_file_info* fi)
{
  (void)fi; // unused
  assert(S_ISREG(mode));
  fs_ctx* fs = get_fs();

  // TODO: create a file at given path with given mode
  return create_inode(path, mode, fs);
}

/**
 * Remove a file.
 *
 * Implements the unlink() system call.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists and is a file.
 *
 * Errors: none
 *
 * @param path  path to the file to remove.
 * @return      0 on success; -errno on error.
 */
static int
vsfs_unlink(const char* path)
{
  fs_ctx* fs = get_fs();

  // TODO: remove the file at given path
  char upper_path[strlen(path)];
	strcpy(upper_path, path);
	set_parent_path(upper_path);

  vsfs_ino_t upper_ino;
  path_lookup(upper_path, &upper_ino);
  vsfs_inode upper_inode = fs->itable[upper_ino];

  vsfs_blk_t block_num;

  vsfs_ino_t inode_num;
  path_lookup(path, &inode_num);
  vsfs_inode inode = fs->itable[inode_num];

  upper_inode.i_nlink --;
  fs->sb->free_inodes ++;

  for (uint32_t k = 0; k < inode.i_blocks; k++){
    if(k < VSFS_NUM_DIRECT){
      bitmap_free(fs->dbmap, fs->sb->num_blocks, inode.i_direct[k]);
    }else{
      vsfs_blk_t *indir = (vsfs_blk_t*)(fs->image + inode.i_indirect * VSFS_BLOCK_SIZE);
      block_num = indir[k - VSFS_NUM_DIRECT];
      bitmap_free(fs->dbmap, fs->sb->num_blocks, block_num);
    }
  }
  inode.i_blocks = 0;
  bitmap_free(fs->ibmap, fs->sb->num_inodes, inode_num);

  return 0;
}

/**
 * Change the modification time of a file or directory.
 *
 * Implements the utimensat() system call. See "man 2 utimensat" for details.
 *
 * NOTE: You only need to implement the setting of modification time (mtime).
 *       Timestamp modifications are not recursive.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists.
 *
 * Errors: none
 *
 * @param path   path to the file or directory.
 * @param times  timestamps array. See "man 2 utimensat" for details.
 * @return       0 on success; -errno on failure.
 */
static int
vsfs_utimens(const char* path, const struct timespec times[2])
{
  fs_ctx* fs = get_fs();
  vsfs_inode* ino = NULL;

  // TODO: update the modification timestamp (mtime) in the inode for given
  // path with either the time passed as argument or the current time,
  // according to the utimensat man page
  (void)path;
  (void)fs;
  (void)ino;

  // 0. Check if there is actually anything to be done.
  if (times[1].tv_nsec == UTIME_OMIT) {
    // Nothing to do.
    return 0;
  }

  // 1. TODO: Find the inode for the final component in path

  // 2. Update the mtime for that inode.
  //    This code is commented out to avoid failure until you have set
  //    'ino' to point to the inode structure for the inode to update.
  if (times[1].tv_nsec == UTIME_NOW) {
    // if (clock_gettime(CLOCK_REALTIME, &(ino->i_mtime)) != 0) {
    // clock_gettime should not fail, unless you give it a
    // bad pointer to a timespec.
    //	assert(false);
    //}
  } else {
    // ino->i_mtime = times[1];
  }

  // return 0;
  return -ENOSYS;
}

/**
 * Change the size of a file.
 *
 * Implements the truncate() system call. Supports both extending and shrinking.
 * If the file is extended, the new uninitialized range at the end must be
 * filled with zeros.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists and is a file.
 *
 * Errors:
 *   ENOMEM  not enough memory (e.g. a malloc() call failed).
 *   ENOSPC  not enough free space in the file system.
 *   EFBIG   write would exceed the maximum file size.
 *
 * @param path  path to the file to set the size.
 * @param size  new file size in bytes.
 * @return      0 on success; -errno on error.
 */
static int
vsfs_truncate(const char* path, off_t size)
{
  fs_ctx* fs = get_fs();

  // TODO: set new file size, possibly "zeroing out" the uninitialized range
  vsfs_ino_t ino;
  path_lookup(path, &ino);

  vsfs_inode* file_inode = &(fs->itable[ino]);

  if(file_inode->i_size == (uint64_t)size){
    return 0;
  }
  else{
    if(file_inode->i_size > (uint64_t)size){
      //shrink
      uint32_t bytes_in_last_block = file_inode->i_size % VSFS_BLOCK_SIZE;
      uint32_t target_num_removed_blocks = file_inode->i_size < (uint64_t)size + bytes_in_last_block ? 0:(file_inode->i_size - size - bytes_in_last_block) / VSFS_BLOCK_SIZE + 1; // +1 for the last block
      
      if(target_num_removed_blocks > 0){
        while(target_num_removed_blocks > 0){
          target_num_removed_blocks -= delete_block(file_inode, fs);
        }
        if(file_inode->i_blocks <= VSFS_NUM_DIRECT && file_inode->i_indirect != 0){
          bitmap_set(fs->dbmap, fs->sb->num_blocks, file_inode->i_indirect, false);
          file_inode->i_indirect = 0; 
        }
      }

    }else{
      //extend
      uint32_t bytes_in_last_block = file_inode->i_size % VSFS_BLOCK_SIZE == 0 && file_inode->i_size != 0 ? VSFS_BLOCK_SIZE : file_inode->i_size % VSFS_BLOCK_SIZE;
      uint32_t nonallocated_bytes_last_block = file_inode->i_size == 0 ? 0: VSFS_BLOCK_SIZE - bytes_in_last_block;
      uint32_t total_additional_bytes = size - file_inode->i_size;  
      uint32_t additional_blocks = total_additional_bytes <= nonallocated_bytes_last_block ? 0: div_round_up(total_additional_bytes - nonallocated_bytes_last_block, VSFS_BLOCK_SIZE);

      if(additional_blocks > fs->sb->free_blocks){
        return -ENOSPC;
      }

      // need to allocate new data block
      for(uint32_t i=0;i<additional_blocks; i++){
        // second allocate a block
        vsfs_blk_t a_block;
        int ret = bitmap_alloc(fs->dbmap,fs->sb->num_blocks,&a_block);
        if(ret < 0){
          fprintf(stderr,"not enough free space in the file system\n");
          return -ENOSPC;
        }
        unsigned char* p_block=(unsigned char*)fs->image + a_block * VSFS_BLOCK_SIZE;
        memset(p_block,0,VSFS_BLOCK_SIZE);
        file_inode->i_direct[file_inode->i_blocks] = a_block;
        file_inode->i_blocks++;
        bitmap_set(fs->dbmap,fs->sb->num_blocks,a_block,true);
      }

      // set uninitialized range at the current block end
      int i_last_block = get_final_block(file_inode, fs);
      int in_block_offset = file_inode->i_size % VSFS_BLOCK_SIZE;
      unsigned char* last_block = fs->image + (i_last_block * VSFS_BLOCK_SIZE);

      int rest_size = VSFS_BLOCK_SIZE - in_block_offset;

      if(size - file_inode->i_size >= (uint64_t)rest_size){
        // not need to allocate new data block
        memset(last_block+in_block_offset,0,size-file_inode->i_size-rest_size);
      }else if(size - file_inode->i_size <(uint64_t)rest_size){
        memset(last_block+in_block_offset,0,rest_size);
      }
      // update super block
      fs->sb->free_blocks -= additional_blocks;
    }

    file_inode->i_size = size;
    if (clock_gettime(CLOCK_REALTIME, &(file_inode->i_mtime)) != 0) {
      return -ENOSYS;
    }
    memcpy(fs->image + VSFS_ITBL_BLKNUM * VSFS_BLOCK_SIZE + ino * sizeof(vsfs_inode), file_inode, sizeof(vsfs_inode));
    return 0;
  }
  return 0;
}

/**
 * Read data from a file.
 *
 * Implements the pread() system call. Must return exactly the number of bytes
 * requested except on EOF (end of file). Reads from file ranges that have not
 * been written to must return ranges filled with zeros. You can assume that the
 * byte range from offset to offset + size is contained within a single block.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists and is a file.
 *
 * Errors: none
 *
 * @param path    path to the file to read from.
 * @param buf     pointer to the buffer that rece ives the data.
 * @param size    buffer size (number of bytes requested).
 * @param offset  offset from the beginning of the file to read from.
 * @param fi      unused.
 * @return        number of bytes read on success; 0 if offset is beyond EOF;
 *                -errno on error.
 */
static int
vsfs_read(const char* path,
          char* buf,
          size_t size,
          off_t offset,
          struct fuse_file_info* fi)
{
  (void)fi; // unused
  fs_ctx* fs = get_fs();

  // TODO: read data from the file at given offset into the buffer
  vsfs_ino_t index;
  path_lookup(path, &index);
	vsfs_inode *inode = &fs->itable[index];
	uint32_t block_offset = offset / VSFS_BLOCK_SIZE;
	uint32_t byte_offset = offset % VSFS_BLOCK_SIZE;
  vsfs_blk_t *block_num;

  if((uint64_t)offset >inode->i_size){
    perror("offset is beyond EOF");
    memset(buf, 0, size);
    return 0;
  }

	if(inode->i_blocks < VSFS_NUM_DIRECT){
    block_num = &inode->i_direct[block_offset];
  }else{
    block_num = (vsfs_blk_t *) (fs->image + inode->i_indirect * VSFS_BLOCK_SIZE + (block_offset - VSFS_NUM_DIRECT) * sizeof(vsfs_blk_t));
  }
  unsigned char* p_block = fs->image + (*block_num) * VSFS_BLOCK_SIZE + byte_offset;

  if(size < inode->i_size - offset){
    memcpy(buf, p_block, size);
    return size;
  }else{
    memcpy(buf, p_block, inode->i_size - offset);
    memset(buf + inode->i_size - offset, 0, size - (inode->i_size - offset));
    return (inode->i_size - offset);
  }
}

/**
 * Write data to a file.
 *
 * Implements the pwrite() system call. Must return exactly the number of bytes
 * requested except on error. If the offset is beyond EOF (end of file), the
 * file must be extended. If the write creates a "hole" of uninitialized data,
 * the new uninitialized range must filled with zeros. You can assume that the
 * byte range from offset to offset + size is contained within a single block.
 *
 * Assumptions (already verified by FUSE using getattr() calls):
 *   "path" exists and is a file.
 *
 * Errors:
 *   ENOMEM  not enough memory (e.g. a malloc() call failed).
 *   ENOSPC  not enough free space in the file system.
 *   EFBIG   write would exceed the maximum file size
 *
 * @param path    path to the file to write to.
 * @param buf     pointer to the buffer containing the data.
 * @param size    buffer size (number of bytes requested).
 * @param offset  offset from the beginning of the file to write to.
 * @param fi      unused.
 * @return        number of bytes written on success; -errno on error.
 */
static int
vsfs_write(const char* path,
           const char* buf,
           size_t size,
           off_t offset,
           struct fuse_file_info* fi)
{
  (void)fi; // unused
  fs_ctx* fs = get_fs();

  // TODO: write data from the buffer into the file at given offset, possibly
  vsfs_ino_t index;
  path_lookup(path,&index);
  vsfs_inode inode = fs->itable[index];

  if(offset + size > inode.i_size){
			long res = vsfs_truncate(path, offset + size);
			if (res < 0)
				return res; // error. prob a ENOSPC error 
	}

	uint32_t block_offset = offset / VSFS_BLOCK_SIZE;
	uint32_t byte_offset = offset % VSFS_BLOCK_SIZE;
	vsfs_blk_t *curr_extent; 

	// load inode because truncate
  inode = fs->itable[index];
	if(inode.i_blocks < VSFS_NUM_DIRECT){
    curr_extent = &inode.i_direct[block_offset];
  }else{
    curr_extent = (vsfs_blk_t *) (fs->image + inode.i_indirect * VSFS_BLOCK_SIZE + (block_offset - VSFS_NUM_DIRECT) * sizeof(vsfs_blk_t));
  }

  inode.i_size += size;
  memcpy(fs->image +  (*curr_extent) * VSFS_BLOCK_SIZE + byte_offset, buf, size);
	return size;
}

static struct fuse_operations vsfs_ops = {
  .destroy = vsfs_destroy,
  .statfs = vsfs_statfs,
  .getattr = vsfs_getattr,
  .readdir = vsfs_readdir,
  .mkdir = vsfs_mkdir,
  .rmdir = vsfs_rmdir,
  .create = vsfs_create,
  .unlink = vsfs_unlink,
  .utimens = vsfs_utimens,
  .truncate = vsfs_truncate,
  .read = vsfs_read,
  .write = vsfs_write,
};

int
main(int argc, char* argv[])
{
  vsfs_opts opts = { 0 }; // defaults are all 0
  struct fuse_args args = FUSE_ARGS_INIT(argc, argv);
  if (!vsfs_opt_parse(&args, &opts))
    return 1;

  fs_ctx fs = { 0 };
  if (!vsfs_init(&fs, &opts)) {
    fprintf(stderr, "Failed to mount the file system\n");
    return 1;
  }

  return fuse_main(args.argc, args.argv, &vsfs_ops, &fs);
}
