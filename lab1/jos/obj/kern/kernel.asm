
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp
	
	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 72 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 b8 08 ff ff    	lea    -0xf748(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 7a 0a 00 00       	call   f0100add <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7e 29                	jle    f0100093 <test_backtrace+0x53>
		test_backtrace(x-1);
f010006a:	83 ec 0c             	sub    $0xc,%esp
f010006d:	8d 46 ff             	lea    -0x1(%esi),%eax
f0100070:	50                   	push   %eax
f0100071:	e8 ca ff ff ff       	call   f0100040 <test_backtrace>
f0100076:	83 c4 10             	add    $0x10,%esp
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
f0100079:	83 ec 08             	sub    $0x8,%esp
f010007c:	56                   	push   %esi
f010007d:	8d 83 d4 08 ff ff    	lea    -0xf72c(%ebx),%eax
f0100083:	50                   	push   %eax
f0100084:	e8 54 0a 00 00       	call   f0100add <cprintf>
}
f0100089:	83 c4 10             	add    $0x10,%esp
f010008c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010008f:	5b                   	pop    %ebx
f0100090:	5e                   	pop    %esi
f0100091:	5d                   	pop    %ebp
f0100092:	c3                   	ret    
		mon_backtrace(0, 0, 0);
f0100093:	83 ec 04             	sub    $0x4,%esp
f0100096:	6a 00                	push   $0x0
f0100098:	6a 00                	push   $0x0
f010009a:	6a 00                	push   $0x0
f010009c:	e8 ed 07 00 00       	call   f010088e <mon_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d3                	jmp    f0100079 <test_backtrace+0x39>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 08             	sub    $0x8,%esp
f01000ad:	e8 0a 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 56 12 01 00    	add    $0x11256,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000be:	c7 c0 c0 36 11 f0    	mov    $0xf01136c0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 a6 16 00 00       	call   f0101775 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3e 05 00 00       	call   f0100612 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 ef 08 ff ff    	lea    -0xf711(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 f5 09 00 00       	call   f0100add <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ef:	e8 4c ff ff ff       	call   f0100040 <test_backtrace>
f01000f4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 23 08 00 00       	call   f0100924 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <i386_init+0x51>

f0100106 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100106:	55                   	push   %ebp
f0100107:	89 e5                	mov    %esp,%ebp
f0100109:	56                   	push   %esi
f010010a:	53                   	push   %ebx
f010010b:	e8 ac 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100110:	81 c3 f8 11 01 00    	add    $0x111f8,%ebx
	va_list ap;

	if (panicstr)
f0100116:	83 bb 58 1d 00 00 00 	cmpl   $0x0,0x1d58(%ebx)
f010011d:	74 0f                	je     f010012e <_panic+0x28>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010011f:	83 ec 0c             	sub    $0xc,%esp
f0100122:	6a 00                	push   $0x0
f0100124:	e8 fb 07 00 00       	call   f0100924 <monitor>
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	eb f1                	jmp    f010011f <_panic+0x19>
	panicstr = fmt;
f010012e:	8b 45 10             	mov    0x10(%ebp),%eax
f0100131:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	asm volatile("cli; cld");
f0100137:	fa                   	cli    
f0100138:	fc                   	cld    
	va_start(ap, fmt);
f0100139:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010013c:	83 ec 04             	sub    $0x4,%esp
f010013f:	ff 75 0c             	push   0xc(%ebp)
f0100142:	ff 75 08             	push   0x8(%ebp)
f0100145:	8d 83 0a 09 ff ff    	lea    -0xf6f6(%ebx),%eax
f010014b:	50                   	push   %eax
f010014c:	e8 8c 09 00 00       	call   f0100add <cprintf>
	vcprintf(fmt, ap);
f0100151:	83 c4 08             	add    $0x8,%esp
f0100154:	56                   	push   %esi
f0100155:	ff 75 10             	push   0x10(%ebp)
f0100158:	e8 49 09 00 00       	call   f0100aa6 <vcprintf>
	cprintf("\n");
f010015d:	8d 83 01 0c ff ff    	lea    -0xf3ff(%ebx),%eax
f0100163:	89 04 24             	mov    %eax,(%esp)
f0100166:	e8 72 09 00 00       	call   f0100add <cprintf>
f010016b:	83 c4 10             	add    $0x10,%esp
f010016e:	eb af                	jmp    f010011f <_panic+0x19>

f0100170 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp
f0100173:	56                   	push   %esi
f0100174:	53                   	push   %ebx
f0100175:	e8 42 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010017a:	81 c3 8e 11 01 00    	add    $0x1118e,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100180:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100183:	83 ec 04             	sub    $0x4,%esp
f0100186:	ff 75 0c             	push   0xc(%ebp)
f0100189:	ff 75 08             	push   0x8(%ebp)
f010018c:	8d 83 22 09 ff ff    	lea    -0xf6de(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 45 09 00 00       	call   f0100add <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	push   0x10(%ebp)
f010019f:	e8 02 09 00 00       	call   f0100aa6 <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 01 0c ff ff    	lea    -0xf3ff(%ebx),%eax
f01001aa:	89 04 24             	mov    %eax,(%esp)
f01001ad:	e8 2b 09 00 00       	call   f0100add <cprintf>
	va_end(ap);
}
f01001b2:	83 c4 10             	add    $0x10,%esp
f01001b5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b8:	5b                   	pop    %ebx
f01001b9:	5e                   	pop    %esi
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <__x86.get_pc_thunk.bx>:
f01001bc:	8b 1c 24             	mov    (%esp),%ebx
f01001bf:	c3                   	ret    

f01001c0 <serial_proc_data>:

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c0:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c5:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	74 0a                	je     f01001d4 <serial_proc_data+0x14>
f01001ca:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	c3                   	ret    
		return -1;
f01001d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001d9:	c3                   	ret    

f01001da <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001da:	55                   	push   %ebp
f01001db:	89 e5                	mov    %esp,%ebp
f01001dd:	57                   	push   %edi
f01001de:	56                   	push   %esi
f01001df:	53                   	push   %ebx
f01001e0:	83 ec 1c             	sub    $0x1c,%esp
f01001e3:	e8 6a 05 00 00       	call   f0100752 <__x86.get_pc_thunk.si>
f01001e8:	81 c6 20 11 01 00    	add    $0x11120,%esi
f01001ee:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001f0:	8d 1d 98 1d 00 00    	lea    0x1d98,%ebx
f01001f6:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f01001f9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01001fc:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f01001ff:	eb 25                	jmp    f0100226 <cons_intr+0x4c>
		cons.buf[cons.wpos++] = c;
f0100201:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f0100208:	8d 51 01             	lea    0x1(%ecx),%edx
f010020b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010020e:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100211:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f0100217:	b8 00 00 00 00       	mov    $0x0,%eax
f010021c:	0f 44 d0             	cmove  %eax,%edx
f010021f:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
	while ((c = (*proc)()) != -1) {
f0100226:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100229:	ff d0                	call   *%eax
f010022b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010022e:	74 06                	je     f0100236 <cons_intr+0x5c>
		if (c == 0)
f0100230:	85 c0                	test   %eax,%eax
f0100232:	75 cd                	jne    f0100201 <cons_intr+0x27>
f0100234:	eb f0                	jmp    f0100226 <cons_intr+0x4c>
	}
}
f0100236:	83 c4 1c             	add    $0x1c,%esp
f0100239:	5b                   	pop    %ebx
f010023a:	5e                   	pop    %esi
f010023b:	5f                   	pop    %edi
f010023c:	5d                   	pop    %ebp
f010023d:	c3                   	ret    

f010023e <kbd_proc_data>:
{
f010023e:	55                   	push   %ebp
f010023f:	89 e5                	mov    %esp,%ebp
f0100241:	56                   	push   %esi
f0100242:	53                   	push   %ebx
f0100243:	e8 74 ff ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100248:	81 c3 c0 10 01 00    	add    $0x110c0,%ebx
f010024e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100253:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100254:	a8 01                	test   $0x1,%al
f0100256:	0f 84 f7 00 00 00    	je     f0100353 <kbd_proc_data+0x115>
	if (stat & KBS_TERR)
f010025c:	a8 20                	test   $0x20,%al
f010025e:	0f 85 f6 00 00 00    	jne    f010035a <kbd_proc_data+0x11c>
f0100264:	ba 60 00 00 00       	mov    $0x60,%edx
f0100269:	ec                   	in     (%dx),%al
f010026a:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010026c:	3c e0                	cmp    $0xe0,%al
f010026e:	74 64                	je     f01002d4 <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f0100270:	84 c0                	test   %al,%al
f0100272:	78 75                	js     f01002e9 <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f0100274:	8b 8b 78 1d 00 00    	mov    0x1d78(%ebx),%ecx
f010027a:	f6 c1 40             	test   $0x40,%cl
f010027d:	74 0e                	je     f010028d <kbd_proc_data+0x4f>
		data |= 0x80;
f010027f:	83 c8 80             	or     $0xffffff80,%eax
f0100282:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100284:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100287:	89 8b 78 1d 00 00    	mov    %ecx,0x1d78(%ebx)
	shift |= shiftcode[data];
f010028d:	0f b6 d2             	movzbl %dl,%edx
f0100290:	0f b6 84 13 78 0a ff 	movzbl -0xf588(%ebx,%edx,1),%eax
f0100297:	ff 
f0100298:	0b 83 78 1d 00 00    	or     0x1d78(%ebx),%eax
	shift ^= togglecode[data];
f010029e:	0f b6 8c 13 78 09 ff 	movzbl -0xf688(%ebx,%edx,1),%ecx
f01002a5:	ff 
f01002a6:	31 c8                	xor    %ecx,%eax
f01002a8:	89 83 78 1d 00 00    	mov    %eax,0x1d78(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002ae:	89 c1                	mov    %eax,%ecx
f01002b0:	83 e1 03             	and    $0x3,%ecx
f01002b3:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002ba:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002be:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002c1:	a8 08                	test   $0x8,%al
f01002c3:	74 61                	je     f0100326 <kbd_proc_data+0xe8>
		if ('a' <= c && c <= 'z')
f01002c5:	89 f2                	mov    %esi,%edx
f01002c7:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002ca:	83 f9 19             	cmp    $0x19,%ecx
f01002cd:	77 4b                	ja     f010031a <kbd_proc_data+0xdc>
			c += 'A' - 'a';
f01002cf:	83 ee 20             	sub    $0x20,%esi
f01002d2:	eb 0c                	jmp    f01002e0 <kbd_proc_data+0xa2>
		shift |= E0ESC;
f01002d4:	83 8b 78 1d 00 00 40 	orl    $0x40,0x1d78(%ebx)
		return 0;
f01002db:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002e0:	89 f0                	mov    %esi,%eax
f01002e2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002e5:	5b                   	pop    %ebx
f01002e6:	5e                   	pop    %esi
f01002e7:	5d                   	pop    %ebp
f01002e8:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002e9:	8b 8b 78 1d 00 00    	mov    0x1d78(%ebx),%ecx
f01002ef:	83 e0 7f             	and    $0x7f,%eax
f01002f2:	f6 c1 40             	test   $0x40,%cl
f01002f5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002f8:	0f b6 d2             	movzbl %dl,%edx
f01002fb:	0f b6 84 13 78 0a ff 	movzbl -0xf588(%ebx,%edx,1),%eax
f0100302:	ff 
f0100303:	83 c8 40             	or     $0x40,%eax
f0100306:	0f b6 c0             	movzbl %al,%eax
f0100309:	f7 d0                	not    %eax
f010030b:	21 c8                	and    %ecx,%eax
f010030d:	89 83 78 1d 00 00    	mov    %eax,0x1d78(%ebx)
		return 0;
f0100313:	be 00 00 00 00       	mov    $0x0,%esi
f0100318:	eb c6                	jmp    f01002e0 <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f010031a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010031d:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100320:	83 fa 1a             	cmp    $0x1a,%edx
f0100323:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100326:	f7 d0                	not    %eax
f0100328:	a8 06                	test   $0x6,%al
f010032a:	75 b4                	jne    f01002e0 <kbd_proc_data+0xa2>
f010032c:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100332:	75 ac                	jne    f01002e0 <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f0100334:	83 ec 0c             	sub    $0xc,%esp
f0100337:	8d 83 3c 09 ff ff    	lea    -0xf6c4(%ebx),%eax
f010033d:	50                   	push   %eax
f010033e:	e8 9a 07 00 00       	call   f0100add <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100343:	b8 03 00 00 00       	mov    $0x3,%eax
f0100348:	ba 92 00 00 00       	mov    $0x92,%edx
f010034d:	ee                   	out    %al,(%dx)
}
f010034e:	83 c4 10             	add    $0x10,%esp
f0100351:	eb 8d                	jmp    f01002e0 <kbd_proc_data+0xa2>
		return -1;
f0100353:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100358:	eb 86                	jmp    f01002e0 <kbd_proc_data+0xa2>
		return -1;
f010035a:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010035f:	e9 7c ff ff ff       	jmp    f01002e0 <kbd_proc_data+0xa2>

f0100364 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100364:	55                   	push   %ebp
f0100365:	89 e5                	mov    %esp,%ebp
f0100367:	57                   	push   %edi
f0100368:	56                   	push   %esi
f0100369:	53                   	push   %ebx
f010036a:	83 ec 1c             	sub    $0x1c,%esp
f010036d:	e8 4a fe ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100372:	81 c3 96 0f 01 00    	add    $0x10f96,%ebx
f0100378:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010037b:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100380:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100385:	b9 84 00 00 00       	mov    $0x84,%ecx
f010038a:	89 fa                	mov    %edi,%edx
f010038c:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010038d:	a8 20                	test   $0x20,%al
f010038f:	75 13                	jne    f01003a4 <cons_putc+0x40>
f0100391:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100397:	7f 0b                	jg     f01003a4 <cons_putc+0x40>
f0100399:	89 ca                	mov    %ecx,%edx
f010039b:	ec                   	in     (%dx),%al
f010039c:	ec                   	in     (%dx),%al
f010039d:	ec                   	in     (%dx),%al
f010039e:	ec                   	in     (%dx),%al
	     i++)
f010039f:	83 c6 01             	add    $0x1,%esi
f01003a2:	eb e6                	jmp    f010038a <cons_putc+0x26>
	outb(COM1 + COM_TX, c);
f01003a4:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f01003a8:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ab:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003b0:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003b1:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003b6:	bf 79 03 00 00       	mov    $0x379,%edi
f01003bb:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003c0:	89 fa                	mov    %edi,%edx
f01003c2:	ec                   	in     (%dx),%al
f01003c3:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003c9:	7f 0f                	jg     f01003da <cons_putc+0x76>
f01003cb:	84 c0                	test   %al,%al
f01003cd:	78 0b                	js     f01003da <cons_putc+0x76>
f01003cf:	89 ca                	mov    %ecx,%edx
f01003d1:	ec                   	in     (%dx),%al
f01003d2:	ec                   	in     (%dx),%al
f01003d3:	ec                   	in     (%dx),%al
f01003d4:	ec                   	in     (%dx),%al
f01003d5:	83 c6 01             	add    $0x1,%esi
f01003d8:	eb e6                	jmp    f01003c0 <cons_putc+0x5c>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003da:	ba 78 03 00 00       	mov    $0x378,%edx
f01003df:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003e3:	ee                   	out    %al,(%dx)
f01003e4:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003e9:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003ee:	ee                   	out    %al,(%dx)
f01003ef:	b8 08 00 00 00       	mov    $0x8,%eax
f01003f4:	ee                   	out    %al,(%dx)
		c |= 0x0700;
f01003f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003f8:	89 f8                	mov    %edi,%eax
f01003fa:	80 cc 07             	or     $0x7,%ah
f01003fd:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100403:	0f 45 c7             	cmovne %edi,%eax
f0100406:	89 c7                	mov    %eax,%edi
f0100408:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f010040b:	0f b6 c0             	movzbl %al,%eax
f010040e:	89 f9                	mov    %edi,%ecx
f0100410:	80 f9 0a             	cmp    $0xa,%cl
f0100413:	0f 84 e4 00 00 00    	je     f01004fd <cons_putc+0x199>
f0100419:	83 f8 0a             	cmp    $0xa,%eax
f010041c:	7f 46                	jg     f0100464 <cons_putc+0x100>
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	0f 84 a8 00 00 00    	je     f01004cf <cons_putc+0x16b>
f0100427:	83 f8 09             	cmp    $0x9,%eax
f010042a:	0f 85 da 00 00 00    	jne    f010050a <cons_putc+0x1a6>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 2a ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 20 ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f0100444:	b8 20 00 00 00       	mov    $0x20,%eax
f0100449:	e8 16 ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f010044e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100453:	e8 0c ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f0100458:	b8 20 00 00 00       	mov    $0x20,%eax
f010045d:	e8 02 ff ff ff       	call   f0100364 <cons_putc>
		break;
