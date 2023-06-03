#include <stdio.h>
#include <stdlib.h>

void
f(void)
{
    int a[4];               //define an array of 4 integers - static allocation
    int *b = malloc(16);    //define a pointer to an array of 4 integers - dynamic allocation
    int *c;                 //define a pointer to an integer
    int i;                  //an integer

    printf("1: a = %p, b = %p, c = %p\n", a, b, c);             
    //print the addresses of the variables: a = 0x7ffee80fc4a0, b = 0x555df24bf2a0, c = (nil)
    //a is a address of an array of 4 integers, a
    //b is a address of an array of 4 integers, b
    //c is a address of an integer, c - it is nil because it has not been assigned a value yet

    c = a;          //the pointer of a is assigned to c - c is now pointing to the head of the array a
    for (i = 0; i < 4; i++)
	a[i] = 100 + i;     //the array a is assigned values 100, 101, 102, 103 respectively
    c[0] = 200;         //the value of the array a[0] is changed to 200

    printf("2: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",      
	   a[0], a[1], a[2], a[3]);
    //print the values of the array a: a[0] = 200, a[1] = 101, a[2] = 102, a[3] = 103
    //the value of a[0] has been changed to 200 because c[0] = 200 and both a and c are pointing to the same address

    c[1] = 300;     //the value of the array a[1] is changed to 300 as well because c[1] = 300 and both a and c are pointing to the same address
    *(c + 2) = 301; //the value of the array a[2] is changed to 301 as well because *(c + 2) = 301 updates the value of array a too 
    3[c] = 302;     //this also updates the value of array a to 302 because 3[c] = 302 updates the value of array a too
    printf("3: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);
    //print the values of the array a: a[0] = 200, a[1] = 300, a[2] = 301, a[3] = 302

    c = c + 1;      //the pointer of c is incremented by 1, so it is now pointing to the second element of the array a
    *c = 400;       //update the value of the array a[1] to 400

    printf("4: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    //print the values of the array a: a[0] = 200, a[1] = 400, a[2] = 301, a[3] = 302

    c = (int *) ((char *) c + 1);       //the pointer of c is incremented by 1 byte - pointing to second element of the array a but starting from the second byte
    *c = 500;                           //put the value 500 in the second byte of the array a[1]
    printf("5: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);
    //print the values of the array a: a[0] = 200, a[1] = 400, a[2] = 500, a[3] = 302
    //but the value of a[1] is some random number because the pointer of c is incremented by 1 byte, whereas an integer is of 4 bytes
    //the value is random because it considers the 3 bytes from the second element of the array a and first byte from the third element of the array a
    //this also affects the value of a[2] because now it is just three bytes from the second element of the array a
    //a[3] is not affected because it is still 4 bytes from the second element of the array a

    b = (int *) a + 1;      //the pointer of b is incremented by 1, so it is now pointing to the second element of the array a
    c = (int *) ((char *) a + 1);   //the pointer of c is incremented by 1 byte, so it is now pointing to the second element of the array a but starting from the second byte
    printf("6: a = %p, b = %p, c = %p\n", a, b, c); 
    //print the addresses of the variables: a = 0x7ffee80fc4a0, b = 0x7ffee80fc4a4, c = 0x7ffee80fc4a1
    //the address of a is the same because it is a static allocation
    //the address of b is incremented by 4 because it is a dynamic allocation
    //the address of c is incremented by 1 because it is a static allocation but starting from the second byte
}

int
main(int ac, char **av)
{
    f();
    return 0;
}

