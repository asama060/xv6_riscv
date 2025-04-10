#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  printf("Active processes: %d\n", sysinfo(0));
  printf("Total syscalls: %d\n", sysinfo(1));
  printf("Free memory pages: %d\n", sysinfo(2));
  
  // Allocate some memory to test
  char *mem = malloc(4096 * 10);  // 10 pages
  printf("Free memory pages after allocation: %d\n", sysinfo(2));
  
  // Free the memory
  free(mem);
  printf("Free memory pages after free: %d\n", sysinfo(2));
  
  // Test invalid parameter
  printf("Invalid parameter: %d\n", sysinfo(3));
  
  exit(0);
}