f0100462:	eb 26                	jmp    f010048a <cons_putc+0x126>
	switch (c & 0xff) {
f0100464:	83 f8 0d             	cmp    $0xd,%eax
f0100467:	0f 85 9d 00 00 00    	jne    f010050a <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f010046d:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f0100474:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010047a:	c1 e8 16             	shr    $0x16,%eax
f010047d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100480:	c1 e0 04             	shl    $0x4,%eax
f0100483:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010048a:	66 81 bb a0 1f 00 00 	cmpw   $0x7cf,0x1fa0(%ebx)
f0100491:	cf 07 
f0100493:	0f 87 98 00 00 00    	ja     f0100531 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100499:	8b 8b a8 1f 00 00    	mov    0x1fa8(%ebx),%ecx
f010049f:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a4:	89 ca                	mov    %ecx,%edx
f01004a6:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a7:	0f b7 9b a0 1f 00 00 	movzwl 0x1fa0(%ebx),%ebx
f01004ae:	8d 71 01             	lea    0x1(%ecx),%esi
f01004b1:	89 d8                	mov    %ebx,%eax
f01004b3:	66 c1 e8 08          	shr    $0x8,%ax
f01004b7:	89 f2                	mov    %esi,%edx
f01004b9:	ee                   	out    %al,(%dx)
f01004ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bf:	89 ca                	mov    %ecx,%edx
f01004c1:	ee                   	out    %al,(%dx)
f01004c2:	89 d8                	mov    %ebx,%eax
f01004c4:	89 f2                	mov    %esi,%edx
f01004c6:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004ca:	5b                   	pop    %ebx
f01004cb:	5e                   	pop    %esi
f01004cc:	5f                   	pop    %edi
f01004cd:	5d                   	pop    %ebp
f01004ce:	c3                   	ret    
		if (crt_pos > 0) {
f01004cf:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f01004d6:	66 85 c0             	test   %ax,%ax
f01004d9:	74 be                	je     f0100499 <cons_putc+0x135>
			crt_pos--;
f01004db:	83 e8 01             	sub    $0x1,%eax
f01004de:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e5:	0f b7 c0             	movzwl %ax,%eax
f01004e8:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004ec:	b2 00                	mov    $0x0,%dl
f01004ee:	83 ca 20             	or     $0x20,%edx
f01004f1:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f01004f7:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004fb:	eb 8d                	jmp    f010048a <cons_putc+0x126>
		crt_pos += CRT_COLS;
f01004fd:	66 83 83 a0 1f 00 00 	addw   $0x50,0x1fa0(%ebx)
f0100504:	50 
f0100505:	e9 63 ff ff ff       	jmp    f010046d <cons_putc+0x109>
		crt_buf[crt_pos++] = c;		/* write the character */
f010050a:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f0100511:	8d 50 01             	lea    0x1(%eax),%edx
f0100514:	66 89 93 a0 1f 00 00 	mov    %dx,0x1fa0(%ebx)
f010051b:	0f b7 c0             	movzwl %ax,%eax
f010051e:	8b 93 a4 1f 00 00    	mov    0x1fa4(%ebx),%edx
f0100524:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100528:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f010052c:	e9 59 ff ff ff       	jmp    f010048a <cons_putc+0x126>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));	
f0100531:	8b 83 a4 1f 00 00    	mov    0x1fa4(%ebx),%eax
f0100537:	83 ec 04             	sub    $0x4,%esp
f010053a:	68 00 0f 00 00       	push   $0xf00
f010053f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100545:	52                   	push   %edx
f0100546:	50                   	push   %eax
f0100547:	e8 6f 12 00 00       	call   f01017bb <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010054c:	8b 93 a4 1f 00 00    	mov    0x1fa4(%ebx),%edx
f0100552:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100558:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010055e:	83 c4 10             	add    $0x10,%esp
f0100561:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100566:	83 c0 02             	add    $0x2,%eax
f0100569:	39 d0                	cmp    %edx,%eax
f010056b:	75 f4                	jne    f0100561 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f010056d:	66 83 ab a0 1f 00 00 	subw   $0x50,0x1fa0(%ebx)
f0100574:	50 
f0100575:	e9 1f ff ff ff       	jmp    f0100499 <cons_putc+0x135>

f010057a <serial_intr>:
{
f010057a:	e8 cf 01 00 00       	call   f010074e <__x86.get_pc_thunk.ax>
f010057f:	05 89 0d 01 00       	add    $0x10d89,%eax
	if (serial_exists)
f0100584:	80 b8 ac 1f 00 00 00 	cmpb   $0x0,0x1fac(%eax)
f010058b:	75 01                	jne    f010058e <serial_intr+0x14>
f010058d:	c3                   	ret    
{
f010058e:	55                   	push   %ebp
f010058f:	89 e5                	mov    %esp,%ebp
f0100591:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100594:	8d 80 b8 ee fe ff    	lea    -0x11148(%eax),%eax
f010059a:	e8 3b fc ff ff       	call   f01001da <cons_intr>
}
f010059f:	c9                   	leave  
f01005a0:	c3                   	ret    

f01005a1 <kbd_intr>:
{
f01005a1:	55                   	push   %ebp
f01005a2:	89 e5                	mov    %esp,%ebp
f01005a4:	83 ec 08             	sub    $0x8,%esp
f01005a7:	e8 a2 01 00 00       	call   f010074e <__x86.get_pc_thunk.ax>
f01005ac:	05 5c 0d 01 00       	add    $0x10d5c,%eax
	cons_intr(kbd_proc_data);
f01005b1:	8d 80 36 ef fe ff    	lea    -0x110ca(%eax),%eax
f01005b7:	e8 1e fc ff ff       	call   f01001da <cons_intr>
}
f01005bc:	c9                   	leave  
f01005bd:	c3                   	ret    

f01005be <cons_getc>:
{
f01005be:	55                   	push   %ebp
f01005bf:	89 e5                	mov    %esp,%ebp
f01005c1:	53                   	push   %ebx
f01005c2:	83 ec 04             	sub    $0x4,%esp
f01005c5:	e8 f2 fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01005ca:	81 c3 3e 0d 01 00    	add    $0x10d3e,%ebx
	serial_intr();
f01005d0:	e8 a5 ff ff ff       	call   f010057a <serial_intr>
	kbd_intr();
f01005d5:	e8 c7 ff ff ff       	call   f01005a1 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005da:	8b 83 98 1f 00 00    	mov    0x1f98(%ebx),%eax
	return 0;
f01005e0:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f01005e5:	3b 83 9c 1f 00 00    	cmp    0x1f9c(%ebx),%eax
f01005eb:	74 1e                	je     f010060b <cons_getc+0x4d>
		c = cons.buf[cons.rpos++];
f01005ed:	8d 48 01             	lea    0x1(%eax),%ecx
f01005f0:	0f b6 94 03 98 1d 00 	movzbl 0x1d98(%ebx,%eax,1),%edx
f01005f7:	00 
			cons.rpos = 0;
f01005f8:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f01005fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100602:	0f 45 c1             	cmovne %ecx,%eax
f0100605:	89 83 98 1f 00 00    	mov    %eax,0x1f98(%ebx)
}
f010060b:	89 d0                	mov    %edx,%eax
f010060d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
f0100615:	57                   	push   %edi
f0100616:	56                   	push   %esi
f0100617:	53                   	push   %ebx
f0100618:	83 ec 1c             	sub    $0x1c,%esp
f010061b:	e8 9c fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100620:	81 c3 e8 0c 01 00    	add    $0x10ce8,%ebx
	was = *cp;
f0100626:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010062d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100634:	5a a5 
	if (*cp != 0xA55A) {
f0100636:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010063d:	b9 b4 03 00 00       	mov    $0x3b4,%ecx
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100642:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
	if (*cp != 0xA55A) {
f0100647:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010064b:	0f 84 ac 00 00 00    	je     f01006fd <cons_init+0xeb>
		addr_6845 = MONO_BASE;
f0100651:	89 8b a8 1f 00 00    	mov    %ecx,0x1fa8(%ebx)
f0100657:	b8 0e 00 00 00       	mov    $0xe,%eax
f010065c:	89 ca                	mov    %ecx,%edx
f010065e:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010065f:	8d 71 01             	lea    0x1(%ecx),%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100662:	89 f2                	mov    %esi,%edx
f0100664:	ec                   	in     (%dx),%al
f0100665:	0f b6 c0             	movzbl %al,%eax
f0100668:	c1 e0 08             	shl    $0x8,%eax
f010066b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010066e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100673:	89 ca                	mov    %ecx,%edx
f0100675:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100676:	89 f2                	mov    %esi,%edx
f0100678:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100679:	89 bb a4 1f 00 00    	mov    %edi,0x1fa4(%ebx)
	pos |= inb(addr_6845 + 1);
f010067f:	0f b6 c0             	movzbl %al,%eax
f0100682:	0b 45 e4             	or     -0x1c(%ebp),%eax
	crt_pos = pos;
f0100685:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010068c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100691:	89 c8                	mov    %ecx,%eax
f0100693:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100698:	ee                   	out    %al,(%dx)
f0100699:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010069e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a3:	89 fa                	mov    %edi,%edx
f01006a5:	ee                   	out    %al,(%dx)
f01006a6:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006ab:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006b0:	ee                   	out    %al,(%dx)
f01006b1:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006b6:	89 c8                	mov    %ecx,%eax
f01006b8:	89 f2                	mov    %esi,%edx
f01006ba:	ee                   	out    %al,(%dx)
f01006bb:	b8 03 00 00 00       	mov    $0x3,%eax
f01006c0:	89 fa                	mov    %edi,%edx
f01006c2:	ee                   	out    %al,(%dx)
f01006c3:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006c8:	89 c8                	mov    %ecx,%eax
f01006ca:	ee                   	out    %al,(%dx)
f01006cb:	b8 01 00 00 00       	mov    $0x1,%eax
f01006d0:	89 f2                	mov    %esi,%edx
f01006d2:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006d8:	ec                   	in     (%dx),%al
f01006d9:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006db:	3c ff                	cmp    $0xff,%al
f01006dd:	0f 95 83 ac 1f 00 00 	setne  0x1fac(%ebx)
f01006e4:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006e9:	ec                   	in     (%dx),%al
f01006ea:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006ef:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006f0:	80 f9 ff             	cmp    $0xff,%cl
f01006f3:	74 1e                	je     f0100713 <cons_init+0x101>
		cprintf("Serial port does not exist!\n");
}
f01006f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006f8:	5b                   	pop    %ebx
f01006f9:	5e                   	pop    %esi
f01006fa:	5f                   	pop    %edi
f01006fb:	5d                   	pop    %ebp
f01006fc:	c3                   	ret    
		*cp = was;
f01006fd:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
f0100704:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100709:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
f010070e:	e9 3e ff ff ff       	jmp    f0100651 <cons_init+0x3f>
		cprintf("Serial port does not exist!\n");
f0100713:	83 ec 0c             	sub    $0xc,%esp
f0100716:	8d 83 48 09 ff ff    	lea    -0xf6b8(%ebx),%eax
f010071c:	50                   	push   %eax
f010071d:	e8 bb 03 00 00       	call   f0100add <cprintf>
f0100722:	83 c4 10             	add    $0x10,%esp
}
f0100725:	eb ce                	jmp    f01006f5 <cons_init+0xe3>

f0100727 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100727:	55                   	push   %ebp
f0100728:	89 e5                	mov    %esp,%ebp
f010072a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010072d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100730:	e8 2f fc ff ff       	call   f0100364 <cons_putc>
}
f0100735:	c9                   	leave  
f0100736:	c3                   	ret    

f0100737 <getchar>:

int
getchar(void)
{
f0100737:	55                   	push   %ebp
f0100738:	89 e5                	mov    %esp,%ebp
f010073a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010073d:	e8 7c fe ff ff       	call   f01005be <cons_getc>
f0100742:	85 c0                	test   %eax,%eax
f0100744:	74 f7                	je     f010073d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100746:	c9                   	leave  
f0100747:	c3                   	ret    

f0100748 <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f0100748:	b8 01 00 00 00       	mov    $0x1,%eax
f010074d:	c3                   	ret    

f010074e <__x86.get_pc_thunk.ax>:
f010074e:	8b 04 24             	mov    (%esp),%eax
f0100751:	c3                   	ret    

f0100752 <__x86.get_pc_thunk.si>:
f0100752:	8b 34 24             	mov    (%esp),%esi
f0100755:	c3                   	ret    

f0100756 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100756:	55                   	push   %ebp
f0100757:	89 e5                	mov    %esp,%ebp
f0100759:	56                   	push   %esi
f010075a:	53                   	push   %ebx
f010075b:	e8 5c fa ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100760:	81 c3 a8 0b 01 00    	add    $0x10ba8,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100766:	83 ec 04             	sub    $0x4,%esp
f0100769:	8d 83 78 0b ff ff    	lea    -0xf488(%ebx),%eax
f010076f:	50                   	push   %eax
f0100770:	8d 83 96 0b ff ff    	lea    -0xf46a(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	8d b3 9b 0b ff ff    	lea    -0xf465(%ebx),%esi
f010077d:	56                   	push   %esi
f010077e:	e8 5a 03 00 00       	call   f0100add <cprintf>
f0100783:	83 c4 0c             	add    $0xc,%esp
f0100786:	8d 83 40 0c ff ff    	lea    -0xf3c0(%ebx),%eax
f010078c:	50                   	push   %eax
f010078d:	8d 83 a4 0b ff ff    	lea    -0xf45c(%ebx),%eax
f0100793:	50                   	push   %eax
f0100794:	56                   	push   %esi
f0100795:	e8 43 03 00 00       	call   f0100add <cprintf>
f010079a:	83 c4 0c             	add    $0xc,%esp
f010079d:	8d 83 ad 0b ff ff    	lea    -0xf453(%ebx),%eax
f01007a3:	50                   	push   %eax
f01007a4:	8d 83 bb 0b ff ff    	lea    -0xf445(%ebx),%eax
f01007aa:	50                   	push   %eax
f01007ab:	56                   	push   %esi
f01007ac:	e8 2c 03 00 00       	call   f0100add <cprintf>
	return 0;
}
f01007b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007b9:	5b                   	pop    %ebx
f01007ba:	5e                   	pop    %esi
f01007bb:	5d                   	pop    %ebp
f01007bc:	c3                   	ret    

f01007bd <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007bd:	55                   	push   %ebp
f01007be:	89 e5                	mov    %esp,%ebp
f01007c0:	57                   	push   %edi
f01007c1:	56                   	push   %esi
f01007c2:	53                   	push   %ebx
f01007c3:	83 ec 18             	sub    $0x18,%esp
f01007c6:	e8 f1 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01007cb:	81 c3 3d 0b 01 00    	add    $0x10b3d,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d1:	8d 83 c5 0b ff ff    	lea    -0xf43b(%ebx),%eax
f01007d7:	50                   	push   %eax
f01007d8:	e8 00 03 00 00       	call   f0100add <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007dd:	83 c4 08             	add    $0x8,%esp
f01007e0:	ff b3 f8 ff ff ff    	push   -0x8(%ebx)
f01007e6:	8d 83 68 0c ff ff    	lea    -0xf398(%ebx),%eax
f01007ec:	50                   	push   %eax
f01007ed:	e8 eb 02 00 00       	call   f0100add <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f2:	83 c4 0c             	add    $0xc,%esp
f01007f5:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007fb:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100801:	50                   	push   %eax
f0100802:	57                   	push   %edi
f0100803:	8d 83 90 0c ff ff    	lea    -0xf370(%ebx),%eax
f0100809:	50                   	push   %eax
f010080a:	e8 ce 02 00 00       	call   f0100add <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	c7 c0 a1 1b 10 f0    	mov    $0xf0101ba1,%eax
f0100818:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010081e:	52                   	push   %edx
f010081f:	50                   	push   %eax
f0100820:	8d 83 b4 0c ff ff    	lea    -0xf34c(%ebx),%eax
f0100826:	50                   	push   %eax
f0100827:	e8 b1 02 00 00       	call   f0100add <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082c:	83 c4 0c             	add    $0xc,%esp
f010082f:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100835:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010083b:	52                   	push   %edx
f010083c:	50                   	push   %eax
f010083d:	8d 83 d8 0c ff ff    	lea    -0xf328(%ebx),%eax
f0100843:	50                   	push   %eax
f0100844:	e8 94 02 00 00       	call   f0100add <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100849:	83 c4 0c             	add    $0xc,%esp
f010084c:	c7 c6 c0 36 11 f0    	mov    $0xf01136c0,%esi
f0100852:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100858:	50                   	push   %eax
f0100859:	56                   	push   %esi
f010085a:	8d 83 fc 0c ff ff    	lea    -0xf304(%ebx),%eax
f0100860:	50                   	push   %eax
f0100861:	e8 77 02 00 00       	call   f0100add <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100866:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100869:	29 fe                	sub    %edi,%esi
f010086b:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100871:	c1 fe 0a             	sar    $0xa,%esi
f0100874:	56                   	push   %esi
f0100875:	8d 83 20 0d ff ff    	lea    -0xf2e0(%ebx),%eax
f010087b:	50                   	push   %eax
f010087c:	e8 5c 02 00 00       	call   f0100add <cprintf>
	return 0;
}
f0100881:	b8 00 00 00 00       	mov    $0x0,%eax
f0100886:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100889:	5b                   	pop    %ebx
f010088a:	5e                   	pop    %esi
f010088b:	5f                   	pop    %edi
f010088c:	5d                   	pop    %ebp
f010088d:	c3                   	ret    

