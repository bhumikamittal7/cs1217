// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h> // for page2pa(), struct PageInfo, etc

#define CMDBUF_SIZE 80 // enough for one VGA text line

uint32_t convert2int(char *str); // convert hex string to int

struct Command
{
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char **argv, struct Trapframe *tf);
};

static struct Command commands[] = {
	{"help", "Display this list of commands", mon_help},
	{"kerninfo", "Display information about the kernel", mon_kerninfo},
	{"showmappings", "Display the page mappings of the given virtual address range", mon_showmappings},
	{"setperm", "Set the permission of the given virtual address range", mon_setperm},
	{"dumpv", "Dump the content of the given virtual or physical address range", mon_dumpv},
	{"dumpp", "Dump the content of the given virtual or physical address range", mon_dumpp},
	// {"backtrace", "Print backtrace of all stack frames - for debugging", mon_backtrace},
	{"pagesize", "Prints the page size", mon_pagesize},
	{"loadv", "Modify a byte at given virtual memory", mon_loadv},
	{"loadp", "Modify a byte at given physical memory", mon_loadp},
};

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	return 0;
}

// convert hex string to int
uint32_t convert2int(char *str)
{
	uint32_t result = 0;
	int i = 0;
	while (str[i] != '\0')
	{
		if (str[i] >= '0' && str[i] <= '9')
		{
			result = result * 16 + (str[i] - '0');
		}
		else if (str[i] >= 'a' && str[i] <= 'f')
		{
			result = result * 16 + (str[i] - 'a' + 10);
		}
		else if (str[i] >= 'A' && str[i] <= 'F')
		{
			result = result * 16 + (str[i] - 'A' + 10);
		}
		i++;
	}
	return result;
}

// given a virtual address, return the physical address
int virtual2physical(uint32_t virtual_address)
{
	pte_t *pte = pgdir_walk(kern_pgdir, (void *)virtual_address, 0); // get the page table entry

	if (!pte) // if the page table entry is not present, return -1
		return -1;

	return PTE_ADDR(*pte) + (virtual_address & 0xFFF); // return the physical address
}

// given a physical address, return the virtual address
int physical2virtual(uint32_t physical_address)
{
	return (uint32_t)KADDR(physical_address); // return the virtual address
}

// extract permission bits from the page table entry in form of three bits (P, W, U)
// output should be in the form of a string - "P W U" (without the quotes) - if the permission is present, else "-"
char *extractperm(pte_t pte)
{
	static char perm[4];
	perm[0] = (pte & PTE_P) ? 'P' : '-';
	perm[1] = (pte & PTE_W) ? 'W' : '-';
	perm[2] = (pte & PTE_U) ? 'U' : '-';
	perm[3] = '\0';
	return perm;
}

// return the permission of the given virtual address
char *getperm(uint32_t virtual_address)
{
	pte_t *pte = pgdir_walk(kern_pgdir, (void *)virtual_address, 0); // get the page table entry

	if (!pte) // if the page table entry is not present, return -1
		return NULL;

	// return the permission bits of the page table entry
	return extractperm(*pte);
}

// show the page mappings of the given virtual address range
int mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
	// sanity check - make sure the user entered the correct number of arguments
	if (argc == 1)
	{
		cprintf("The function takes two arguments - beginning address and end address\n");
		return 0;
	}

	// convert the arguments to integers
	uint32_t start = convert2int(argv[1]);
	uint32_t end = convert2int(argv[2]);

	cprintf("start address: %x, end address: %x\n", start, end);
	for (; start <= end; start += PGSIZE)
	{
		pte_t *pte = pgdir_walk(kern_pgdir, (void *)start, 1); // get the page table entry

		if (!pte)
			panic("page table entry not found - out of memory?");

		if (*pte & PTE_P) // if the page is present and has a physical address
		{
			cprintf("virtual page: %x ", start);					// print the virtual address - the start address
			cprintf("physical page: %x ", virtual2physical(start)); // print the physical address
			cprintf("permission: %s \n", getperm(start));			// print the physical address
		}
		else
			cprintf("page don't exist: %x\n", start); // if the page is not present, say that the page does not exist
	}
	return 0;
	// test -- showmappings 0xf0110000 0xf011a000
}

