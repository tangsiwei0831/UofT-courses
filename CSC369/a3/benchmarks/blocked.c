/* File:     Blocked matrix multiplication
 * Adapted from: http://www.cs.usfca.edu/~peter/math202/blocked.c
 *
 * Purpose:  Compare the run time of the standard matrix multiplication
 *           algorithm with blocked matrix multiplication.
 *
 * Compile:  gcc -g -Wall [-DDEBUG] -o blocked blocked.c
 * Run:      ./blocked <order of matrices> <order of blocks>
 *              <-> required argument, [-] optional argument
 *
 * Output:   Elapsed time for blocked matrix multiplication.
 *           If the DEBUG flag is set, the factor and the product
 *           matrices are also output.
 *
 * Notes:
 * 1.  The file timer.h should be in the directory containing the source file.
 * 2.  Set the DEBUG flag to see the factor and the product matrices.
 * 3.  Matrices are generated using a random number generator.
 * 4.  There are a number of optimizations that can be made to the source
 *     code that will improve the performance of both algorithms.
 * 5.  Note that unless the DEBUG flag is set the product matrices will,
 *     in general, be different using the two algorithms, since the two
 *     algorithms use identical storage for A and B, but they assume
 *     the storage has different structures.
 * 6.  The order of the blocks (b) must evenly divide the order
 *     of the matrices (n).
 * 7.  If the matrix order is n and the block size is b, define
 *
 *        n_bar = n/b = number of block rows = number of block cols
 *        b_sqr = b*b = size of the blocks
 *
 *     If we're in block row i_bar, block column j_bar, then the
 *     address of the first entry in matrix X will be
 *
 *        X + (i_bar*n_bar + j_bar)*b_sqr
 *
 *     The remainder of the b x b block is stored in the next b^2
 *     memory locations.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h> // for memset

#include "marker.h"
#include "timer.h"

#define PAD 120

struct record
{
  double value;
  char padding[PAD];
};

// Global Variables
const double DRAND_MAX = RAND_MAX;
struct record *A, *B, *C;
struct record* C_p;
int n, b;
int n_bar, b_sqr;

void
Usage(const char* prog_name);
void
Get_matrices(struct record A[], struct record B[], int n);
void
Blocked_mat_mult(void);
void
Zero_C(int i_bar, int j_bar);
void
Mult_add(int i_bar, int j_bar, int k_bar);
void
Print_matrix(struct record M[], int n, const char* name);
void
To_blocked(struct record A[], int n, int b);
void
From_blocked(struct record C[], int n, int b);

/*-------------------------------------------------------------------*/
int
main(int argc, char* argv[])
{
  write_marker_file("blocked.marker");
  MARKER_START();

  if (argc < 3 || argc > 4) {
    Usage(argv[0]);
  }
  n = strtol(argv[1], NULL, 10);
  b = strtol(argv[2], NULL, 10);
  if (n % b != 0) {
    Usage(argv[0]);
  }

  A = malloc(n * n * sizeof(struct record));
  B = malloc(n * n * sizeof(struct record));
  C = malloc(n * n * sizeof(struct record));
  if (A == NULL || B == NULL || C == NULL) {
    perror("malloc");
    exit(1);
  }

  n_bar = n / b;
  b_sqr = b * b;
  Get_matrices(A, B, n);

#ifdef DEBUG
  Print_matrix(A, n, "A");
  Print_matrix(B, n, "B");
  To_blocked(A, n, b);
  To_blocked(B, n, b);
#endif

  double start = get_time();
  Blocked_mat_mult();
  double finish = get_time();

#ifdef DEBUG
  From_blocked(C, n, b);
  Print_matrix(C, n, "C");
#endif

  printf("Elapsed time for blocked algorithm = %e seconds\n", finish - start);

  free(A);
  free(B);
  free(C);

  MARKER_END();
  return 0;
}

/*-------------------------------------------------------------------
 * Function:  Usage
 * Purpose:   Print a message showing how the program is used and quit
 * In arg:    prog_name:  the program name
 */
void
Usage(const char* prog_name)
{
  fprintf(
    stderr, "usage:  %s <order of matrices> <order of blocks>\n", prog_name);
  fprintf(stderr, "   order of blocks must evenly divide order of matrices\n");
  exit(1);
}

/*-------------------------------------------------------------------
 * Function:  Get_matrices
 * Purpose:   Generate the factor matrices
 * In args:   n:     order of the matrices
 * Out args:  A, B:  the matrices
 */
void
Get_matrices(struct record A[], struct record B[], int n)
{
  int i;

  for (i = 0; i < n * n; i++) {
    A[i].value = random() / DRAND_MAX;
    B[i].value = random() / DRAND_MAX;
  }
}

/*-------------------------------------------------------------------
 * Function:     Zero_C
 * Purpose:      Assign 0 to the current block of C and set the global
 *               pointer C_p to refer to this block
 * In args:      i_bar:  current block row
 *               j_bar:  current block col
 * Globals in:   n_bar:  the number of blocks
 *               b_sqr:  square of the blocksize
 * Globals out:  C_p:    pointer to the start of the current block of C
 */
