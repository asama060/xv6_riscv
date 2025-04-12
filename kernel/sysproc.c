#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
uint64 sys_hello(void)
{
  int n;
  argint(0,&n);
  print_hello(n);
  return 0;
}

uint64
sys_sysinfo(void)
{
  int param;
  
  argint(0, &param);
  
  switch(param) {
    case 0:
      return count_active_procs();
    case 1:
      return get_total_syscalls() - 1;
    case 2:
      return count_free_pages();
    default:
      return -1;
  }
}
uint64
sys_procinfo(void)
{
  uint64 info_addr; // User address where struct pinfo will be written
  struct proc *p = myproc();
  struct pinfo info;
  
  // Get the user pointer from argument
  argaddr(0, &info_addr);
  
  // Check for NULL pointer
  if(info_addr == 0)
    return -1;
  
  // Fill in the info structure
  info.ppid = p->parent ? p->parent->pid : -1;
  info.syscall_count = p->syscall_count - 1; // Subtract this syscall
  info.page_usage = (p->sz + PGSIZE - 1) / PGSIZE; // Convert bytes to pages, rounded up
  
  // Copy the structure back to user space
  if(copyout(p->pagetable, info_addr, (char *)&info, sizeof(info)) < 0)
    return -1;
  
  return 0;
}