f010088e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010088e:	55                   	push   %ebp
f010088f:	89 e5                	mov    %esp,%ebp
f0100891:	57                   	push   %edi
f0100892:	56                   	push   %esi
f0100893:	53                   	push   %ebx
f0100894:	83 ec 48             	sub    $0x48,%esp
f0100897:	e8 20 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010089c:	81 c3 6c 0a 01 00    	add    $0x10a6c,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a2:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp = (uint32_t *)read_ebp();	//base pointer
f01008a4:	89 c6                	mov    %eax,%esi
	uint32_t eip = ebp[1];  //eip is the second element of the stack frame. The first element is the return address of the caller
f01008a6:	8b 78 04             	mov    0x4(%eax),%edi
	cprintf("Stack backtrace:\n");
f01008a9:	8d 83 de 0b ff ff    	lea    -0xf422(%ebx),%eax
f01008af:	50                   	push   %eax
f01008b0:	e8 28 02 00 00       	call   f0100add <cprintf>
f01008b5:	83 c4 10             	add    $0x10,%esp
	struct Eipdebuginfo info;

	while(ebp != 0){
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\r \n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);	//print the stack frame - ebp, eip, and the first 5 arguments
f01008b8:	8d 83 4c 0d ff ff    	lea    -0xf2b4(%ebx),%eax
f01008be:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		//print the function name
		debuginfo_eip(eip, &info);		//as the name suggest!
		//prints the file name, line number, function name, and offset
		cprintf("\t%s:%d: %.*s+%d\r \n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01008c1:	8d 83 f0 0b ff ff    	lea    -0xf410(%ebx),%eax
f01008c7:	89 45 c0             	mov    %eax,-0x40(%ebp)
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\r \n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);	//print the stack frame - ebp, eip, and the first 5 arguments
f01008ca:	ff 76 18             	push   0x18(%esi)
f01008cd:	ff 76 14             	push   0x14(%esi)
f01008d0:	ff 76 10             	push   0x10(%esi)
f01008d3:	ff 76 0c             	push   0xc(%esi)
f01008d6:	ff 76 08             	push   0x8(%esi)
f01008d9:	57                   	push   %edi
f01008da:	56                   	push   %esi
f01008db:	ff 75 c4             	push   -0x3c(%ebp)
f01008de:	e8 fa 01 00 00       	call   f0100add <cprintf>
		debuginfo_eip(eip, &info);		//as the name suggest!
f01008e3:	83 c4 18             	add    $0x18,%esp
f01008e6:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008e9:	50                   	push   %eax
f01008ea:	57                   	push   %edi
f01008eb:	e8 f6 02 00 00       	call   f0100be6 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\r \n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01008f0:	83 c4 08             	add    $0x8,%esp
f01008f3:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01008f6:	57                   	push   %edi
f01008f7:	ff 75 d8             	push   -0x28(%ebp)
f01008fa:	ff 75 dc             	push   -0x24(%ebp)
f01008fd:	ff 75 d4             	push   -0x2c(%ebp)
f0100900:	ff 75 d0             	push   -0x30(%ebp)
f0100903:	ff 75 c0             	push   -0x40(%ebp)
f0100906:	e8 d2 01 00 00       	call   f0100add <cprintf>
		ebp = (uint32_t *)*ebp;		//move to the next stack frame
f010090b:	8b 36                	mov    (%esi),%esi
		eip = ebp[1];	//update eip - without this, the eip will be the same as the previous stack frame (we dn't want that)
f010090d:	8b 7e 04             	mov    0x4(%esi),%edi
	while(ebp != 0){
f0100910:	83 c4 20             	add    $0x20,%esp
f0100913:	85 f6                	test   %esi,%esi
f0100915:	75 b3                	jne    f01008ca <mon_backtrace+0x3c>
	}
	return 0;
}
f0100917:	b8 00 00 00 00       	mov    $0x0,%eax
f010091c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010091f:	5b                   	pop    %ebx
f0100920:	5e                   	pop    %esi
f0100921:	5f                   	pop    %edi
f0100922:	5d                   	pop    %ebp
f0100923:	c3                   	ret    

f0100924 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100924:	55                   	push   %ebp
f0100925:	89 e5                	mov    %esp,%ebp
f0100927:	57                   	push   %edi
f0100928:	56                   	push   %esi
f0100929:	53                   	push   %ebx
f010092a:	83 ec 68             	sub    $0x68,%esp
f010092d:	e8 8a f8 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100932:	81 c3 d6 09 01 00    	add    $0x109d6,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100938:	8d 83 80 0d ff ff    	lea    -0xf280(%ebx),%eax
f010093e:	50                   	push   %eax
f010093f:	e8 99 01 00 00       	call   f0100add <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100944:	8d 83 a4 0d ff ff    	lea    -0xf25c(%ebx),%eax
f010094a:	89 04 24             	mov    %eax,(%esp)
f010094d:	e8 8b 01 00 00       	call   f0100add <cprintf>
f0100952:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100955:	8d bb 07 0c ff ff    	lea    -0xf3f9(%ebx),%edi
f010095b:	eb 4a                	jmp    f01009a7 <monitor+0x83>
f010095d:	83 ec 08             	sub    $0x8,%esp
f0100960:	0f be c0             	movsbl %al,%eax
f0100963:	50                   	push   %eax
f0100964:	57                   	push   %edi
f0100965:	e8 cc 0d 00 00       	call   f0101736 <strchr>
f010096a:	83 c4 10             	add    $0x10,%esp
f010096d:	85 c0                	test   %eax,%eax
f010096f:	74 08                	je     f0100979 <monitor+0x55>
			*buf++ = 0;
f0100971:	c6 06 00             	movb   $0x0,(%esi)
f0100974:	8d 76 01             	lea    0x1(%esi),%esi
f0100977:	eb 76                	jmp    f01009ef <monitor+0xcb>
		if (*buf == 0)
f0100979:	80 3e 00             	cmpb   $0x0,(%esi)
f010097c:	74 7c                	je     f01009fa <monitor+0xd6>
		if (argc == MAXARGS-1) {
f010097e:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100982:	74 0f                	je     f0100993 <monitor+0x6f>
		argv[argc++] = buf;
f0100984:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100987:	8d 48 01             	lea    0x1(%eax),%ecx
f010098a:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010098d:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100991:	eb 41                	jmp    f01009d4 <monitor+0xb0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100993:	83 ec 08             	sub    $0x8,%esp
f0100996:	6a 10                	push   $0x10
f0100998:	8d 83 0c 0c ff ff    	lea    -0xf3f4(%ebx),%eax
f010099e:	50                   	push   %eax
f010099f:	e8 39 01 00 00       	call   f0100add <cprintf>
			return 0;
f01009a4:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009a7:	8d 83 03 0c ff ff    	lea    -0xf3fd(%ebx),%eax
f01009ad:	89 c6                	mov    %eax,%esi
f01009af:	83 ec 0c             	sub    $0xc,%esp
f01009b2:	56                   	push   %esi
f01009b3:	e8 2d 0b 00 00       	call   f01014e5 <readline>
		if (buf != NULL)
f01009b8:	83 c4 10             	add    $0x10,%esp
f01009bb:	85 c0                	test   %eax,%eax
f01009bd:	74 f0                	je     f01009af <monitor+0x8b>
	argv[argc] = 0;
f01009bf:	89 c6                	mov    %eax,%esi
f01009c1:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009c8:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009cf:	eb 1e                	jmp    f01009ef <monitor+0xcb>
			buf++;
f01009d1:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009d4:	0f b6 06             	movzbl (%esi),%eax
f01009d7:	84 c0                	test   %al,%al
f01009d9:	74 14                	je     f01009ef <monitor+0xcb>
f01009db:	83 ec 08             	sub    $0x8,%esp
f01009de:	0f be c0             	movsbl %al,%eax
f01009e1:	50                   	push   %eax
f01009e2:	57                   	push   %edi
f01009e3:	e8 4e 0d 00 00       	call   f0101736 <strchr>
f01009e8:	83 c4 10             	add    $0x10,%esp
f01009eb:	85 c0                	test   %eax,%eax
f01009ed:	74 e2                	je     f01009d1 <monitor+0xad>
		while (*buf && strchr(WHITESPACE, *buf))
f01009ef:	0f b6 06             	movzbl (%esi),%eax
f01009f2:	84 c0                	test   %al,%al
f01009f4:	0f 85 63 ff ff ff    	jne    f010095d <monitor+0x39>
	argv[argc] = 0;
f01009fa:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009fd:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a04:	00 
	if (argc == 0)
f0100a05:	85 c0                	test   %eax,%eax
f0100a07:	74 9e                	je     f01009a7 <monitor+0x83>
f0100a09:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a14:	89 7d a0             	mov    %edi,-0x60(%ebp)
f0100a17:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a19:	83 ec 08             	sub    $0x8,%esp
f0100a1c:	ff 36                	push   (%esi)
f0100a1e:	ff 75 a8             	push   -0x58(%ebp)
f0100a21:	e8 b0 0c 00 00       	call   f01016d6 <strcmp>
f0100a26:	83 c4 10             	add    $0x10,%esp
f0100a29:	85 c0                	test   %eax,%eax
f0100a2b:	74 28                	je     f0100a55 <monitor+0x131>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a2d:	83 c7 01             	add    $0x1,%edi
f0100a30:	83 c6 0c             	add    $0xc,%esi
f0100a33:	83 ff 03             	cmp    $0x3,%edi
f0100a36:	75 e1                	jne    f0100a19 <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a38:	8b 7d a0             	mov    -0x60(%ebp),%edi
f0100a3b:	83 ec 08             	sub    $0x8,%esp
f0100a3e:	ff 75 a8             	push   -0x58(%ebp)
f0100a41:	8d 83 29 0c ff ff    	lea    -0xf3d7(%ebx),%eax
f0100a47:	50                   	push   %eax
f0100a48:	e8 90 00 00 00       	call   f0100add <cprintf>
	return 0;
f0100a4d:	83 c4 10             	add    $0x10,%esp
f0100a50:	e9 52 ff ff ff       	jmp    f01009a7 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a55:	89 f8                	mov    %edi,%eax
f0100a57:	8b 7d a0             	mov    -0x60(%ebp),%edi
f0100a5a:	83 ec 04             	sub    $0x4,%esp
f0100a5d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a60:	ff 75 08             	push   0x8(%ebp)
f0100a63:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a66:	52                   	push   %edx
f0100a67:	ff 75 a4             	push   -0x5c(%ebp)
f0100a6a:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a71:	83 c4 10             	add    $0x10,%esp
f0100a74:	85 c0                	test   %eax,%eax
f0100a76:	0f 89 2b ff ff ff    	jns    f01009a7 <monitor+0x83>
				break;
	}
}
f0100a7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a7f:	5b                   	pop    %ebx
f0100a80:	5e                   	pop    %esi
f0100a81:	5f                   	pop    %edi
f0100a82:	5d                   	pop    %ebp
f0100a83:	c3                   	ret    

f0100a84 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a84:	55                   	push   %ebp
f0100a85:	89 e5                	mov    %esp,%ebp
f0100a87:	53                   	push   %ebx
f0100a88:	83 ec 10             	sub    $0x10,%esp
f0100a8b:	e8 2c f7 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100a90:	81 c3 78 08 01 00    	add    $0x10878,%ebx
	cputchar(ch);
f0100a96:	ff 75 08             	push   0x8(%ebp)
f0100a99:	e8 89 fc ff ff       	call   f0100727 <cputchar>
	*cnt++;
}
f0100a9e:	83 c4 10             	add    $0x10,%esp
f0100aa1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aa4:	c9                   	leave  
f0100aa5:	c3                   	ret    

f0100aa6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100aa6:	55                   	push   %ebp
f0100aa7:	89 e5                	mov    %esp,%ebp
f0100aa9:	53                   	push   %ebx
f0100aaa:	83 ec 14             	sub    $0x14,%esp
f0100aad:	e8 0a f7 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100ab2:	81 c3 56 08 01 00    	add    $0x10856,%ebx
	int cnt = 0;
f0100ab8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100abf:	ff 75 0c             	push   0xc(%ebp)
f0100ac2:	ff 75 08             	push   0x8(%ebp)
f0100ac5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ac8:	50                   	push   %eax
f0100ac9:	8d 83 7c f7 fe ff    	lea    -0x10884(%ebx),%eax
f0100acf:	50                   	push   %eax
f0100ad0:	e8 5f 04 00 00       	call   f0100f34 <vprintfmt>
	//this function takes a format string and a va_list of arguments, formats the string using vprintfmt(), and outputs it to the console using the putch() function, which ultimately calls cputchar().
	return cnt;
}
f0100ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ad8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100adb:	c9                   	leave  
f0100adc:	c3                   	ret    

f0100add <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100add:	55                   	push   %ebp
f0100ade:	89 e5                	mov    %esp,%ebp
f0100ae0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ae3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100ae6:	50                   	push   %eax
f0100ae7:	ff 75 08             	push   0x8(%ebp)
f0100aea:	e8 b7 ff ff ff       	call   f0100aa6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100aef:	c9                   	leave  
f0100af0:	c3                   	ret    

f0100af1 <stab_binsearch>:
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)