void
Zero_C(int i_bar, int j_bar)
{
  C_p = C + (i_bar * n_bar + j_bar) * b_sqr;
  memset(C_p, 0, b_sqr * sizeof(struct record));
}

/*-------------------------------------------------------------------
 * Function:      Mult_add
 * Purpose:       Add the product of the current blocks of A and B
 *                into C
 * In args:       i_bar:  current block row in C and A
 *                j_bar:  current block col in C and B
 *                k_bar:  current block col in A, block row in B
 * Globals in:    C_p:    pointer to start of current block of C
 *                A:      the factor matrix A
 *                B:      the factor matrix B
 *                n_bar:  the number of blocks = n/b
 *                b:      the blocksize
 *                b_sqr:  b*b
 * Global in/out: C:      the product matrix
 */
void
Mult_add(int i_bar, int j_bar, int k_bar)
{
  struct record* c_p = C_p;
  struct record* a_p = A + (i_bar * n_bar + k_bar) * b_sqr;
  struct record* b_p = B + (k_bar * n_bar + j_bar) * b_sqr;
  int i, j, k;

  for (i = 0; i < b; i++) {
    for (j = 0; j < b; j++) {
      for (k = 0; k < b; k++) {
        (c_p + i * b + j)->value +=
          (a_p + i * b + k)->value * (b_p + k * b + j)->value;
      }
    }
  }
}

/*-------------------------------------------------------------------
 * Function:      Blocked_mat_mult
 * Purpose:       Implement blocked matrix-matrix multiplication
 * Globals in:    n_bar:   the number blocks = n/b
 *                A, B:    the factor matrices (used in Mat_mult)
 * Globals out:   C, C_p:  the product matrix, and pointer to current
 *                         block in product matrix
 */
void
Blocked_mat_mult(void)
{
  int i_bar, j_bar, k_bar; // index block rows and columns

  for (i_bar = 0; i_bar < n_bar; i_bar++) {
    for (j_bar = 0; j_bar < n_bar; j_bar++) {
      Zero_C(i_bar, j_bar);
      for (k_bar = 0; k_bar < n_bar; k_bar++) {
        Mult_add(i_bar, j_bar, k_bar);
      }
    }
  }
}

/*-------------------------------------------------------------------
 * Function:  Print_matrix
 * Purpose:   Print a matrix on stdout
 * In args:   M:     the matrix
 *            n:     order of matrix
 *            name:  name of the matrix
 */
void
Print_matrix(struct record M[], int n, const char* name)
{
  printf("Matrix %s:\n", name);

  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      printf("%.2e ", M[i * n + j].value);
    }
    printf("\n");
  }
  printf("\n");
}

/*-------------------------------------------------------------------
 * Function:    To_blocked
 * Purpose:     Convert the matrix A from row-major to blocked storage
 * In args:     n:  order of matrix
 *              b:  blocksize
 * In/out arg:  A:  on input matrix stored in row-major format, on
 *                  output matrix stored in blocked format
 */
void
To_blocked(struct record A[], int n, int b)
{
  int i, j;
  int i_bar, j_bar; // index block rows and block cols
  int n_bar = n / b;
  struct record *T, *a_p, *t_p;

  T = malloc(n * n * sizeof(struct record));
  if (T == NULL) {
    fprintf(stderr, "Can't allocate temporary in To_blocked\n");
    exit(1);
  }

  // for each block in A
  t_p = T;
  for (i_bar = 0; i_bar < n_bar; i_bar++) {
    for (j_bar = 0; j_bar < n_bar; j_bar++) {

      // Copy block into contiguous locations in T
      a_p = A + (i_bar * b * n + j_bar * b);
      for (i = 0; i < b; i++, a_p += (n - b)) {
        for (j = 0; j < b; j++) {
          t_p->value = a_p->value;
          t_p++;
          a_p++;
        }
      }
    }
  }

  memcpy(A, T, n * n * sizeof(struct record));
  free(T);
}

/*-------------------------------------------------------------------
 * Function:    From_blocked
 * Purpose:     Convert the matrix C from blocked storage to row-major storage
 * In args:     n:  order of matrix
 *              b:  blocksize
 * In/out arg:  C:  on input matrix stored in blocked format,
 *                  on output matrix stored in row-major format
 */
void
From_blocked(struct record C[], int n, int b)
{
  int i, j;
  int i_bar, j_bar; // index blocks of C
  int n_bar = n / b;
  struct record *T, *c_p, *t_p;

  T = malloc(n * n * sizeof(struct record));
  if (T == NULL) {
    fprintf(stderr, "Can't allocate temporary in To_blocked\n");
    exit(1);
  }

  // for each block of C
  c_p = C;
  for (i_bar = 0; i_bar < n_bar; i_bar++) {
    for (j_bar = 0; j_bar < n_bar; j_bar++) {

      // Copy block into correct locations in T
      t_p = T + (i_bar * b * n + j_bar * b);
      for (i = 0; i < b; i++, t_p += (n - b)) {
        for (j = 0; j < b; j++) {
          t_p->value = c_p->value;
          t_p++;
          c_p++;
        }
      }
    }
  }

  memcpy(C, T, n * n * sizeof(struct record));
  free(T);
}
