#include "types.h"
#include "user.h"

// test case for checking if the MLFQ scheduler is working properly
// by creating 3 processes with different priorities and checking
// if the scheduler is scheduling them in the correct order

int main()
{
    int pid1, pid2, pid3;
    int i;
    
    pid1 = fork();
    if(pid1 == 0)
    {
        for(i = 0; i < 100; i++)
        {
        printf(1, "child 1\n");
        }
        exit();
    }
    else
    {
        pid2 = fork();
        if(pid2 == 0)
        {
        for(i = 0; i < 100; i++)
        {
            printf(1, "child 2\n");
        }
        exit();
        }
        else
        {
        pid3 = fork();
        if(pid3 == 0)
        {
            for(i = 0; i < 100; i++)
            {
            printf(1, "child 3\n");
            }
            exit();
        }
        else
        {
            setpriority(pid1, 1);
            setpriority(pid2, 2);
            setpriority(pid3, 3);
            for(i = 0; i < 100; i++)
            {
            printf(1, "parent\n");
            }
            wait();
            wait();
            wait();
        }
        }
    }
    exit();
}