{
f0100af1:	55                   	push   %ebp
f0100af2:	89 e5                	mov    %esp,%ebp
f0100af4:	57                   	push   %edi
f0100af5:	56                   	push   %esi
f0100af6:	53                   	push   %ebx
f0100af7:	83 ec 14             	sub    $0x14,%esp
f0100afa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100afd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b00:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b03:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b06:	8b 1a                	mov    (%edx),%ebx
f0100b08:	8b 01                	mov    (%ecx),%eax
f0100b0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b0d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b14:	eb 2f                	jmp    f0100b45 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b16:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b19:	39 c3                	cmp    %eax,%ebx
f0100b1b:	7f 4e                	jg     f0100b6b <stab_binsearch+0x7a>
f0100b1d:	0f b6 0a             	movzbl (%edx),%ecx
f0100b20:	83 ea 0c             	sub    $0xc,%edx
f0100b23:	39 f1                	cmp    %esi,%ecx
f0100b25:	75 ef                	jne    f0100b16 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b27:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b2a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b2d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b31:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b34:	73 3a                	jae    f0100b70 <stab_binsearch+0x7f>
			*region_left = m;
f0100b36:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b39:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100b3b:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0100b3e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b45:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b48:	7f 53                	jg     f0100b9d <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0100b4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b4d:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0100b50:	89 d0                	mov    %edx,%eax
f0100b52:	c1 e8 1f             	shr    $0x1f,%eax
f0100b55:	01 d0                	add    %edx,%eax
f0100b57:	89 c7                	mov    %eax,%edi
f0100b59:	d1 ff                	sar    %edi
f0100b5b:	83 e0 fe             	and    $0xfffffffe,%eax
f0100b5e:	01 f8                	add    %edi,%eax
f0100b60:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b63:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100b67:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b69:	eb ae                	jmp    f0100b19 <stab_binsearch+0x28>
			l = true_m + 1;
f0100b6b:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100b6e:	eb d5                	jmp    f0100b45 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100b70:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b73:	76 14                	jbe    f0100b89 <stab_binsearch+0x98>
			*region_right = m - 1;
f0100b75:	83 e8 01             	sub    $0x1,%eax
f0100b78:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b7b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b7e:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0100b80:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b87:	eb bc                	jmp    f0100b45 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b89:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b8c:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100b8e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b92:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0100b94:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b9b:	eb a8                	jmp    f0100b45 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b9d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100ba1:	75 15                	jne    f0100bb8 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0100ba3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba6:	8b 00                	mov    (%eax),%eax
f0100ba8:	83 e8 01             	sub    $0x1,%eax
f0100bab:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100bae:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100bb0:	83 c4 14             	add    $0x14,%esp
f0100bb3:	5b                   	pop    %ebx
f0100bb4:	5e                   	pop    %esi
f0100bb5:	5f                   	pop    %edi
f0100bb6:	5d                   	pop    %ebp
f0100bb7:	c3                   	ret    
		for (l = *region_right;
f0100bb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bbb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bc0:	8b 0f                	mov    (%edi),%ecx
f0100bc2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bc5:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100bc8:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0100bcc:	39 c1                	cmp    %eax,%ecx
f0100bce:	7d 0f                	jge    f0100bdf <stab_binsearch+0xee>
f0100bd0:	0f b6 1a             	movzbl (%edx),%ebx
f0100bd3:	83 ea 0c             	sub    $0xc,%edx
f0100bd6:	39 f3                	cmp    %esi,%ebx
f0100bd8:	74 05                	je     f0100bdf <stab_binsearch+0xee>
		     l--)
f0100bda:	83 e8 01             	sub    $0x1,%eax
f0100bdd:	eb ed                	jmp    f0100bcc <stab_binsearch+0xdb>
		*region_left = l;
f0100bdf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100be2:	89 07                	mov    %eax,(%edi)
}
f0100be4:	eb ca                	jmp    f0100bb0 <stab_binsearch+0xbf>

f0100be6 <debuginfo_eip>:
//


int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100be6:	55                   	push   %ebp
f0100be7:	89 e5                	mov    %esp,%ebp
f0100be9:	57                   	push   %edi
f0100bea:	56                   	push   %esi
f0100beb:	53                   	push   %ebx
f0100bec:	83 ec 3c             	sub    $0x3c,%esp
f0100bef:	e8 c8 f5 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100bf4:	81 c3 14 07 01 00    	add    $0x10714,%ebx
f0100bfa:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bfd:	8d 83 c9 0d ff ff    	lea    -0xf237(%ebx),%eax
f0100c03:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100c05:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100c0c:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100c0f:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100c16:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c19:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f0100c1c:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c23:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0100c28:	0f 86 3e 01 00 00    	jbe    f0100d6c <debuginfo_eip+0x186>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c2e:	c7 c0 75 5b 10 f0    	mov    $0xf0105b75,%eax
f0100c34:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100c3a:	0f 86 d3 01 00 00    	jbe    f0100e13 <debuginfo_eip+0x22d>
f0100c40:	c7 c0 9d 71 10 f0    	mov    $0xf010719d,%eax
f0100c46:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c4a:	0f 85 ca 01 00 00    	jne    f0100e1a <debuginfo_eip+0x234>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c50:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c57:	c7 c0 ec 22 10 f0    	mov    $0xf01022ec,%eax
f0100c5d:	c7 c2 74 5b 10 f0    	mov    $0xf0105b74,%edx
f0100c63:	29 c2                	sub    %eax,%edx
f0100c65:	c1 fa 02             	sar    $0x2,%edx
f0100c68:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100c6e:	83 ea 01             	sub    $0x1,%edx
f0100c71:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c74:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c77:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c7a:	83 ec 08             	sub    $0x8,%esp
f0100c7d:	ff 75 08             	push   0x8(%ebp)
f0100c80:	6a 64                	push   $0x64
f0100c82:	e8 6a fe ff ff       	call   f0100af1 <stab_binsearch>
	if (lfile == 0)
f0100c87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c8a:	83 c4 10             	add    $0x10,%esp
f0100c8d:	85 ff                	test   %edi,%edi
f0100c8f:	0f 84 8c 01 00 00    	je     f0100e21 <debuginfo_eip+0x23b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c95:	89 7d dc             	mov    %edi,-0x24(%ebp)
	rfun = rfile;
