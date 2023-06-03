#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"
#include "pstat.h"
#include "date.h"

struct
{
  struct spinlock lock;
  struct proc proc[NPROC];
  unsigned int PromoteAtTime;
} ptable;

static struct proc *initproc;
// struct proc *priorityQueue[MAXPRIORITY][NPROC];

int nextpid = 1;
extern void forkret(void);
extern void trapret(void);

static void wakeup1(void *chan);

// set priority of a process
int setpriority(int pid, int priority)
{
  struct proc *p;
  // bound check
  acquire(&ptable.lock);
  if (priority < 0 || priority > MAXPRIORITY)
  {
    return -1; // return error
  }
  // lock the table - no change can be done to the table
  // iterate over the table and find the process with the given pid
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    // if found, set the priority and return
    if (p->pid == pid)
    {
      p->priority = priority;
      p->budget = DEFAULT_BUDGET;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock); // unlock
  return -1;
}

int getpriority(int pid)
{
  struct proc *p;

  acquire(&ptable.lock); // lock the table
  // iterate over the table and find the process with the given pid
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    // if found, return the priority
    if (p->pid == pid && p->state != UNUSED)
    {
      release(&ptable.lock);
      return p->priority;
    }
  }
  release(&ptable.lock); // unlock
  return -1;
}

void pinit(void)
{
  initlock(&ptable.lock, "ptable");
}

// Must be called with interrupts disabled
int cpuid()
{
  return mycpu() - cpus;
}

// Must be called with interrupts disabled to avoid the caller being
// rescheduled between reading lapicid and running through the loop.
struct cpu *
mycpu(void)
{
  int apicid, i;

  if (readeflags() & FL_IF)
    panic("mycpu called with interrupts enabled\n");

  apicid = lapicid();
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i)
  {
    if (cpus[i].apicid == apicid)
      return &cpus[i];
  }
  panic("unknown apicid\n");
}

// Disable interrupts so that we are not rescheduled
// while reading proc from the cpu structure
struct proc *
myproc(void)
{
  struct cpu *c;
  struct proc *p;
  pushcli();
  c = mycpu();
  p = c->proc;
  popcli();
  return p;
}

// PAGEBREAK: 32
//  Look in the process table for an UNUSED proc.
//  If found, change state to EMBRYO and initialize
//  state required to run in the kernel.
//  Otherwise return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
    {
      goto found;
    }
  }

  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  p->budget = DEFAULT_BUDGET;
  p->priority = MAXPRIORITY;
  p->num_tickets = 1;   // by default each proc should get one ticket
  p->num_scheduled = 0; // initialised to no times scheduled
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if ((p->kstack = kalloc()) == 0)
  {
    p->state = UNUSED;
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;

  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  p->tf = (struct trapframe *)sp;

  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint *)sp = (uint)trapret;

  sp -= sizeof *p->context;
  p->context = (struct context *)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;

  return p;
}

