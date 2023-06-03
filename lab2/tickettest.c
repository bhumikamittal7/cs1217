#include "types.h"
#include "user.h"


// test case for checking if settickets is working properly and process with higher tickets is indeed getting more CPU time

int main(void)
{
    settickets(2); 
    int returnCode = fork();

    if (returnCode == 0) // in child
    {
        settickets(3);
        int j = 0;
        for (int i = 0; i < 1000; i++) // just run for these many iterations and do meaningless thing
        {
            j+=i;
        }
        
        printf(1, "\n I am the child process with PID: %d\n", getpid()); 

        exit();
    }
    else                // in parent
    {
        int pid_child;
        pid_child = wait();
        int k = 0;
        if (pid_child == -1)
        {
            printf(1,"\nProcess has no children\n");
            for (int i = 0; i < 1000; i++) // just run for these many iterations and do meaningless thing
            {
                k+=i;
            }
            printf(1, "\n I am the parent process with PID: %d\n", getpid());
            
            exit();
        }

        else 
        {
            
            for (int i = 0; i < 100; i++) // just run for these many iterations and do meaningless thing
            {
                k+=i;
            }
            printf(1, "\n I am the parent process with PID: %d\n", getpid());
            wait();
            exit();
        }
    }

}


// in the below test the output interferes
// #include "types.h"
// #include "user.h"



// int main(void)

// {
//     settickets(59);
//     int returnCode;
//     returnCode = fork();

//     if (returnCode == 0) // we are in the child
//     {
//         settickets(1);
        
//         printf(1, "\nI am the child process with pid: %d\n", getpid());
//         exit();
//     }
//     else // we are in the parent
//     {
        
//         printf(1, "\nI am the parent process with pid: %d\n", getpid());
//         wait();
//         exit();
//     }
// }