f0100c98:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c9b:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0100c9e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ca1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ca4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ca7:	83 ec 08             	sub    $0x8,%esp
f0100caa:	ff 75 08             	push   0x8(%ebp)
f0100cad:	6a 24                	push   $0x24
f0100caf:	c7 c0 ec 22 10 f0    	mov    $0xf01022ec,%eax
f0100cb5:	e8 37 fe ff ff       	call   f0100af1 <stab_binsearch>

	if (lfun <= rfun) {
f0100cba:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100cbd:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0100cc0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100cc3:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0100cc6:	83 c4 10             	add    $0x10,%esp
f0100cc9:	89 f8                	mov    %edi,%eax
f0100ccb:	39 d1                	cmp    %edx,%ecx
f0100ccd:	7f 39                	jg     f0100d08 <debuginfo_eip+0x122>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ccf:	8d 04 49             	lea    (%ecx,%ecx,2),%eax
f0100cd2:	c7 c2 ec 22 10 f0    	mov    $0xf01022ec,%edx
f0100cd8:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100cdb:	8b 11                	mov    (%ecx),%edx
f0100cdd:	c7 c0 9d 71 10 f0    	mov    $0xf010719d,%eax
f0100ce3:	81 e8 75 5b 10 f0    	sub    $0xf0105b75,%eax
f0100ce9:	39 c2                	cmp    %eax,%edx
f0100ceb:	73 09                	jae    f0100cf6 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ced:	81 c2 75 5b 10 f0    	add    $0xf0105b75,%edx
f0100cf3:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100cf6:	8b 41 08             	mov    0x8(%ecx),%eax
f0100cf9:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100cfc:	29 45 08             	sub    %eax,0x8(%ebp)
f0100cff:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0100d02:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0100d05:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0100d08:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d0b:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100d0e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d11:	83 ec 08             	sub    $0x8,%esp
f0100d14:	6a 3a                	push   $0x3a
f0100d16:	ff 76 08             	push   0x8(%esi)
f0100d19:	e8 3b 0a 00 00       	call   f0101759 <strfind>
f0100d1e:	2b 46 08             	sub    0x8(%esi),%eax
f0100d21:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);		// N_SLINE is the type for line numbers in stabs - as mentioned in the header file
f0100d24:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d27:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d2a:	83 c4 08             	add    $0x8,%esp
f0100d2d:	ff 75 08             	push   0x8(%ebp)
f0100d30:	6a 44                	push   $0x44
f0100d32:	c7 c0 ec 22 10 f0    	mov    $0xf01022ec,%eax
f0100d38:	e8 b4 fd ff ff       	call   f0100af1 <stab_binsearch>
		if (lline <= rline) {										// if the line number is found
f0100d3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d40:	83 c4 10             	add    $0x10,%esp
f0100d43:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100d46:	0f 8f dc 00 00 00    	jg     f0100e28 <debuginfo_eip+0x242>
				info->eip_line = stabs[lline].n_desc;				// n_desc is the line number in the stab and is stored in the stabs structure - in this line we are storing the line number in the eip_line variable
f0100d4c:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0100d4f:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100d52:	c7 c0 ec 22 10 f0    	mov    $0xf01022ec,%eax
f0100d58:	0f b7 54 88 06       	movzwl 0x6(%eax,%ecx,4),%edx
f0100d5d:	89 56 04             	mov    %edx,0x4(%esi)
f0100d60:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax
f0100d64:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100d67:	89 75 0c             	mov    %esi,0xc(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d6a:	eb 21                	jmp    f0100d8d <debuginfo_eip+0x1a7>
  	        panic("User address");
f0100d6c:	83 ec 04             	sub    $0x4,%esp
f0100d6f:	8d 83 d3 0d ff ff    	lea    -0xf22d(%ebx),%eax
f0100d75:	50                   	push   %eax
f0100d76:	68 81 00 00 00       	push   $0x81
f0100d7b:	8d 83 e0 0d ff ff    	lea    -0xf220(%ebx),%eax
f0100d81:	50                   	push   %eax
f0100d82:	e8 7f f3 ff ff       	call   f0100106 <_panic>
f0100d87:	83 ea 01             	sub    $0x1,%edx
f0100d8a:	83 e8 0c             	sub    $0xc,%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d8d:	39 d7                	cmp    %edx,%edi
f0100d8f:	7f 3c                	jg     f0100dcd <debuginfo_eip+0x1e7>
	       && stabs[lline].n_type != N_SOL
f0100d91:	0f b6 08             	movzbl (%eax),%ecx
f0100d94:	80 f9 84             	cmp    $0x84,%cl
f0100d97:	74 0b                	je     f0100da4 <debuginfo_eip+0x1be>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d99:	80 f9 64             	cmp    $0x64,%cl
f0100d9c:	75 e9                	jne    f0100d87 <debuginfo_eip+0x1a1>
f0100d9e:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100da2:	74 e3                	je     f0100d87 <debuginfo_eip+0x1a1>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100da4:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100da7:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100daa:	c7 c0 ec 22 10 f0    	mov    $0xf01022ec,%eax
f0100db0:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100db3:	c7 c0 9d 71 10 f0    	mov    $0xf010719d,%eax
f0100db9:	81 e8 75 5b 10 f0    	sub    $0xf0105b75,%eax
f0100dbf:	39 c2                	cmp    %eax,%edx
f0100dc1:	73 0d                	jae    f0100dd0 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100dc3:	81 c2 75 5b 10 f0    	add    $0xf0105b75,%edx
f0100dc9:	89 16                	mov    %edx,(%esi)
f0100dcb:	eb 03                	jmp    f0100dd0 <debuginfo_eip+0x1ea>
f0100dcd:	8b 75 0c             	mov    0xc(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dd0:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100dd5:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100dd8:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0100ddb:	39 cf                	cmp    %ecx,%edi
f0100ddd:	7d 55                	jge    f0100e34 <debuginfo_eip+0x24e>
		for (lline = lfun + 1;
f0100ddf:	83 c7 01             	add    $0x1,%edi
f0100de2:	89 f8                	mov    %edi,%eax
f0100de4:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0100de7:	c7 c2 ec 22 10 f0    	mov    $0xf01022ec,%edx
f0100ded:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100df1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100df4:	eb 04                	jmp    f0100dfa <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0100df6:	83 46 14 01          	addl   $0x1,0x14(%esi)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dfa:	39 c3                	cmp    %eax,%ebx
f0100dfc:	7e 31                	jle    f0100e2f <debuginfo_eip+0x249>
f0100dfe:	0f b6 0a             	movzbl (%edx),%ecx
f0100e01:	83 c0 01             	add    $0x1,%eax
f0100e04:	83 c2 0c             	add    $0xc,%edx
f0100e07:	80 f9 a0             	cmp    $0xa0,%cl
f0100e0a:	74 ea                	je     f0100df6 <debuginfo_eip+0x210>
	return 0;
f0100e0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e11:	eb 21                	jmp    f0100e34 <debuginfo_eip+0x24e>
		return -1;
f0100e13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e18:	eb 1a                	jmp    f0100e34 <debuginfo_eip+0x24e>
f0100e1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e1f:	eb 13                	jmp    f0100e34 <debuginfo_eip+0x24e>
		return -1;
f0100e21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e26:	eb 0c                	jmp    f0100e34 <debuginfo_eip+0x24e>
				return -1;											// if the line number is not found, return -1
f0100e28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e2d:	eb 05                	jmp    f0100e34 <debuginfo_eip+0x24e>
	return 0;
f0100e2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e34:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e37:	5b                   	pop    %ebx
f0100e38:	5e                   	pop    %esi
f0100e39:	5f                   	pop    %edi
f0100e3a:	5d                   	pop    %ebp
f0100e3b:	c3                   	ret    

f0100e3c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e3c:	55                   	push   %ebp
f0100e3d:	89 e5                	mov    %esp,%ebp
f0100e3f:	57                   	push   %edi
f0100e40:	56                   	push   %esi
f0100e41:	53                   	push   %ebx
f0100e42:	83 ec 2c             	sub    $0x2c,%esp
f0100e45:	e8 97 06 00 00       	call   f01014e1 <__x86.get_pc_thunk.cx>
f0100e4a:	81 c1 be 04 01 00    	add    $0x104be,%ecx
f0100e50:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100e53:	89 c7                	mov    %eax,%edi
f0100e55:	89 d6                	mov    %edx,%esi
f0100e57:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e5d:	89 d1                	mov    %edx,%ecx
f0100e5f:	89 c2                	mov    %eax,%edx
f0100e61:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e64:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100e67:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e6a:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e70:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100e77:	39 c2                	cmp    %eax,%edx
f0100e79:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0100e7c:	72 41                	jb     f0100ebf <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e7e:	83 ec 0c             	sub    $0xc,%esp
f0100e81:	ff 75 18             	push   0x18(%ebp)
f0100e84:	83 eb 01             	sub    $0x1,%ebx
f0100e87:	53                   	push   %ebx
f0100e88:	50                   	push   %eax
f0100e89:	83 ec 08             	sub    $0x8,%esp
f0100e8c:	ff 75 e4             	push   -0x1c(%ebp)
f0100e8f:	ff 75 e0             	push   -0x20(%ebp)
f0100e92:	ff 75 d4             	push   -0x2c(%ebp)
f0100e95:	ff 75 d0             	push   -0x30(%ebp)
f0100e98:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e9b:	e8 d0 0a 00 00       	call   f0101970 <__udivdi3>
f0100ea0:	83 c4 18             	add    $0x18,%esp
f0100ea3:	52                   	push   %edx
f0100ea4:	50                   	push   %eax
f0100ea5:	89 f2                	mov    %esi,%edx
f0100ea7:	89 f8                	mov    %edi,%eax
f0100ea9:	e8 8e ff ff ff       	call   f0100e3c <printnum>
f0100eae:	83 c4 20             	add    $0x20,%esp
f0100eb1:	eb 13                	jmp    f0100ec6 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100eb3:	83 ec 08             	sub    $0x8,%esp
f0100eb6:	56                   	push   %esi
f0100eb7:	ff 75 18             	push   0x18(%ebp)
f0100eba:	ff d7                	call   *%edi
f0100ebc:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100ebf:	83 eb 01             	sub    $0x1,%ebx
f0100ec2:	85 db                	test   %ebx,%ebx
f0100ec4:	7f ed                	jg     f0100eb3 <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ec6:	83 ec 08             	sub    $0x8,%esp
f0100ec9:	56                   	push   %esi
f0100eca:	83 ec 04             	sub    $0x4,%esp
f0100ecd:	ff 75 e4             	push   -0x1c(%ebp)
f0100ed0:	ff 75 e0             	push   -0x20(%ebp)
f0100ed3:	ff 75 d4             	push   -0x2c(%ebp)
f0100ed6:	ff 75 d0             	push   -0x30(%ebp)
f0100ed9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100edc:	e8 af 0b 00 00       	call   f0101a90 <__umoddi3>
f0100ee1:	83 c4 14             	add    $0x14,%esp
f0100ee4:	0f be 84 03 ee 0d ff 	movsbl -0xf212(%ebx,%eax,1),%eax
f0100eeb:	ff 
f0100eec:	50                   	push   %eax
f0100eed:	ff d7                	call   *%edi
}
f0100eef:	83 c4 10             	add    $0x10,%esp
f0100ef2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ef5:	5b                   	pop    %ebx
f0100ef6:	5e                   	pop    %esi
f0100ef7:	5f                   	pop    %edi
f0100ef8:	5d                   	pop    %ebp
f0100ef9:	c3                   	ret    

f0100efa <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100efa:	55                   	push   %ebp
f0100efb:	89 e5                	mov    %esp,%ebp
f0100efd:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f00:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f04:	8b 10                	mov    (%eax),%edx
f0100f06:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f09:	73 0a                	jae    f0100f15 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f0b:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f0e:	89 08                	mov    %ecx,(%eax)
f0100f10:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f13:	88 02                	mov    %al,(%edx)
}
f0100f15:	5d                   	pop    %ebp
f0100f16:	c3                   	ret    

f0100f17 <printfmt>:
{
f0100f17:	55                   	push   %ebp
f0100f18:	89 e5                	mov    %esp,%ebp
f0100f1a:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f1d:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f20:	50                   	push   %eax
f0100f21:	ff 75 10             	push   0x10(%ebp)
f0100f24:	ff 75 0c             	push   0xc(%ebp)
f0100f27:	ff 75 08             	push   0x8(%ebp)
f0100f2a:	e8 05 00 00 00       	call   f0100f34 <vprintfmt>
}
f0100f2f:	83 c4 10             	add    $0x10,%esp
f0100f32:	c9                   	leave  
f0100f33:	c3                   	ret    

f0100f34 <vprintfmt>:
{
f0100f34:	55                   	push   %ebp
f0100f35:	89 e5                	mov    %esp,%ebp
f0100f37:	57                   	push   %edi
f0100f38:	56                   	push   %esi
f0100f39:	53                   	push   %ebx
f0100f3a:	83 ec 3c             	sub    $0x3c,%esp
f0100f3d:	e8 0c f8 ff ff       	call   f010074e <__x86.get_pc_thunk.ax>
f0100f42:	05 c6 03 01 00       	add    $0x103c6,%eax
f0100f47:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100f4a:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f4d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100f50:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f53:	8d 80 3c 1d 00 00    	lea    0x1d3c(%eax),%eax
f0100f59:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100f5c:	eb 0a                	jmp    f0100f68 <vprintfmt+0x34>
			putch(ch, putdat);
f0100f5e:	83 ec 08             	sub    $0x8,%esp
f0100f61:	57                   	push   %edi
f0100f62:	50                   	push   %eax
f0100f63:	ff d6                	call   *%esi
f0100f65:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f68:	83 c3 01             	add    $0x1,%ebx
f0100f6b:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0100f6f:	83 f8 25             	cmp    $0x25,%eax
f0100f72:	74 0c                	je     f0100f80 <vprintfmt+0x4c>
			if (ch == '\0')
f0100f74:	85 c0                	test   %eax,%eax
f0100f76:	75 e6                	jne    f0100f5e <vprintfmt+0x2a>
}
f0100f78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f7b:	5b                   	pop    %ebx
f0100f7c:	5e                   	pop    %esi
f0100f7d:	5f                   	pop    %edi
f0100f7e:	5d                   	pop    %ebp
f0100f7f:	c3                   	ret    
		padc = ' ';
f0100f80:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0100f84:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		precision = -1;
f0100f8b:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0100f92:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		lflag = 0;
f0100f99:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f9e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100fa1:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fa4:	8d 43 01             	lea    0x1(%ebx),%eax
f0100fa7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100faa:	0f b6 13             	movzbl (%ebx),%edx
f0100fad:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100fb0:	3c 55                	cmp    $0x55,%al
f0100fb2:	0f 87 8d 04 00 00    	ja     f0101445 <.L20>
f0100fb8:	0f b6 c0             	movzbl %al,%eax
f0100fbb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fbe:	89 ce                	mov    %ecx,%esi
f0100fc0:	03 b4 81 7c 0e ff ff 	add    -0xf184(%ecx,%eax,4),%esi
f0100fc7:	ff e6                	jmp    *%esi

f0100fc9 <.L69>:
f0100fc9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0100fcc:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0100fd0:	eb d2                	jmp    f0100fa4 <vprintfmt+0x70>

f0100fd2 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fd5:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0100fd9:	eb c9                	jmp    f0100fa4 <vprintfmt+0x70>

f0100fdb <.L31>:
f0100fdb:	0f b6 d2             	movzbl %dl,%edx
f0100fde:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0100fe1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe6:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0100fe9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100fec:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100ff0:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0100ff3:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100ff6:	83 f9 09             	cmp    $0x9,%ecx
f0100ff9:	77 58                	ja     f0101053 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0100ffb:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0100ffe:	eb e9                	jmp    f0100fe9 <.L31+0xe>

f0101000 <.L34>:
			precision = va_arg(ap, int);
f0101000:	8b 45 14             	mov    0x14(%ebp),%eax
f0101003:	8b 00                	mov    (%eax),%eax
f0101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101008:	8b 45 14             	mov    0x14(%ebp),%eax
f010100b:	8d 40 04             	lea    0x4(%eax),%eax
f010100e:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101011:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0101014:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101018:	79 8a                	jns    f0100fa4 <vprintfmt+0x70>
				width = precision, precision = -1;
f010101a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010101d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101020:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0101027:	e9 78 ff ff ff       	jmp    f0100fa4 <vprintfmt+0x70>

f010102c <.L33>:
f010102c:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010102f:	85 d2                	test   %edx,%edx
f0101031:	b8 00 00 00 00       	mov    $0x0,%eax
f0101036:	0f 49 c2             	cmovns %edx,%eax
f0101039:	89 45 d0             	mov    %eax,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010103c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f010103f:	e9 60 ff ff ff       	jmp    f0100fa4 <vprintfmt+0x70>

f0101044 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f0101044:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0101047:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f010104e:	e9 51 ff ff ff       	jmp    f0100fa4 <vprintfmt+0x70>
f0101053:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101056:	89 75 08             	mov    %esi,0x8(%ebp)
f0101059:	eb b9                	jmp    f0101014 <.L34+0x14>

f010105b <.L27>:
			lflag++;
f010105b:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010105f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0101062:	e9 3d ff ff ff       	jmp    f0100fa4 <vprintfmt+0x70>

f0101067 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101067:	8b 75 08             	mov    0x8(%ebp),%esi
f010106a:	8b 45 14             	mov    0x14(%ebp),%eax
f010106d:	8d 58 04             	lea    0x4(%eax),%ebx
f0101070:	83 ec 08             	sub    $0x8,%esp
f0101073:	57                   	push   %edi
f0101074:	ff 30                	push   (%eax)
f0101076:	ff d6                	call   *%esi
			break;
f0101078:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010107b:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f010107e:	e9 2d 03 00 00       	jmp    f01013b0 <.L25+0x52>

f0101083 <.L28>:
			err = va_arg(ap, int);
f0101083:	8b 75 08             	mov    0x8(%ebp),%esi
f0101086:	8b 45 14             	mov    0x14(%ebp),%eax
f0101089:	8d 58 04             	lea    0x4(%eax),%ebx
f010108c:	8b 10                	mov    (%eax),%edx
f010108e:	89 d0                	mov    %edx,%eax
f0101090:	f7 d8                	neg    %eax
f0101092:	0f 48 c2             	cmovs  %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101095:	83 f8 06             	cmp    $0x6,%eax
f0101098:	7f 27                	jg     f01010c1 <.L28+0x3e>
f010109a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f010109d:	8b 14 82             	mov    (%edx,%eax,4),%edx
f01010a0:	85 d2                	test   %edx,%edx
f01010a2:	74 1d                	je     f01010c1 <.L28+0x3e>
				printfmt(putch, putdat, "%s", p);
f01010a4:	52                   	push   %edx
f01010a5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010a8:	8d 80 0f 0e ff ff    	lea    -0xf1f1(%eax),%eax
f01010ae:	50                   	push   %eax
f01010af:	57                   	push   %edi
f01010b0:	56                   	push   %esi
f01010b1:	e8 61 fe ff ff       	call   f0100f17 <printfmt>
f01010b6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010b9:	89 5d 14             	mov    %ebx,0x14(%ebp)
f01010bc:	e9 ef 02 00 00       	jmp    f01013b0 <.L25+0x52>
				printfmt(putch, putdat, "error %d", err);
f01010c1:	50                   	push   %eax
f01010c2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010c5:	8d 80 06 0e ff ff    	lea    -0xf1fa(%eax),%eax
f01010cb:	50                   	push   %eax
f01010cc:	57                   	push   %edi
f01010cd:	56                   	push   %esi
f01010ce:	e8 44 fe ff ff       	call   f0100f17 <printfmt>
f01010d3:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010d6:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01010d9:	e9 d2 02 00 00       	jmp    f01013b0 <.L25+0x52>

f01010de <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f01010de:	8b 75 08             	mov    0x8(%ebp),%esi
f01010e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e4:	83 c0 04             	add    $0x4,%eax
f01010e7:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01010ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ed:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f01010ef:	85 d2                	test   %edx,%edx
f01010f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010f4:	8d 80 ff 0d ff ff    	lea    -0xf201(%eax),%eax
f01010fa:	0f 45 c2             	cmovne %edx,%eax
f01010fd:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0101100:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101104:	7e 06                	jle    f010110c <.L24+0x2e>
f0101106:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f010110a:	75 0d                	jne    f0101119 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f010110c:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010110f:	89 c3                	mov    %eax,%ebx
f0101111:	03 45 d0             	add    -0x30(%ebp),%eax
f0101114:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101117:	eb 58                	jmp    f0101171 <.L24+0x93>
f0101119:	83 ec 08             	sub    $0x8,%esp
f010111c:	ff 75 d8             	push   -0x28(%ebp)
f010111f:	ff 75 c8             	push   -0x38(%ebp)
f0101122:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101125:	e8 d8 04 00 00       	call   f0101602 <strnlen>
f010112a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010112d:	29 c2                	sub    %eax,%edx
f010112f:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0101132:	83 c4 10             	add    $0x10,%esp
f0101135:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0101137:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f010113b:	89 45 d0             	mov    %eax,-0x30(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010113e:	eb 0f                	jmp    f010114f <.L24+0x71>
					putch(padc, putdat);
f0101140:	83 ec 08             	sub    $0x8,%esp
f0101143:	57                   	push   %edi
f0101144:	ff 75 d0             	push   -0x30(%ebp)
f0101147:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101149:	83 eb 01             	sub    $0x1,%ebx
f010114c:	83 c4 10             	add    $0x10,%esp
f010114f:	85 db                	test   %ebx,%ebx
f0101151:	7f ed                	jg     f0101140 <.L24+0x62>
f0101153:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0101156:	85 d2                	test   %edx,%edx
f0101158:	b8 00 00 00 00       	mov    $0x0,%eax
f010115d:	0f 49 c2             	cmovns %edx,%eax
f0101160:	29 c2                	sub    %eax,%edx
f0101162:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101165:	eb a5                	jmp    f010110c <.L24+0x2e>
					putch(ch, putdat);
f0101167:	83 ec 08             	sub    $0x8,%esp
f010116a:	57                   	push   %edi
f010116b:	52                   	push   %edx
f010116c:	ff d6                	call   *%esi
f010116e:	83 c4 10             	add    $0x10,%esp
f0101171:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101174:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101176:	83 c3 01             	add    $0x1,%ebx
f0101179:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f010117d:	0f be d0             	movsbl %al,%edx
f0101180:	85 d2                	test   %edx,%edx
f0101182:	74 4b                	je     f01011cf <.L24+0xf1>
f0101184:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101188:	78 06                	js     f0101190 <.L24+0xb2>
f010118a:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f010118e:	78 1e                	js     f01011ae <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0101190:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101194:	74 d1                	je     f0101167 <.L24+0x89>
f0101196:	0f be c0             	movsbl %al,%eax
f0101199:	83 e8 20             	sub    $0x20,%eax
f010119c:	83 f8 5e             	cmp    $0x5e,%eax
f010119f:	76 c6                	jbe    f0101167 <.L24+0x89>
					putch('?', putdat);
f01011a1:	83 ec 08             	sub    $0x8,%esp
f01011a4:	57                   	push   %edi
f01011a5:	6a 3f                	push   $0x3f
f01011a7:	ff d6                	call   *%esi
f01011a9:	83 c4 10             	add    $0x10,%esp
f01011ac:	eb c3                	jmp    f0101171 <.L24+0x93>
f01011ae:	89 cb                	mov    %ecx,%ebx
f01011b0:	eb 0e                	jmp    f01011c0 <.L24+0xe2>
				putch(' ', putdat);
f01011b2:	83 ec 08             	sub    $0x8,%esp
f01011b5:	57                   	push   %edi
f01011b6:	6a 20                	push   $0x20
f01011b8:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01011ba:	83 eb 01             	sub    $0x1,%ebx
f01011bd:	83 c4 10             	add    $0x10,%esp
f01011c0:	85 db                	test   %ebx,%ebx
f01011c2:	7f ee                	jg     f01011b2 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f01011c4:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01011c7:	89 45 14             	mov    %eax,0x14(%ebp)
f01011ca:	e9 e1 01 00 00       	jmp    f01013b0 <.L25+0x52>
f01011cf:	89 cb                	mov    %ecx,%ebx
f01011d1:	eb ed                	jmp    f01011c0 <.L24+0xe2>

f01011d3 <.L29>:
	if (lflag >= 2)
f01011d3:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01011d6:	8b 75 08             	mov    0x8(%ebp),%esi
f01011d9:	83 f9 01             	cmp    $0x1,%ecx
f01011dc:	7f 1b                	jg     f01011f9 <.L29+0x26>
	else if (lflag)
f01011de:	85 c9                	test   %ecx,%ecx
f01011e0:	74 3f                	je     f0101221 <.L29+0x4e>
		return va_arg(*ap, long);
f01011e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e5:	8b 00                	mov    (%eax),%eax
f01011e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011ea:	99                   	cltd   
f01011eb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f1:	8d 40 04             	lea    0x4(%eax),%eax
f01011f4:	89 45 14             	mov    %eax,0x14(%ebp)
f01011f7:	eb 17                	jmp    f0101210 <.L29+0x3d>
		return va_arg(*ap, long long);
f01011f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fc:	8b 50 04             	mov    0x4(%eax),%edx
f01011ff:	8b 00                	mov    (%eax),%eax
f0101201:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101204:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101207:	8b 45 14             	mov    0x14(%ebp),%eax
f010120a:	8d 40 08             	lea    0x8(%eax),%eax
f010120d:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101210:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101213:	85 d2                	test   %edx,%edx
f0101215:	78 21                	js     f0101238 <.L29+0x65>
			base = 10;
f0101217:	ba 0a 00 00 00       	mov    $0xa,%edx
f010121c:	e9 71 01 00 00       	jmp    f0101392 <.L25+0x34>
		return va_arg(*ap, int);
f0101221:	8b 45 14             	mov    0x14(%ebp),%eax
f0101224:	8b 00                	mov    (%eax),%eax
f0101226:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101229:	99                   	cltd   
f010122a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010122d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101230:	8d 40 04             	lea    0x4(%eax),%eax
f0101233:	89 45 14             	mov    %eax,0x14(%ebp)
f0101236:	eb d8                	jmp    f0101210 <.L29+0x3d>
				putch('-', putdat);
f0101238:	83 ec 08             	sub    $0x8,%esp
f010123b:	57                   	push   %edi
f010123c:	6a 2d                	push   $0x2d
f010123e:	ff d6                	call   *%esi
				num = -(long long) num;
f0101240:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101243:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101246:	f7 d8                	neg    %eax
f0101248:	83 d2 00             	adc    $0x0,%edx
f010124b:	f7 da                	neg    %edx
f010124d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101250:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101253:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101256:	ba 0a 00 00 00       	mov    $0xa,%edx
f010125b:	e9 32 01 00 00       	jmp    f0101392 <.L25+0x34>

f0101260 <.L23>:
	if (lflag >= 2)
f0101260:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101263:	8b 75 08             	mov    0x8(%ebp),%esi
f0101266:	83 f9 01             	cmp    $0x1,%ecx
f0101269:	7f 27                	jg     f0101292 <.L23+0x32>
	else if (lflag)
f010126b:	85 c9                	test   %ecx,%ecx
f010126d:	74 44                	je     f01012b3 <.L23+0x53>
		return va_arg(*ap, unsigned long);
f010126f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101272:	8b 00                	mov    (%eax),%eax
f0101274:	ba 00 00 00 00       	mov    $0x0,%edx
f0101279:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010127c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010127f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101282:	8d 40 04             	lea    0x4(%eax),%eax
f0101285:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101288:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long);
f010128d:	e9 00 01 00 00       	jmp    f0101392 <.L25+0x34>
		return va_arg(*ap, unsigned long long);
f0101292:	8b 45 14             	mov    0x14(%ebp),%eax
f0101295:	8b 50 04             	mov    0x4(%eax),%edx
f0101298:	8b 00                	mov    (%eax),%eax
f010129a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010129d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a3:	8d 40 08             	lea    0x8(%eax),%eax
f01012a6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012a9:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long long);
f01012ae:	e9 df 00 00 00       	jmp    f0101392 <.L25+0x34>
		return va_arg(*ap, unsigned int);
f01012b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b6:	8b 00                	mov    (%eax),%eax
f01012b8:	ba 00 00 00 00       	mov    $0x0,%edx
f01012bd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012c0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c6:	8d 40 04             	lea    0x4(%eax),%eax
f01012c9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012cc:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned int);
f01012d1:	e9 bc 00 00 00       	jmp    f0101392 <.L25+0x34>