// PAGEBREAK: 32
//  Set up first user process.
void userinit(void)
{
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  ptable.PromoteAtTime = ticks + TICKS_TO_PROMOTE;

  p = allocproc();

  initproc = p;
  if ((p->pgdir = setupkvm()) == 0)
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE;
  memset(p->tf, 0, sizeof(*p->tf));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0; // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  // this assignment to p->state lets other cores
  // run this process. the acquire forces the above
  // writes to be visible, and the lock is also needed
  // because the assignment might not be atomic.
  acquire(&ptable.lock);

  p->state = RUNNABLE;

  release(&ptable.lock);
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint sz;
  struct proc *curproc = myproc();

  sz = curproc->sz;
  if (n > 0)
  {
    if ((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  else if (n < 0)
  {
    if ((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  curproc->sz = sz;
  switchuvm(curproc);
  return 0;
}

// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *curproc = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy process state from proc.
  if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0)
  {
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = curproc->sz;
  np->parent = curproc;
  *np->tf = *curproc->tf;
  np->num_tickets = curproc->num_tickets;
  np->num_scheduled = 0;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for (i = 0; i < NOFILE; i++)
    if (curproc->ofile[i])
      np->ofile[i] = filedup(curproc->ofile[i]);
  np->cwd = idup(curproc->cwd);

  safestrcpy(np->name, curproc->name, sizeof(curproc->name));

  pid = np->pid;

  acquire(&ptable.lock);

  np->state = RUNNABLE;

  release(&ptable.lock);

  return pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void exit(void)
{
  struct proc *curproc = myproc();
  struct proc *p;
  int fd;

  if (curproc == initproc)
    panic("init exiting");

  // Close all open files.
  for (fd = 0; fd < NOFILE; fd++)
  {
    if (curproc->ofile[fd])
    {
      fileclose(curproc->ofile[fd]);
      curproc->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(curproc->cwd);
  end_op();
  curproc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);

  // Pass abandoned children to init.
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->parent == curproc)
    {
      p->parent = initproc;
      if (p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  curproc->state = ZOMBIE;
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(void)
{
  struct proc *p;
  int havekids, pid;
  struct proc *curproc = myproc();

  acquire(&ptable.lock);
  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    {
      if (p->parent != curproc)
        continue;
      havekids = 1;
      if (p->state == ZOMBIE)
      {
        // Found one.
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        p->state = UNUSED;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || curproc->killed)
    {
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curproc, &ptable.lock); // DOC: wait-sleep
  }
}

// PAGEBREAK: 42
//  Per-CPU process scheduler.
//  Each CPU calls scheduler() after setting itself up.
//  Scheduler never returns.  It loops, doing:
//   - choose a process to run
//   - swtch to start running that process
//   - eventually that process transfers control
//       via swtch back to the scheduler.
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;

  for (;;)
  {
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    {

      if (p->state != RUNNABLE)
      {
        continue;
      }

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.

      c->proc = p;
      switchuvm(p);
      p->state = RUNNING;
      swtch(&(c->scheduler), p->context);
      switchkvm();

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
    }
    release(&ptable.lock);
  }
}

// //find the process in the priority queue array and return its index
// int find(struct proc *p){
//   int i,j;
//   for (j = 0; j < 3; j++){
//   for(i = 0; i < NPROC; i++){
//     if(p == priorityQueue[j][i]){
//       return i;
//     }
//   }}
//   return -1;
// }

// //remove the process from the priority queue array
// void remove(struct proc *p){
//   int i = find(p);
//   if(i != -1){
//     priorityQueue[p->priority][i] = 0;
//   }
// }

// //add the process to the priority queue array
// void add(struct proc *p){
//   int i;
//   for(i = 0; i < NPROC; i++){
//     if(priorityQueue[p->priority][i] == 0){
//       priorityQueue[p->priority][i] = p;
//       break;
//     }
//   }
// }

// adjust priority function
void adjustPriority(struct proc *p)
{
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->state != ZOMBIE)
    {
      if (p->priority < MAXPRIORITY)
      {
        p->priority = p->priority + 1;
        p->budget = DEFAULT_BUDGET;
      }
    }
  }
}

// MLFQ scheduler
void mlfqsched(void)
{
  struct proc *p;          // pointer to the process
  struct cpu *c = mycpu(); // pointer to the cpu - mycpu() returns the address of the current cpu
  c->proc = 0;             // set the current process to 0

  for (;;)
  {
    // Enable interrupts on this processor.
    sti();
    acquire(&ptable.lock);

    int current_priority; // set the current priority to the highest priority
    for (current_priority = MAXPRIORITY; current_priority >= 0;)
    {
      int count = 0; // count the number of processes in the priority queue which are runnable

      for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) // loop through the process table
      {
        if (p->state != RUNNABLE)
        {
          continue;
        }
        if (p->priority == current_priority) // if the process is runnable and has the current priority (this divides the processes into different priority queues)
        {
          count++;      // increment the count
          c->proc = p;  // set the current process to p
          switchuvm(p); // switch to the process's address space
          p->num_scheduled++;
          p->state = RUNNING; // set the state of the process to running

          int time_in = ticks;                // get the time when the process starts running
          swtch(&(c->scheduler), p->context); // runs the process p
          int time_out = ticks;               // get the time when the process stops running
          switchkvm();                        // switch to the kernel's address space
          p->ticks += time_out - time_in;
          // Process is done running for now.
          // It should have changed its p->state before coming back.
          c->proc = 0; // set the current process to 0

          // update the budget of the process
          p->budget = p->budget - (time_out - time_in);
          if (p->budget <= 0)
          {
            if (p->priority > 0)
            {
              // if the budget is less than or equal to 0, set the priority of the process to the next priority and set the budget to the default budget
              p->priority = p->priority - 1;
              p->budget = DEFAULT_BUDGET;
            }
            else
            {
              // if the budget is less than or equal to 0 and the priority is 0, set the budget to DEFAULT_BUDGET [policy decision because this isn't mentioned in the assignment]
              p->budget = DEFAULT_BUDGET;
            }
          }

          // promotion of the process if it yeilds the cpu or if it finishes its execution
          if (ptable.PromoteAtTime <= ticks)
          {
            adjustPriority(p);
            ptable.PromoteAtTime = ticks + TICKS_TO_PROMOTE;
          }
        }
      }
      if (count == 0)
      {
        current_priority--; // if there are no processes in the priority queue, decrement the priority
      }
    }
    release(&ptable.lock);
  }
}

// Lottery scheduler

int settickets(int number)
{
  if (number < 1) // can the number be greater than the total number of processes if every process should have at least one ticket?
  {
    return -1;
  }

  struct proc *p = myproc(); // current process on the CPU which is running
  p->num_tickets = number;

  return 0;
}

int getpinfo(struct pstat *procinfo) // how to check for null
{

  acquire(&ptable.lock);
  struct proc *p;

  int index = 0; // for index of ptable
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->state != UNUSED)
    {
      procinfo->inuse[index] = 1;
    }

    else if (p->state == UNUSED)
    {
      procinfo->inuse[index] = 0;
    }

    procinfo->tickets[index] = p->num_tickets;
    procinfo->pid[index] = p->pid;
    procinfo->ticks[index] = p->ticks;

    index++;
  }
  release(&ptable.lock);

  acquire(&ptable.lock);
  for (int i = 0; i < NPROC; i++)
  {

    if (procinfo->inuse[i] || procinfo->ticks[i] || procinfo->tickets[i] || procinfo->pid[i]) // only if one of the fields is nonzero
    {
      cprintf("\n %d) Name: %s, PID: %d, Tickets: %d, Ticks: %d, Inuse: %d\n", i, ptable.proc[i].name, procinfo->pid[i], procinfo->tickets[i], procinfo->ticks[i], procinfo->inuse[i]);
    }

    else
    {
      continue;
    }
    // cprintf("\n %d) PID: %d, Tickets: %d, Ticks: %d, Inuse: %d\n", i, procinfo->pid[i], procinfo->tickets[i], procinfo->ticks[i], procinfo->inuse[i]);
  }
  release(&ptable.lock);

  return 0;
}

// using cmostime to generate random numbers
int rand(void)
{
  int seed;

  struct rtcdate r;
  cmostime(&r);
  int timestamp = (int)r.second + 60 * r.minute + 3600 * r.hour + 86400 * (r.day - 1) + 2592000 * (r.month - 1) + 31536000 * (r.year - 1970);
  seed = timestamp % 100;

  seed = 1593 * seed + 1042; // unsigned integers might a pose problem ki using uint then returning as int
  return seed % 4930;        // Can integer overflow happen here
}

int total_runnable_tickets(void)
{
  struct proc *p;
  int available_tickets = 0;

  acquire(&ptable.lock);
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->state == RUNNABLE)
    {
      available_tickets += p->num_tickets;
    }
    else
    {
      continue;
    }
  }
  release(&ptable.lock);

  return available_tickets;
}

void lotterysched(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  int startticks = 0;
  int endticks = 0;

  for (;;)
  {
    // Enable interrupts on this processor.
    sti();

    int runnable_tickets = 0;
    int counter = 0;

    acquire(&ptable.lock);

    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    {

      if (p->state == RUNNABLE)
      {
        // assert that p->num_tickets is 1
        runnable_tickets += p->num_tickets;
      }
      else
      {
        continue;
      }
    }
    release(&ptable.lock);

    // if (runnable_tickets != 1 && runnable_tickets != 0)
    // {
    //   cprintf("\n\n Runnable tickets: %d \n\n", runnable_tickets);
    // }

    if (runnable_tickets > 0) // if runnable_tickets is 0 then don't do this since no process is runnable so nothing to do
    {
      int chosen_ticket = (rand() % runnable_tickets) + 1;

      // Loop over process table looking for process to run.

      acquire(&ptable.lock);

      for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
      {
        if (p->state != RUNNABLE)
        {
          continue;
        }
        // cprintf("\n\n Process Tickets: %d, Random ticket number: %d, Runnable tickets: %d\n\n", p->num_tickets, chosen_ticket, runnable_tickets);

        counter = counter + p->num_tickets;

        if (counter < chosen_ticket)
        {
          continue;
        }

        // Switch to chosen process.  It is the process's job
        // to release ptable.lock and then reacquire it
        // before jumping back to us.

        // if (p->pid != 1)
        // {
        //   cprintf("\n\n Chosen ticket: %d, Chosen process: %s, PID: %d \n\n", chosen_ticket, p->name, p->pid); // for debugging see the process which has been chosen
        // }

        c->proc = p;
        startticks = ticks;
        switchuvm(p);
        // procdump();
        p->num_scheduled++;

        p->state = RUNNING;

        swtch(&(c->scheduler), p->context);
        switchkvm();
        endticks = ticks;
        p->ticks += endticks - startticks;

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
        // cprintf("\nStart ticks: %d, Endticks: %d, Ticks accumulated: %d \n",startticks, endticks, p->ticks);

        break; // so that the loop starts again
      }
      release(&ptable.lock);
    }
    else
    {
      continue;
    } // if no runnable tickets were found then just go to the next iteration of for(;;)
  }
}

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->ncli, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&ptable.lock))
    panic("sched ptable.lock");
  if (mycpu()->ncli != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (readeflags() & FL_IF)
    panic("sched interruptible");
  intena = mycpu()->intena;
  swtch(&p->context, mycpu()->scheduler);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  acquire(&ptable.lock); // DOC: yieldlock
  myproc()->state = RUNNABLE;
  sched();
  release(&ptable.lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first)
  {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
    iinit(ROOTDEV);
    initlog(ROOTDEV);
  }

  // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  if (p == 0)
    panic("sleep");

  if (lk == 0)
    panic("sleep without lk");

  // Must acquire ptable.lock in order to
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if (lk != &ptable.lock)
  {                        // DOC: sleeplock0
    acquire(&ptable.lock); // DOC: sleeplock1
    release(lk);
  }
  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  if (lk != &ptable.lock)
  { // DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}

// PAGEBREAK!
//  Wake up all processes sleeping on chan.
//  The ptable lock must be held.
static void
wakeup1(void *chan)
{
  struct proc *p;

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if (p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
}

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->pid == pid)
    {
      p->killed = 1;
      // Wake process from sleep if necessary.
      if (p->state == SLEEPING)
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}

// PAGEBREAK: 36
//  Print a process listing to console.  For debugging.
//  Runs when user types ^P on console.
//  No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [EMBRYO] "embryo",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    cprintf("PID: %d,  State: %s,  Name: %s,         Tickets: %d, NumScheduled: %d, Ticks: %d, Priority: %d, Budget: %d", p->pid, state, p->name, p->num_tickets, p->num_scheduled, p->ticks, p->priority, p->budget);
    if (p->state == SLEEPING)
    {
      getcallerpcs((uint *)p->context->ebp + 2, pc);
      for (i = 0; i < 10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
  cprintf("----------------------------\n");
}