// function to print the permission bits of the page table entry
void printPermission(pte_t *pte)
{
	cprintf("PTE_P: %d, PTE_W: %d, PTE_U: %d \r \n", (*pte & PTE_P) ? 1 : 0, (*pte & PTE_W) ? 1 : 0, (*pte & PTE_U) ? 1 : 0);
}

// change the permission of the given virtual address
int mon_setperm(int argc, char **argv, struct Trapframe *tf)
{
	if (argc == 1)
	{
		cprintf("The function takes three arguments - addresss, clear/set and permission\n");
		return 0;
	}
	uint32_t addr = convert2int(argv[1]); // convert the address to integer

	pte_t *pte = pgdir_walk(kern_pgdir, (void *)addr, 1); // get the page table entry
	if (!pte)
		panic("page table entry not found - out of memory?");

	cprintf("%x before setperm: ", addr); // print the virtual address
	printPermission(pte);				  // print the permissions

	uint32_t perm = 0; // permission bits

	if (argv[3][0] == 'P')
		perm = PTE_P;
	if (argv[3][0] == 'W')
		perm = PTE_W;
	if (argv[3][0] == 'U')
		perm = PTE_U;
	if (argv[2][0] == '0') // clear the permission
		*pte = *pte & ~perm;
	else // set	the permission
		*pte = *pte | perm;

	cprintf("%x after setperm: ", addr);
	printPermission(pte);

	return 0;
} // setperm 0xef400000 0 P (for setting P to 0 for given va)

// dump the contents of the given virtual address range
int mon_dumpv(int argc, char **argv, struct Trapframe *tf)
{
	// sanity check
	if (argc == 1)
	{
		cprintf("The function takes two arguments - beginning address and end address\n");
		return 0;
	}
	// convert the arguments to integers
	uint32_t start = convert2int(argv[1]);
	uint32_t end = convert2int(argv[2]);

	// check the validity of the addresses
	if (start > end)
	{
		cprintf("The start address should be less than the end address\n");
		return 0;
	}

	// check if the addresses are in the virtual address range
	if (start < UTOP)
	{
		cprintf("The start address should be greater than UTOP\n");
		return 0;
	}

	if (end < UTOP)
	{
		cprintf("The end address should be greater than UTOP\n");
		return 0;
	}


	cprintf("start address: %x, end address: %x\n", start, end);
	// loop through the virtual address range and print the contents
	while (start <= end)
	{
		cprintf("Virtual Address: %x contains %x %x %x %x \r \n", start, *(uint32_t *)start, *(uint32_t *)(start + 1), *(uint32_t *)(start + 2), *(uint32_t *)(start + 3));
		start += 4;
	}
	return 0;
	// test -- dumpv 0xe0110000 0xe0110004
}

// dump the contents of the given physical address range
int mon_dumpp(int argc, char **argv, struct Trapframe *tf)
{
	// sanity check
	if (argc == 1)
	{
		cprintf("The function takes two arguments - beginning address and end address\n");
		return 0;
	}
	// convert the physical address to virtual address
	uint32_t start = physical2virtual(convert2int(argv[1]));
	uint32_t end = physical2virtual(convert2int(argv[2]));

	// check the validity of the addresses
	if (start > end)
	{
		cprintf("The start address should be less than the end address\n");
		return 0;
	}

	// check if the addresses are in the physical address range
	if (start > UTOP)
	{
		cprintf("The start address should be less than UTOP\n");
		return 0;
	}
	if (end > UTOP)
	{
		cprintf("The end address should be less than UTOP\n");
		return 0;
	}

	cprintf("start address: %x, end address: %x\n", start, end);
	// loop through the physical address range and print the contents
	while (start <= end)
	{
		cprintf("Physical Address: %x contains %x %x %x %x \r \n", start, *(uint32_t *)start, *(uint32_t *)(start + 1), *(uint32_t *)(start + 2), *(uint32_t *)(start + 3));
		start += 4;
	}
	return 0;
	// test -- dumpp 0x100000 0x100001
}