f01012d6 <.L26>:
	if (lflag >= 2)
f01012d6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01012d9:	8b 75 08             	mov    0x8(%ebp),%esi
f01012dc:	83 f9 01             	cmp    $0x1,%ecx
f01012df:	7f 1f                	jg     f0101300 <.L26+0x2a>
	else if (lflag)
f01012e1:	85 c9                	test   %ecx,%ecx
f01012e3:	74 5e                	je     f0101343 <.L26+0x6d>
		return va_arg(*ap, unsigned long);
f01012e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e8:	8b 00                	mov    (%eax),%eax
f01012ea:	ba 00 00 00 00       	mov    $0x0,%edx
f01012ef:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012f2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f8:	8d 40 04             	lea    0x4(%eax),%eax
f01012fb:	89 45 14             	mov    %eax,0x14(%ebp)
f01012fe:	eb 17                	jmp    f0101317 <.L26+0x41>
		return va_arg(*ap, unsigned long long);
f0101300:	8b 45 14             	mov    0x14(%ebp),%eax
f0101303:	8b 50 04             	mov    0x4(%eax),%edx
f0101306:	8b 00                	mov    (%eax),%eax
f0101308:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010130b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010130e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101311:	8d 40 08             	lea    0x8(%eax),%eax
f0101314:	89 45 14             	mov    %eax,0x14(%ebp)
			if (altflag && num != 0){
f0101317:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010131b:	0f 84 07 01 00 00    	je     f0101428 <.L21+0x70>
f0101321:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101324:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101327:	89 c1                	mov    %eax,%ecx
f0101329:	09 d1                	or     %edx,%ecx
f010132b:	0f 84 f7 00 00 00    	je     f0101428 <.L21+0x70>
				putch('0', putdat);
f0101331:	83 ec 08             	sub    $0x8,%esp
f0101334:	57                   	push   %edi
f0101335:	6a 30                	push   $0x30
f0101337:	ff d6                	call   *%esi
f0101339:	83 c4 10             	add    $0x10,%esp
			base = 8;
f010133c:	ba 08 00 00 00       	mov    $0x8,%edx
f0101341:	eb 4f                	jmp    f0101392 <.L25+0x34>
		return va_arg(*ap, unsigned int);
f0101343:	8b 45 14             	mov    0x14(%ebp),%eax
f0101346:	8b 00                	mov    (%eax),%eax
f0101348:	ba 00 00 00 00       	mov    $0x0,%edx
f010134d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101350:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101353:	8b 45 14             	mov    0x14(%ebp),%eax
f0101356:	8d 40 04             	lea    0x4(%eax),%eax
f0101359:	89 45 14             	mov    %eax,0x14(%ebp)
f010135c:	eb b9                	jmp    f0101317 <.L26+0x41>

f010135e <.L25>:
			putch('0', putdat);
f010135e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101361:	83 ec 08             	sub    $0x8,%esp
f0101364:	57                   	push   %edi
f0101365:	6a 30                	push   $0x30
f0101367:	ff d6                	call   *%esi
			putch('x', putdat);
f0101369:	83 c4 08             	add    $0x8,%esp
f010136c:	57                   	push   %edi
f010136d:	6a 78                	push   $0x78
f010136f:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101371:	8b 45 14             	mov    0x14(%ebp),%eax
f0101374:	8b 00                	mov    (%eax),%eax
f0101376:	ba 00 00 00 00       	mov    $0x0,%edx
f010137b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010137e:	89 55 dc             	mov    %edx,-0x24(%ebp)
			goto number;
f0101381:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101384:	8b 45 14             	mov    0x14(%ebp),%eax
f0101387:	8d 40 04             	lea    0x4(%eax),%eax
f010138a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010138d:	ba 10 00 00 00       	mov    $0x10,%edx
			printnum(putch, putdat, num, base, width, padc);
f0101392:	83 ec 0c             	sub    $0xc,%esp
f0101395:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0101399:	50                   	push   %eax
f010139a:	ff 75 d0             	push   -0x30(%ebp)
f010139d:	52                   	push   %edx
f010139e:	ff 75 dc             	push   -0x24(%ebp)
f01013a1:	ff 75 d8             	push   -0x28(%ebp)
f01013a4:	89 fa                	mov    %edi,%edx
f01013a6:	89 f0                	mov    %esi,%eax
f01013a8:	e8 8f fa ff ff       	call   f0100e3c <printnum>
			break;
f01013ad:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01013b0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01013b3:	e9 b0 fb ff ff       	jmp    f0100f68 <vprintfmt+0x34>

f01013b8 <.L21>:
	if (lflag >= 2)
f01013b8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01013bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01013be:	83 f9 01             	cmp    $0x1,%ecx
f01013c1:	7f 24                	jg     f01013e7 <.L21+0x2f>
	else if (lflag)
f01013c3:	85 c9                	test   %ecx,%ecx
f01013c5:	74 3e                	je     f0101405 <.L21+0x4d>
		return va_arg(*ap, unsigned long);
f01013c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ca:	8b 00                	mov    (%eax),%eax
f01013cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01013d1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01013d4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01013d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013da:	8d 40 04             	lea    0x4(%eax),%eax
f01013dd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013e0:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long);
f01013e5:	eb ab                	jmp    f0101392 <.L25+0x34>
		return va_arg(*ap, unsigned long long);
f01013e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ea:	8b 50 04             	mov    0x4(%eax),%edx
f01013ed:	8b 00                	mov    (%eax),%eax
f01013ef:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01013f2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01013f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01013f8:	8d 40 08             	lea    0x8(%eax),%eax
f01013fb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013fe:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long long);
f0101403:	eb 8d                	jmp    f0101392 <.L25+0x34>
		return va_arg(*ap, unsigned int);
f0101405:	8b 45 14             	mov    0x14(%ebp),%eax
f0101408:	8b 00                	mov    (%eax),%eax
f010140a:	ba 00 00 00 00       	mov    $0x0,%edx
f010140f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101412:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101415:	8b 45 14             	mov    0x14(%ebp),%eax
f0101418:	8d 40 04             	lea    0x4(%eax),%eax
f010141b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010141e:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned int);
f0101423:	e9 6a ff ff ff       	jmp    f0101392 <.L25+0x34>
			base = 8;
f0101428:	ba 08 00 00 00       	mov    $0x8,%edx
f010142d:	e9 60 ff ff ff       	jmp    f0101392 <.L25+0x34>

f0101432 <.L35>:
			putch(ch, putdat);
f0101432:	8b 75 08             	mov    0x8(%ebp),%esi
f0101435:	83 ec 08             	sub    $0x8,%esp
f0101438:	57                   	push   %edi
f0101439:	6a 25                	push   $0x25
f010143b:	ff d6                	call   *%esi
			break;
f010143d:	83 c4 10             	add    $0x10,%esp
f0101440:	e9 6b ff ff ff       	jmp    f01013b0 <.L25+0x52>

f0101445 <.L20>:
			putch('%', putdat);
f0101445:	8b 75 08             	mov    0x8(%ebp),%esi
f0101448:	83 ec 08             	sub    $0x8,%esp
f010144b:	57                   	push   %edi
f010144c:	6a 25                	push   $0x25
f010144e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101450:	83 c4 10             	add    $0x10,%esp
f0101453:	89 d8                	mov    %ebx,%eax
f0101455:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101459:	74 05                	je     f0101460 <.L20+0x1b>
f010145b:	83 e8 01             	sub    $0x1,%eax
f010145e:	eb f5                	jmp    f0101455 <.L20+0x10>
f0101460:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101463:	e9 48 ff ff ff       	jmp    f01013b0 <.L25+0x52>

f0101468 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101468:	55                   	push   %ebp
f0101469:	89 e5                	mov    %esp,%ebp
f010146b:	53                   	push   %ebx
f010146c:	83 ec 14             	sub    $0x14,%esp
f010146f:	e8 48 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0101474:	81 c3 94 fe 00 00    	add    $0xfe94,%ebx
f010147a:	8b 45 08             	mov    0x8(%ebp),%eax
f010147d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101480:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101483:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101487:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010148a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101491:	85 c0                	test   %eax,%eax
f0101493:	74 2b                	je     f01014c0 <vsnprintf+0x58>
f0101495:	85 d2                	test   %edx,%edx
f0101497:	7e 27                	jle    f01014c0 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101499:	ff 75 14             	push   0x14(%ebp)
f010149c:	ff 75 10             	push   0x10(%ebp)
f010149f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01014a2:	50                   	push   %eax
f01014a3:	8d 83 f2 fb fe ff    	lea    -0x1040e(%ebx),%eax
f01014a9:	50                   	push   %eax
f01014aa:	e8 85 fa ff ff       	call   f0100f34 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01014af:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014b2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01014b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014b8:	83 c4 10             	add    $0x10,%esp
}
f01014bb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014be:	c9                   	leave  
f01014bf:	c3                   	ret    
		return -E_INVAL;
f01014c0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01014c5:	eb f4                	jmp    f01014bb <vsnprintf+0x53>

f01014c7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01014c7:	55                   	push   %ebp
f01014c8:	89 e5                	mov    %esp,%ebp
f01014ca:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01014cd:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01014d0:	50                   	push   %eax
f01014d1:	ff 75 10             	push   0x10(%ebp)
f01014d4:	ff 75 0c             	push   0xc(%ebp)
f01014d7:	ff 75 08             	push   0x8(%ebp)
f01014da:	e8 89 ff ff ff       	call   f0101468 <vsnprintf>
	va_end(ap);

	return rc;
}
f01014df:	c9                   	leave  
f01014e0:	c3                   	ret    

f01014e1 <__x86.get_pc_thunk.cx>:
f01014e1:	8b 0c 24             	mov    (%esp),%ecx
f01014e4:	c3                   	ret    

f01014e5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01014e5:	55                   	push   %ebp
f01014e6:	89 e5                	mov    %esp,%ebp
f01014e8:	57                   	push   %edi
f01014e9:	56                   	push   %esi
f01014ea:	53                   	push   %ebx
f01014eb:	83 ec 1c             	sub    $0x1c,%esp
f01014ee:	e8 c9 ec ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01014f3:	81 c3 15 fe 00 00    	add    $0xfe15,%ebx
f01014f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01014fc:	85 c0                	test   %eax,%eax
f01014fe:	74 13                	je     f0101513 <readline+0x2e>
		cprintf("%s", prompt);
f0101500:	83 ec 08             	sub    $0x8,%esp
f0101503:	50                   	push   %eax
f0101504:	8d 83 0f 0e ff ff    	lea    -0xf1f1(%ebx),%eax
f010150a:	50                   	push   %eax
f010150b:	e8 cd f5 ff ff       	call   f0100add <cprintf>
f0101510:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101513:	83 ec 0c             	sub    $0xc,%esp
f0101516:	6a 00                	push   $0x0
f0101518:	e8 2b f2 ff ff       	call   f0100748 <iscons>
f010151d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101520:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101523:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0101528:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f010152e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101531:	eb 45                	jmp    f0101578 <readline+0x93>
			cprintf("read error: %e\n", c);
f0101533:	83 ec 08             	sub    $0x8,%esp
f0101536:	50                   	push   %eax
f0101537:	8d 83 d4 0f ff ff    	lea    -0xf02c(%ebx),%eax
f010153d:	50                   	push   %eax
f010153e:	e8 9a f5 ff ff       	call   f0100add <cprintf>
			return NULL;
f0101543:	83 c4 10             	add    $0x10,%esp
f0101546:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010154b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010154e:	5b                   	pop    %ebx
f010154f:	5e                   	pop    %esi
f0101550:	5f                   	pop    %edi
f0101551:	5d                   	pop    %ebp
f0101552:	c3                   	ret    
			if (echoing)
f0101553:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101557:	75 05                	jne    f010155e <readline+0x79>
			i--;
f0101559:	83 ef 01             	sub    $0x1,%edi
f010155c:	eb 1a                	jmp    f0101578 <readline+0x93>
				cputchar('\b');
f010155e:	83 ec 0c             	sub    $0xc,%esp
f0101561:	6a 08                	push   $0x8
f0101563:	e8 bf f1 ff ff       	call   f0100727 <cputchar>
f0101568:	83 c4 10             	add    $0x10,%esp
f010156b:	eb ec                	jmp    f0101559 <readline+0x74>
			buf[i++] = c;
f010156d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101570:	89 f0                	mov    %esi,%eax
f0101572:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0101575:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101578:	e8 ba f1 ff ff       	call   f0100737 <getchar>
f010157d:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010157f:	85 c0                	test   %eax,%eax
f0101581:	78 b0                	js     f0101533 <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101583:	83 f8 08             	cmp    $0x8,%eax
f0101586:	0f 94 c0             	sete   %al
f0101589:	83 fe 7f             	cmp    $0x7f,%esi
f010158c:	0f 94 c2             	sete   %dl
f010158f:	08 d0                	or     %dl,%al
f0101591:	74 04                	je     f0101597 <readline+0xb2>
f0101593:	85 ff                	test   %edi,%edi
f0101595:	7f bc                	jg     f0101553 <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101597:	83 fe 1f             	cmp    $0x1f,%esi
f010159a:	7e 1c                	jle    f01015b8 <readline+0xd3>
f010159c:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01015a2:	7f 14                	jg     f01015b8 <readline+0xd3>
			if (echoing)
f01015a4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015a8:	74 c3                	je     f010156d <readline+0x88>
				cputchar(c);
f01015aa:	83 ec 0c             	sub    $0xc,%esp
f01015ad:	56                   	push   %esi
f01015ae:	e8 74 f1 ff ff       	call   f0100727 <cputchar>
f01015b3:	83 c4 10             	add    $0x10,%esp
f01015b6:	eb b5                	jmp    f010156d <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f01015b8:	83 fe 0a             	cmp    $0xa,%esi
f01015bb:	74 05                	je     f01015c2 <readline+0xdd>
f01015bd:	83 fe 0d             	cmp    $0xd,%esi
f01015c0:	75 b6                	jne    f0101578 <readline+0x93>
			if (echoing)
f01015c2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015c6:	75 13                	jne    f01015db <readline+0xf6>
			buf[i] = 0;
f01015c8:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f01015cf:	00 
			return buf;
f01015d0:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01015d6:	e9 70 ff ff ff       	jmp    f010154b <readline+0x66>
				cputchar('\n');
f01015db:	83 ec 0c             	sub    $0xc,%esp
f01015de:	6a 0a                	push   $0xa
f01015e0:	e8 42 f1 ff ff       	call   f0100727 <cputchar>
f01015e5:	83 c4 10             	add    $0x10,%esp
f01015e8:	eb de                	jmp    f01015c8 <readline+0xe3>

f01015ea <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01015ea:	55                   	push   %ebp
f01015eb:	89 e5                	mov    %esp,%ebp
f01015ed:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01015f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01015f5:	eb 03                	jmp    f01015fa <strlen+0x10>
		n++;
f01015f7:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01015fa:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015fe:	75 f7                	jne    f01015f7 <strlen+0xd>
	return n;
}
f0101600:	5d                   	pop    %ebp
f0101601:	c3                   	ret    

f0101602 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101602:	55                   	push   %ebp
f0101603:	89 e5                	mov    %esp,%ebp
f0101605:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101608:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010160b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101610:	eb 03                	jmp    f0101615 <strnlen+0x13>
		n++;
f0101612:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101615:	39 d0                	cmp    %edx,%eax
f0101617:	74 08                	je     f0101621 <strnlen+0x1f>
f0101619:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010161d:	75 f3                	jne    f0101612 <strnlen+0x10>
f010161f:	89 c2                	mov    %eax,%edx
	return n;
}
f0101621:	89 d0                	mov    %edx,%eax
f0101623:	5d                   	pop    %ebp
f0101624:	c3                   	ret    

