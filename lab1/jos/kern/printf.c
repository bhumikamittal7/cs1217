// Simple implementation of cprintf console output for the kernel,
// based on printfmt() and the kernel console's cputchar().

#include <inc/types.h>
#include <inc/stdio.h>
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
	cputchar(ch);
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
	int cnt = 0;

	vprintfmt((void*)putch, &cnt, fmt, ap);
	//this function takes a format string and a va_list of arguments, formats the string using vprintfmt(), and outputs it to the console using the putch() function, which ultimately calls cputchar().
	return cnt;
}

int
cprintf(const char *fmt, ...)
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
	va_end(ap);

	return cnt;
}


/* 
Explanation of the code

This code implements a console output function for a kernel using the cputchar() function from the kernel console. It defines two functions: vcprintf() and cprintf().
The vcprintf() function takes a format string and a va_list of arguments, formats the string using vprintfmt(), and outputs it to the console using the putch() function, which ultimately calls cputchar().
The cprintf() function is a wrapper around vcprintf() and takes the same arguments but uses the va_start(), va_end() and va_list macros to handle variable arguments. Finally, both functions return the number of characters outputted to the console.

*/