// function to print the page size of the given virtual address - for debugging
int mon_pagesize(int argc, char **argv, struct Trapframe *tf)
{
	// sanity check
	if (argc == 1)
	{
		cprintf("The function takes one argument - address\n");
		return 0;
	}
	// convert the address to integer
	uint32_t addr = convert2int(argv[1]);

	// get the page table entry
	pte_t *pte = pgdir_walk(kern_pgdir, (void *)addr, 1);
	if (!pte)
		panic("page table entry not found - out of memory?");

	// print the page size
	if (*pte & PTE_PS)
		cprintf("Page size: 4MB \r \n");
	else
		cprintf("Page size: 4KB \r \n");

	return 0;
	// test -- pagesize 0xf0110000
}

// Modify a byte at given virtual memory
int mon_loadv(int argc, char **argv, struct Trapframe *tf)
{
	// sanity check
	if (argc == 1)
	{
		cprintf("The function takes three arguments - address, value and size\n");
		return 0;
	}
	// convert the address to integer
	uint32_t addr = convert2int(argv[1]);
	// convert the value to integer
	uint32_t value = convert2int(argv[2]);
	// convert the size to integer
	uint32_t size = convert2int(argv[3]);

	// get the page table entry
	pte_t *pte = pgdir_walk(kern_pgdir, (void *)addr, 1);
	if (!pte)
		panic("page table entry not found - out of memory?");

	// check if the page is present
	if (!(*pte & PTE_P))
		panic("page not present");

	// check if the page is writable
	if (!(*pte & PTE_W))
		panic("page not writable");

	// check if the size is valid
	if (size != 1 && size != 2 && size != 4)
		panic("invalid size");

	// check if the address is aligned
	if (addr % size != 0)
		panic("address not aligned");

	// check if the value is valid
	if (size == 1 && value > 0xff)
		panic("invalid value");
	if (size == 2 && value > 0xffff)
		panic("invalid value");
	if (size == 4 && value > 0xffffffff)
		panic("invalid value");

	// modify the byte
	*(uint32_t *)addr = value;

	return 0;
	// test -- loadv 0xf0110000 0x12345678 4
}

// Modify a byte at given physical memory
int mon_loadp(int argc, char **argv, struct Trapframe *tf)
{
	// sanity check
	if (argc == 1)
	{
		cprintf("The function takes three arguments - address, value and size\n");
		return 0;
	}
	// convert the address to integer
	uint32_t addr = physical2virtual(convert2int(argv[1]));
	// convert the value to integer
	uint32_t value = convert2int(argv[2]);
	// convert the size to integer
	uint32_t size = convert2int(argv[3]);

	// get the page table entry
	pte_t *pte = pgdir_walk(kern_pgdir, (void *)addr, 1);
	if (!pte)
		panic("page table entry not found - out of memory?");

	// check if the page is present
	if (!(*pte & PTE_P))
		panic("page not present");

	// check if the page is writable
	if (!(*pte & PTE_W))
		panic("page not writable");

	// check if the size is valid
	if (size != 1 && size != 2 && size != 4)
		panic("invalid size");

	// check if the address is aligned
	if (addr % size != 0)
		panic("address not aligned");

	// check if the value is valid
	if (size == 1 && value > 0xff)
		panic("invalid value");
	if (size == 2 && value > 0xffff)
		panic("invalid value");
	if (size == 4 && value > 0xffffffff)
		panic("invalid value");

	// modify the byte
	*(uint32_t *)addr = value;

	return 0;
	// test -- loadp 0xf0110000 0x12345678 4
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS - 1)
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++)
	{
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	while (1)
	{
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