f0101625 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101625:	55                   	push   %ebp
f0101626:	89 e5                	mov    %esp,%ebp
f0101628:	53                   	push   %ebx
f0101629:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010162c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010162f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101634:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0101638:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f010163b:	83 c0 01             	add    $0x1,%eax
f010163e:	84 d2                	test   %dl,%dl
f0101640:	75 f2                	jne    f0101634 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101642:	89 c8                	mov    %ecx,%eax
f0101644:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101647:	c9                   	leave  
f0101648:	c3                   	ret    

f0101649 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101649:	55                   	push   %ebp
f010164a:	89 e5                	mov    %esp,%ebp
f010164c:	53                   	push   %ebx
f010164d:	83 ec 10             	sub    $0x10,%esp
f0101650:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101653:	53                   	push   %ebx
f0101654:	e8 91 ff ff ff       	call   f01015ea <strlen>
f0101659:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f010165c:	ff 75 0c             	push   0xc(%ebp)
f010165f:	01 d8                	add    %ebx,%eax
f0101661:	50                   	push   %eax
f0101662:	e8 be ff ff ff       	call   f0101625 <strcpy>
	return dst;
}
f0101667:	89 d8                	mov    %ebx,%eax
f0101669:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010166c:	c9                   	leave  
f010166d:	c3                   	ret    

f010166e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010166e:	55                   	push   %ebp
f010166f:	89 e5                	mov    %esp,%ebp
f0101671:	56                   	push   %esi
f0101672:	53                   	push   %ebx
f0101673:	8b 75 08             	mov    0x8(%ebp),%esi
f0101676:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101679:	89 f3                	mov    %esi,%ebx
f010167b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010167e:	89 f0                	mov    %esi,%eax
f0101680:	eb 0f                	jmp    f0101691 <strncpy+0x23>
		*dst++ = *src;
f0101682:	83 c0 01             	add    $0x1,%eax
f0101685:	0f b6 0a             	movzbl (%edx),%ecx
f0101688:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010168b:	80 f9 01             	cmp    $0x1,%cl
f010168e:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f0101691:	39 d8                	cmp    %ebx,%eax
f0101693:	75 ed                	jne    f0101682 <strncpy+0x14>
	}
	return ret;
}
f0101695:	89 f0                	mov    %esi,%eax
f0101697:	5b                   	pop    %ebx
f0101698:	5e                   	pop    %esi
f0101699:	5d                   	pop    %ebp
f010169a:	c3                   	ret    

f010169b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010169b:	55                   	push   %ebp
f010169c:	89 e5                	mov    %esp,%ebp
f010169e:	56                   	push   %esi
f010169f:	53                   	push   %ebx
f01016a0:	8b 75 08             	mov    0x8(%ebp),%esi
f01016a3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01016a6:	8b 55 10             	mov    0x10(%ebp),%edx
f01016a9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01016ab:	85 d2                	test   %edx,%edx
f01016ad:	74 21                	je     f01016d0 <strlcpy+0x35>
f01016af:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01016b3:	89 f2                	mov    %esi,%edx
f01016b5:	eb 09                	jmp    f01016c0 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01016b7:	83 c1 01             	add    $0x1,%ecx
f01016ba:	83 c2 01             	add    $0x1,%edx
f01016bd:	88 5a ff             	mov    %bl,-0x1(%edx)
		while (--size > 0 && *src != '\0')
f01016c0:	39 c2                	cmp    %eax,%edx
f01016c2:	74 09                	je     f01016cd <strlcpy+0x32>
f01016c4:	0f b6 19             	movzbl (%ecx),%ebx
f01016c7:	84 db                	test   %bl,%bl
f01016c9:	75 ec                	jne    f01016b7 <strlcpy+0x1c>
f01016cb:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f01016cd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01016d0:	29 f0                	sub    %esi,%eax
}
f01016d2:	5b                   	pop    %ebx
f01016d3:	5e                   	pop    %esi
f01016d4:	5d                   	pop    %ebp
f01016d5:	c3                   	ret    

f01016d6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01016d6:	55                   	push   %ebp
f01016d7:	89 e5                	mov    %esp,%ebp
f01016d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016dc:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01016df:	eb 06                	jmp    f01016e7 <strcmp+0x11>
		p++, q++;
f01016e1:	83 c1 01             	add    $0x1,%ecx
f01016e4:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01016e7:	0f b6 01             	movzbl (%ecx),%eax
f01016ea:	84 c0                	test   %al,%al
f01016ec:	74 04                	je     f01016f2 <strcmp+0x1c>
f01016ee:	3a 02                	cmp    (%edx),%al
f01016f0:	74 ef                	je     f01016e1 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01016f2:	0f b6 c0             	movzbl %al,%eax
f01016f5:	0f b6 12             	movzbl (%edx),%edx
f01016f8:	29 d0                	sub    %edx,%eax
}
f01016fa:	5d                   	pop    %ebp
f01016fb:	c3                   	ret    

f01016fc <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01016fc:	55                   	push   %ebp
f01016fd:	89 e5                	mov    %esp,%ebp
f01016ff:	53                   	push   %ebx
f0101700:	8b 45 08             	mov    0x8(%ebp),%eax
f0101703:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101706:	89 c3                	mov    %eax,%ebx
f0101708:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010170b:	eb 06                	jmp    f0101713 <strncmp+0x17>
		n--, p++, q++;
f010170d:	83 c0 01             	add    $0x1,%eax
f0101710:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101713:	39 d8                	cmp    %ebx,%eax
f0101715:	74 18                	je     f010172f <strncmp+0x33>
f0101717:	0f b6 08             	movzbl (%eax),%ecx
f010171a:	84 c9                	test   %cl,%cl
f010171c:	74 04                	je     f0101722 <strncmp+0x26>
f010171e:	3a 0a                	cmp    (%edx),%cl
f0101720:	74 eb                	je     f010170d <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101722:	0f b6 00             	movzbl (%eax),%eax
f0101725:	0f b6 12             	movzbl (%edx),%edx
f0101728:	29 d0                	sub    %edx,%eax
}
f010172a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010172d:	c9                   	leave  
f010172e:	c3                   	ret    
		return 0;
f010172f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101734:	eb f4                	jmp    f010172a <strncmp+0x2e>

f0101736 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101736:	55                   	push   %ebp
f0101737:	89 e5                	mov    %esp,%ebp
f0101739:	8b 45 08             	mov    0x8(%ebp),%eax
f010173c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101740:	eb 03                	jmp    f0101745 <strchr+0xf>
f0101742:	83 c0 01             	add    $0x1,%eax
f0101745:	0f b6 10             	movzbl (%eax),%edx
f0101748:	84 d2                	test   %dl,%dl
f010174a:	74 06                	je     f0101752 <strchr+0x1c>
		if (*s == c)
f010174c:	38 ca                	cmp    %cl,%dl
f010174e:	75 f2                	jne    f0101742 <strchr+0xc>
f0101750:	eb 05                	jmp    f0101757 <strchr+0x21>
			return (char *) s;
	return 0;
f0101752:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101757:	5d                   	pop    %ebp
f0101758:	c3                   	ret    

f0101759 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101759:	55                   	push   %ebp
f010175a:	89 e5                	mov    %esp,%ebp
f010175c:	8b 45 08             	mov    0x8(%ebp),%eax
f010175f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101763:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101766:	38 ca                	cmp    %cl,%dl
f0101768:	74 09                	je     f0101773 <strfind+0x1a>
f010176a:	84 d2                	test   %dl,%dl
f010176c:	74 05                	je     f0101773 <strfind+0x1a>
	for (; *s; s++)
f010176e:	83 c0 01             	add    $0x1,%eax
f0101771:	eb f0                	jmp    f0101763 <strfind+0xa>
			break;
	return (char *) s;
}
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    

f0101775 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101775:	55                   	push   %ebp
f0101776:	89 e5                	mov    %esp,%ebp
f0101778:	57                   	push   %edi
f0101779:	56                   	push   %esi
f010177a:	53                   	push   %ebx
f010177b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010177e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101781:	85 c9                	test   %ecx,%ecx
f0101783:	74 2f                	je     f01017b4 <memset+0x3f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101785:	89 f8                	mov    %edi,%eax
f0101787:	09 c8                	or     %ecx,%eax
f0101789:	a8 03                	test   $0x3,%al
f010178b:	75 21                	jne    f01017ae <memset+0x39>
		c &= 0xFF;
f010178d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101791:	89 d0                	mov    %edx,%eax
f0101793:	c1 e0 08             	shl    $0x8,%eax
f0101796:	89 d3                	mov    %edx,%ebx
f0101798:	c1 e3 18             	shl    $0x18,%ebx
f010179b:	89 d6                	mov    %edx,%esi
f010179d:	c1 e6 10             	shl    $0x10,%esi
f01017a0:	09 f3                	or     %esi,%ebx
f01017a2:	09 da                	or     %ebx,%edx
f01017a4:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01017a6:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01017a9:	fc                   	cld    
f01017aa:	f3 ab                	rep stos %eax,%es:(%edi)
f01017ac:	eb 06                	jmp    f01017b4 <memset+0x3f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01017ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017b1:	fc                   	cld    
f01017b2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01017b4:	89 f8                	mov    %edi,%eax
f01017b6:	5b                   	pop    %ebx
f01017b7:	5e                   	pop    %esi
f01017b8:	5f                   	pop    %edi
f01017b9:	5d                   	pop    %ebp
f01017ba:	c3                   	ret    

f01017bb <memmove>:
// memmove: copy n bytes from src to dst 
void *
memmove(void *dst, const void *src, size_t n)
{
f01017bb:	55                   	push   %ebp
f01017bc:	89 e5                	mov    %esp,%ebp
f01017be:	57                   	push   %edi
f01017bf:	56                   	push   %esi
f01017c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017c6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01017c9:	39 c6                	cmp    %eax,%esi
f01017cb:	73 32                	jae    f01017ff <memmove+0x44>
f01017cd:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01017d0:	39 c2                	cmp    %eax,%edx
f01017d2:	76 2b                	jbe    f01017ff <memmove+0x44>
		s += n;
		d += n;
f01017d4:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017d7:	89 d6                	mov    %edx,%esi
f01017d9:	09 fe                	or     %edi,%esi
f01017db:	09 ce                	or     %ecx,%esi
f01017dd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01017e3:	75 0e                	jne    f01017f3 <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01017e5:	83 ef 04             	sub    $0x4,%edi
f01017e8:	8d 72 fc             	lea    -0x4(%edx),%esi
f01017eb:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01017ee:	fd                   	std    
f01017ef:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017f1:	eb 09                	jmp    f01017fc <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01017f3:	83 ef 01             	sub    $0x1,%edi
f01017f6:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01017f9:	fd                   	std    
f01017fa:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01017fc:	fc                   	cld    
f01017fd:	eb 1a                	jmp    f0101819 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017ff:	89 f2                	mov    %esi,%edx
f0101801:	09 c2                	or     %eax,%edx
f0101803:	09 ca                	or     %ecx,%edx
f0101805:	f6 c2 03             	test   $0x3,%dl
f0101808:	75 0a                	jne    f0101814 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010180a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010180d:	89 c7                	mov    %eax,%edi
f010180f:	fc                   	cld    
f0101810:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101812:	eb 05                	jmp    f0101819 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f0101814:	89 c7                	mov    %eax,%edi
f0101816:	fc                   	cld    
f0101817:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101819:	5e                   	pop    %esi
f010181a:	5f                   	pop    %edi
f010181b:	5d                   	pop    %ebp
f010181c:	c3                   	ret    

f010181d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010181d:	55                   	push   %ebp
f010181e:	89 e5                	mov    %esp,%ebp
f0101820:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101823:	ff 75 10             	push   0x10(%ebp)
f0101826:	ff 75 0c             	push   0xc(%ebp)
f0101829:	ff 75 08             	push   0x8(%ebp)
f010182c:	e8 8a ff ff ff       	call   f01017bb <memmove>
}
f0101831:	c9                   	leave  
f0101832:	c3                   	ret    

f0101833 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101833:	55                   	push   %ebp
f0101834:	89 e5                	mov    %esp,%ebp
f0101836:	56                   	push   %esi
f0101837:	53                   	push   %ebx
f0101838:	8b 45 08             	mov    0x8(%ebp),%eax
f010183b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010183e:	89 c6                	mov    %eax,%esi
f0101840:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101843:	eb 06                	jmp    f010184b <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101845:	83 c0 01             	add    $0x1,%eax
f0101848:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f010184b:	39 f0                	cmp    %esi,%eax
f010184d:	74 14                	je     f0101863 <memcmp+0x30>
		if (*s1 != *s2)
f010184f:	0f b6 08             	movzbl (%eax),%ecx
f0101852:	0f b6 1a             	movzbl (%edx),%ebx
f0101855:	38 d9                	cmp    %bl,%cl
f0101857:	74 ec                	je     f0101845 <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f0101859:	0f b6 c1             	movzbl %cl,%eax
f010185c:	0f b6 db             	movzbl %bl,%ebx
f010185f:	29 d8                	sub    %ebx,%eax
f0101861:	eb 05                	jmp    f0101868 <memcmp+0x35>
	}

	return 0;
f0101863:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101868:	5b                   	pop    %ebx
f0101869:	5e                   	pop    %esi
f010186a:	5d                   	pop    %ebp
f010186b:	c3                   	ret    

f010186c <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010186c:	55                   	push   %ebp
f010186d:	89 e5                	mov    %esp,%ebp
f010186f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101872:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101875:	89 c2                	mov    %eax,%edx
f0101877:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010187a:	eb 03                	jmp    f010187f <memfind+0x13>
f010187c:	83 c0 01             	add    $0x1,%eax
f010187f:	39 d0                	cmp    %edx,%eax
f0101881:	73 04                	jae    f0101887 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101883:	38 08                	cmp    %cl,(%eax)
f0101885:	75 f5                	jne    f010187c <memfind+0x10>
			break;
	return (void *) s;
}
f0101887:	5d                   	pop    %ebp
f0101888:	c3                   	ret    

f0101889 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101889:	55                   	push   %ebp
f010188a:	89 e5                	mov    %esp,%ebp
f010188c:	57                   	push   %edi
f010188d:	56                   	push   %esi
f010188e:	53                   	push   %ebx
f010188f:	8b 55 08             	mov    0x8(%ebp),%edx
f0101892:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101895:	eb 03                	jmp    f010189a <strtol+0x11>
		s++;
f0101897:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f010189a:	0f b6 02             	movzbl (%edx),%eax
f010189d:	3c 20                	cmp    $0x20,%al
f010189f:	74 f6                	je     f0101897 <strtol+0xe>
f01018a1:	3c 09                	cmp    $0x9,%al
f01018a3:	74 f2                	je     f0101897 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01018a5:	3c 2b                	cmp    $0x2b,%al
f01018a7:	74 2a                	je     f01018d3 <strtol+0x4a>
	int neg = 0;
f01018a9:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01018ae:	3c 2d                	cmp    $0x2d,%al
f01018b0:	74 2b                	je     f01018dd <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018b2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01018b8:	75 0f                	jne    f01018c9 <strtol+0x40>
f01018ba:	80 3a 30             	cmpb   $0x30,(%edx)
f01018bd:	74 28                	je     f01018e7 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01018bf:	85 db                	test   %ebx,%ebx
f01018c1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01018c6:	0f 44 d8             	cmove  %eax,%ebx
f01018c9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01018ce:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01018d1:	eb 46                	jmp    f0101919 <strtol+0x90>
		s++;
f01018d3:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f01018d6:	bf 00 00 00 00       	mov    $0x0,%edi
f01018db:	eb d5                	jmp    f01018b2 <strtol+0x29>
		s++, neg = 1;
f01018dd:	83 c2 01             	add    $0x1,%edx
f01018e0:	bf 01 00 00 00       	mov    $0x1,%edi
f01018e5:	eb cb                	jmp    f01018b2 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018e7:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01018eb:	74 0e                	je     f01018fb <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f01018ed:	85 db                	test   %ebx,%ebx
f01018ef:	75 d8                	jne    f01018c9 <strtol+0x40>
		s++, base = 8;
f01018f1:	83 c2 01             	add    $0x1,%edx
f01018f4:	bb 08 00 00 00       	mov    $0x8,%ebx
f01018f9:	eb ce                	jmp    f01018c9 <strtol+0x40>
		s += 2, base = 16;
f01018fb:	83 c2 02             	add    $0x2,%edx
f01018fe:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101903:	eb c4                	jmp    f01018c9 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0101905:	0f be c0             	movsbl %al,%eax
f0101908:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010190b:	3b 45 10             	cmp    0x10(%ebp),%eax
f010190e:	7d 3a                	jge    f010194a <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101910:	83 c2 01             	add    $0x1,%edx
f0101913:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f0101917:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f0101919:	0f b6 02             	movzbl (%edx),%eax
f010191c:	8d 70 d0             	lea    -0x30(%eax),%esi
f010191f:	89 f3                	mov    %esi,%ebx
f0101921:	80 fb 09             	cmp    $0x9,%bl
f0101924:	76 df                	jbe    f0101905 <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f0101926:	8d 70 9f             	lea    -0x61(%eax),%esi
f0101929:	89 f3                	mov    %esi,%ebx
f010192b:	80 fb 19             	cmp    $0x19,%bl
f010192e:	77 08                	ja     f0101938 <strtol+0xaf>
			dig = *s - 'a' + 10;
f0101930:	0f be c0             	movsbl %al,%eax
f0101933:	83 e8 57             	sub    $0x57,%eax
f0101936:	eb d3                	jmp    f010190b <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f0101938:	8d 70 bf             	lea    -0x41(%eax),%esi
f010193b:	89 f3                	mov    %esi,%ebx
f010193d:	80 fb 19             	cmp    $0x19,%bl
f0101940:	77 08                	ja     f010194a <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101942:	0f be c0             	movsbl %al,%eax
f0101945:	83 e8 37             	sub    $0x37,%eax
f0101948:	eb c1                	jmp    f010190b <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f010194a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010194e:	74 05                	je     f0101955 <strtol+0xcc>
		*endptr = (char *) s;
f0101950:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101953:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0101955:	89 c8                	mov    %ecx,%eax
f0101957:	f7 d8                	neg    %eax
f0101959:	85 ff                	test   %edi,%edi
f010195b:	0f 45 c8             	cmovne %eax,%ecx
}
f010195e:	89 c8                	mov    %ecx,%eax
f0101960:	5b                   	pop    %ebx
f0101961:	5e                   	pop    %esi
f0101962:	5f                   	pop    %edi
f0101963:	5d                   	pop    %ebp
f0101964:	c3                   	ret    
f0101965:	66 90                	xchg   %ax,%ax
f0101967:	66 90                	xchg   %ax,%ax
f0101969:	66 90                	xchg   %ax,%ax
f010196b:	66 90                	xchg   %ax,%ax
f010196d:	66 90                	xchg   %ax,%ax
f010196f:	90                   	nop

f0101970 <__udivdi3>:
f0101970:	f3 0f 1e fb          	endbr32 
f0101974:	55                   	push   %ebp
f0101975:	57                   	push   %edi
f0101976:	56                   	push   %esi
f0101977:	53                   	push   %ebx
f0101978:	83 ec 1c             	sub    $0x1c,%esp
f010197b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010197f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101983:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101987:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010198b:	85 c0                	test   %eax,%eax
f010198d:	75 19                	jne    f01019a8 <__udivdi3+0x38>
f010198f:	39 f3                	cmp    %esi,%ebx
f0101991:	76 4d                	jbe    f01019e0 <__udivdi3+0x70>
f0101993:	31 ff                	xor    %edi,%edi
f0101995:	89 e8                	mov    %ebp,%eax
f0101997:	89 f2                	mov    %esi,%edx
f0101999:	f7 f3                	div    %ebx
f010199b:	89 fa                	mov    %edi,%edx
f010199d:	83 c4 1c             	add    $0x1c,%esp
f01019a0:	5b                   	pop    %ebx
f01019a1:	5e                   	pop    %esi
f01019a2:	5f                   	pop    %edi
f01019a3:	5d                   	pop    %ebp
f01019a4:	c3                   	ret    
f01019a5:	8d 76 00             	lea    0x0(%esi),%esi
f01019a8:	39 f0                	cmp    %esi,%eax
f01019aa:	76 14                	jbe    f01019c0 <__udivdi3+0x50>
f01019ac:	31 ff                	xor    %edi,%edi
f01019ae:	31 c0                	xor    %eax,%eax
f01019b0:	89 fa                	mov    %edi,%edx
f01019b2:	83 c4 1c             	add    $0x1c,%esp
f01019b5:	5b                   	pop    %ebx
f01019b6:	5e                   	pop    %esi
f01019b7:	5f                   	pop    %edi
f01019b8:	5d                   	pop    %ebp
f01019b9:	c3                   	ret    
f01019ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019c0:	0f bd f8             	bsr    %eax,%edi
f01019c3:	83 f7 1f             	xor    $0x1f,%edi
f01019c6:	75 48                	jne    f0101a10 <__udivdi3+0xa0>
f01019c8:	39 f0                	cmp    %esi,%eax
f01019ca:	72 06                	jb     f01019d2 <__udivdi3+0x62>
f01019cc:	31 c0                	xor    %eax,%eax
f01019ce:	39 eb                	cmp    %ebp,%ebx
f01019d0:	77 de                	ja     f01019b0 <__udivdi3+0x40>
f01019d2:	b8 01 00 00 00       	mov    $0x1,%eax
f01019d7:	eb d7                	jmp    f01019b0 <__udivdi3+0x40>
f01019d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019e0:	89 d9                	mov    %ebx,%ecx
f01019e2:	85 db                	test   %ebx,%ebx
f01019e4:	75 0b                	jne    f01019f1 <__udivdi3+0x81>
f01019e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019eb:	31 d2                	xor    %edx,%edx
f01019ed:	f7 f3                	div    %ebx
f01019ef:	89 c1                	mov    %eax,%ecx
f01019f1:	31 d2                	xor    %edx,%edx
f01019f3:	89 f0                	mov    %esi,%eax
f01019f5:	f7 f1                	div    %ecx
f01019f7:	89 c6                	mov    %eax,%esi
f01019f9:	89 e8                	mov    %ebp,%eax
f01019fb:	89 f7                	mov    %esi,%edi
f01019fd:	f7 f1                	div    %ecx
f01019ff:	89 fa                	mov    %edi,%edx
f0101a01:	83 c4 1c             	add    $0x1c,%esp
f0101a04:	5b                   	pop    %ebx
f0101a05:	5e                   	pop    %esi
f0101a06:	5f                   	pop    %edi
f0101a07:	5d                   	pop    %ebp
f0101a08:	c3                   	ret    
f0101a09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a10:	89 f9                	mov    %edi,%ecx
f0101a12:	ba 20 00 00 00       	mov    $0x20,%edx
f0101a17:	29 fa                	sub    %edi,%edx
f0101a19:	d3 e0                	shl    %cl,%eax
f0101a1b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a1f:	89 d1                	mov    %edx,%ecx
f0101a21:	89 d8                	mov    %ebx,%eax
f0101a23:	d3 e8                	shr    %cl,%eax
f0101a25:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101a29:	09 c1                	or     %eax,%ecx
f0101a2b:	89 f0                	mov    %esi,%eax
f0101a2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a31:	89 f9                	mov    %edi,%ecx
f0101a33:	d3 e3                	shl    %cl,%ebx
f0101a35:	89 d1                	mov    %edx,%ecx
f0101a37:	d3 e8                	shr    %cl,%eax
f0101a39:	89 f9                	mov    %edi,%ecx
f0101a3b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101a3f:	89 eb                	mov    %ebp,%ebx
f0101a41:	d3 e6                	shl    %cl,%esi
f0101a43:	89 d1                	mov    %edx,%ecx
f0101a45:	d3 eb                	shr    %cl,%ebx
f0101a47:	09 f3                	or     %esi,%ebx
f0101a49:	89 c6                	mov    %eax,%esi
f0101a4b:	89 f2                	mov    %esi,%edx
f0101a4d:	89 d8                	mov    %ebx,%eax
f0101a4f:	f7 74 24 08          	divl   0x8(%esp)
f0101a53:	89 d6                	mov    %edx,%esi
f0101a55:	89 c3                	mov    %eax,%ebx
f0101a57:	f7 64 24 0c          	mull   0xc(%esp)
f0101a5b:	39 d6                	cmp    %edx,%esi
f0101a5d:	72 19                	jb     f0101a78 <__udivdi3+0x108>
f0101a5f:	89 f9                	mov    %edi,%ecx
f0101a61:	d3 e5                	shl    %cl,%ebp
f0101a63:	39 c5                	cmp    %eax,%ebp
f0101a65:	73 04                	jae    f0101a6b <__udivdi3+0xfb>
f0101a67:	39 d6                	cmp    %edx,%esi
f0101a69:	74 0d                	je     f0101a78 <__udivdi3+0x108>
f0101a6b:	89 d8                	mov    %ebx,%eax
f0101a6d:	31 ff                	xor    %edi,%edi
f0101a6f:	e9 3c ff ff ff       	jmp    f01019b0 <__udivdi3+0x40>
f0101a74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a78:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101a7b:	31 ff                	xor    %edi,%edi
f0101a7d:	e9 2e ff ff ff       	jmp    f01019b0 <__udivdi3+0x40>
f0101a82:	66 90                	xchg   %ax,%ax
f0101a84:	66 90                	xchg   %ax,%ax
f0101a86:	66 90                	xchg   %ax,%ax
f0101a88:	66 90                	xchg   %ax,%ax
f0101a8a:	66 90                	xchg   %ax,%ax
f0101a8c:	66 90                	xchg   %ax,%ax
f0101a8e:	66 90                	xchg   %ax,%ax

f0101a90 <__umoddi3>:
f0101a90:	f3 0f 1e fb          	endbr32 
f0101a94:	55                   	push   %ebp
f0101a95:	57                   	push   %edi
f0101a96:	56                   	push   %esi
f0101a97:	53                   	push   %ebx
f0101a98:	83 ec 1c             	sub    $0x1c,%esp
f0101a9b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101a9f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101aa3:	8b 7c 24 3c          	mov    0x3c(%esp),%edi
f0101aa7:	8b 6c 24 38          	mov    0x38(%esp),%ebp
f0101aab:	89 f0                	mov    %esi,%eax
f0101aad:	89 da                	mov    %ebx,%edx
f0101aaf:	85 ff                	test   %edi,%edi
f0101ab1:	75 15                	jne    f0101ac8 <__umoddi3+0x38>
f0101ab3:	39 dd                	cmp    %ebx,%ebp
f0101ab5:	76 39                	jbe    f0101af0 <__umoddi3+0x60>
f0101ab7:	f7 f5                	div    %ebp
f0101ab9:	89 d0                	mov    %edx,%eax
f0101abb:	31 d2                	xor    %edx,%edx
f0101abd:	83 c4 1c             	add    $0x1c,%esp
f0101ac0:	5b                   	pop    %ebx
f0101ac1:	5e                   	pop    %esi
f0101ac2:	5f                   	pop    %edi
f0101ac3:	5d                   	pop    %ebp
f0101ac4:	c3                   	ret    
f0101ac5:	8d 76 00             	lea    0x0(%esi),%esi
f0101ac8:	39 df                	cmp    %ebx,%edi
f0101aca:	77 f1                	ja     f0101abd <__umoddi3+0x2d>
f0101acc:	0f bd cf             	bsr    %edi,%ecx
f0101acf:	83 f1 1f             	xor    $0x1f,%ecx
f0101ad2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101ad6:	75 40                	jne    f0101b18 <__umoddi3+0x88>
f0101ad8:	39 df                	cmp    %ebx,%edi
f0101ada:	72 04                	jb     f0101ae0 <__umoddi3+0x50>
f0101adc:	39 f5                	cmp    %esi,%ebp
f0101ade:	77 dd                	ja     f0101abd <__umoddi3+0x2d>
f0101ae0:	89 da                	mov    %ebx,%edx
f0101ae2:	89 f0                	mov    %esi,%eax
f0101ae4:	29 e8                	sub    %ebp,%eax
f0101ae6:	19 fa                	sbb    %edi,%edx
f0101ae8:	eb d3                	jmp    f0101abd <__umoddi3+0x2d>
f0101aea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101af0:	89 e9                	mov    %ebp,%ecx
f0101af2:	85 ed                	test   %ebp,%ebp
f0101af4:	75 0b                	jne    f0101b01 <__umoddi3+0x71>
f0101af6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101afb:	31 d2                	xor    %edx,%edx
f0101afd:	f7 f5                	div    %ebp
f0101aff:	89 c1                	mov    %eax,%ecx
f0101b01:	89 d8                	mov    %ebx,%eax
f0101b03:	31 d2                	xor    %edx,%edx
f0101b05:	f7 f1                	div    %ecx
f0101b07:	89 f0                	mov    %esi,%eax
f0101b09:	f7 f1                	div    %ecx
f0101b0b:	89 d0                	mov    %edx,%eax
f0101b0d:	31 d2                	xor    %edx,%edx
f0101b0f:	eb ac                	jmp    f0101abd <__umoddi3+0x2d>
f0101b11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b18:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b1c:	ba 20 00 00 00       	mov    $0x20,%edx
f0101b21:	29 c2                	sub    %eax,%edx
f0101b23:	89 c1                	mov    %eax,%ecx
f0101b25:	89 e8                	mov    %ebp,%eax
f0101b27:	d3 e7                	shl    %cl,%edi
f0101b29:	89 d1                	mov    %edx,%ecx
f0101b2b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b2f:	d3 e8                	shr    %cl,%eax
f0101b31:	89 c1                	mov    %eax,%ecx
f0101b33:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b37:	09 f9                	or     %edi,%ecx
f0101b39:	89 df                	mov    %ebx,%edi
f0101b3b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101b3f:	89 c1                	mov    %eax,%ecx
f0101b41:	d3 e5                	shl    %cl,%ebp
f0101b43:	89 d1                	mov    %edx,%ecx
f0101b45:	d3 ef                	shr    %cl,%edi
f0101b47:	89 c1                	mov    %eax,%ecx
f0101b49:	89 f0                	mov    %esi,%eax
f0101b4b:	d3 e3                	shl    %cl,%ebx
f0101b4d:	89 d1                	mov    %edx,%ecx
f0101b4f:	89 fa                	mov    %edi,%edx
f0101b51:	d3 e8                	shr    %cl,%eax
f0101b53:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b58:	09 d8                	or     %ebx,%eax
f0101b5a:	f7 74 24 08          	divl   0x8(%esp)
f0101b5e:	89 d3                	mov    %edx,%ebx
f0101b60:	d3 e6                	shl    %cl,%esi
f0101b62:	f7 e5                	mul    %ebp
f0101b64:	89 c7                	mov    %eax,%edi
f0101b66:	89 d1                	mov    %edx,%ecx
f0101b68:	39 d3                	cmp    %edx,%ebx
f0101b6a:	72 06                	jb     f0101b72 <__umoddi3+0xe2>
f0101b6c:	75 0e                	jne    f0101b7c <__umoddi3+0xec>
f0101b6e:	39 c6                	cmp    %eax,%esi
f0101b70:	73 0a                	jae    f0101b7c <__umoddi3+0xec>
f0101b72:	29 e8                	sub    %ebp,%eax
f0101b74:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0101b78:	89 d1                	mov    %edx,%ecx
f0101b7a:	89 c7                	mov    %eax,%edi
f0101b7c:	89 f5                	mov    %esi,%ebp
f0101b7e:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101b82:	29 fd                	sub    %edi,%ebp
f0101b84:	19 cb                	sbb    %ecx,%ebx
f0101b86:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101b8b:	89 d8                	mov    %ebx,%eax
f0101b8d:	d3 e0                	shl    %cl,%eax
f0101b8f:	89 f1                	mov    %esi,%ecx
f0101b91:	d3 ed                	shr    %cl,%ebp
f0101b93:	d3 eb                	shr    %cl,%ebx
f0101b95:	09 e8                	or     %ebp,%eax
f0101b97:	89 da                	mov    %ebx,%edx
f0101b99:	83 c4 1c             	add    $0x1c,%esp
f0101b9c:	5b                   	pop    %ebx
f0101b9d:	5e                   	pop    %esi
f0101b9e:	5f                   	pop    %edi
f0101b9f:	5d                   	pop    %ebp
f0101ba0:	c3                   	ret    
