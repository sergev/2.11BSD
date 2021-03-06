.\" Copyright (c) 1983 Regents of the University of California.
.\" All rights reserved.  The Berkeley software License Agreement
.\" specifies the terms and conditions for redistribution.
.\"
.\"	@(#)1.2.t	6.8 (Berkeley) 5/14/86
.\"
.sh "Memory management\(dg
.NH 3
Text, data and stack
.PP
.FS
\(dg This section represents the interface planned for later
releases of the system.  Of the calls described in this section,
only \fIsbrk\fP and \fIgetpagesize\fP are included in 4.3BSD.
.FE
Each process begins execution with three logical areas of memory
called text, data and stack.  
The text area is read-only and shared, while the data and stack
areas are private to the process.  Both the data and stack areas may
be extended and contracted on program request.  The call
.DS
addr = sbrk(incr);
result caddr_t addr; int incr;
.DE
changes the size of the data area by \fIincr\fP bytes and
returns the new end of the data area, while
.DS
addr = sstk(incr);
result caddr_t addr; int incr;
.DE
changes the size of the stack area.
The stack area is also automatically extended as needed.
On the VAX the text and data areas are adjacent in the P0 region,
while the stack section is in the P1 region, and grows downward.
.NH 3
Mapping pages
.PP
The system supports sharing of data between processes
by allowing pages to be mapped into memory.  These mapped
pages may be \fIshared\fP with other processes or \fIprivate\fP
to the process.
Protection and sharing options are defined in \fI<sys/mman.h>\fP as:
.DS
.ta \w'#define\ \ 'u +\w'MAP_HASSEMPHORE\ \ 'u +\w'0x0080\ \ 'u
/* protections are chosen from these bits, or-ed together */
#define	PROT_READ	0x04	/* pages can be read */
#define	PROT_WRITE	0x02	/* pages can be written */
#define	PROT_EXEC	0x01	/* pages can be executed */

/* flags contain mapping type, sharing type and options */
/* mapping type; choose one */
#define MAP_FILE	0x0001	/* mapped from a file or device */
#define MAP_ANON	0x0002	/* allocated from memory, swap space */
#define MAP_TYPE	0x000f	/* mask for type field */

/* sharing types; choose one */
#define	MAP_SHARED	0x0010	/* share changes */
#define	MAP_PRIVATE	0x0000	/* changes are private */

/* other flags */
#define MAP_FIXED	0x0020	/* map addr must be exactly as requested */
#define MAP_NOEXTEND	0x0040	/* for MAP_FILE, don't change file size */
#define MAP_HASSEMPHORE	0x0080	/* region may contain semaphores */
#define MAP_INHERIT	0x0100	/* region is retained after exec */
.DE
The cpu-dependent size of a page is returned by the
\fIgetpagesize\fP system call:
.DS
pagesize = getpagesize();
result int pagesize;
.DE
.PP
The call:
.DS
maddr = mmap(addr, len, prot, flags, fd, pos);
result caddr_t maddr; caddr_t addr; int *len, prot, flags, fd; off_t pos;
.DE
causes the pages starting at \fIaddr\fP and continuing
for at most \fIlen\fP bytes to be mapped from the object represented by
descriptor \fIfd\fP, starting at byte offset \fIpos\fP.
The starting address of the region is returned;
for the convenience of the system,
it may be different than that supplied
unless the MAP_FIXED flag is given,
in which case the exact address will be used or the call will fail.
The actual amount mapped is returned in \fIlen\fP.
The \fIaddr\fP, \fIlen\fP, and \fIpos\fP parameters
must all be multiples of the pagesize.
The parameter \fIprot\fP specifies the accessibility
of the mapped pages.
The parameter \fIflags\fP specifies
the type of object to be mapped,
mapping options, and
whether modifications made to
this mapped copy of the page
are to be kept \fIprivate\fP, or are to be \fIshared\fP with
other references.
Possible types include MAP_FILE,
mapping a regular file or character-special device memory,
and MAP_ANON, which maps memory not associated with any specific file.
The file descriptor used for creating MAP_ANON regions is used only
for naming, and may be given as \-1 if no name
is associated with the region\(dd.
.FS
\(dd The current design does not allow a process
to specify the location of swap space.
In the future we may define an additional mapping type, MAP_SWAP,
in which the file descriptor argument specifies a file
or device to which swapping should be done.
.FE
The MAP_NOEXTEND flag prevents the mapped file from being extended
despite rounding due to the granularity of mapping.
The MAP_HASSEMAPHORE flag allows special handling for
regions that may contain semaphores.
The MAP_INHERIT flag allows a region to be inherited after an \fIexec\fP.
.PP
A facility is provided to synchronize a mapped region with the file
it maps; the call
.DS
msync(addr, len);
caddr_t addr; int len;
.DE
writes any modified pages back to the filesystem and updates
the file modification time.
If \fIlen\fP is 0, all modified pages within the region containing \fIaddr\fP
will be flushed;
if \fIlen\fP is non-zero, only the pages containing \fIaddr\fP and \fIlen\fP
succeeding locations will be examined.
Any required invalidation of memory caches will also take place at this time.
Filesystem operations on a file which is mapped for shared modifications
are unpredictable except after an \fImsync\fP.
.PP
A mapping can be removed by the call
.DS
munmap(addr);
caddr_t addr;
.DE
This call deletes the region containing the address given,
and causes further references to addresses within the region
to generate invalid memory references.
.NH 3
Page protection control
.PP
A process can control the protection of pages using the call
.DS
mprotect(addr, len, prot);
caddr_t addr; int len, prot;
.DE
This call changes the specified pages to have protection \fIprot\fP\|.
Not all implementations will guarantee protection on a page basis;
the granularity of protection changes may be as large as an entire region.
.NH 3
Giving and getting advice
.PP
A process that has knowledge of its memory behavior may
use the \fImadvise\fP call:
.DS
madvise(addr, len, behav);
caddr_t addr; int len, behav;
.DE
\fIBehav\fP describes expected behavior, as given
in \fI<sys/mman.h>\fP:
.DS
.ta \w'#define\ \ 'u +\w'MADV_SEQUENTIAL\ \ 'u +\w'00\ \ \ \ 'u
#define	MADV_NORMAL	0	/* no further special treatment */
#define	MADV_RANDOM	1	/* expect random page references */
#define	MADV_SEQUENTIAL	2	/* expect sequential references */
#define	MADV_WILLNEED	3	/* will need these pages */
#define	MADV_DONTNEED	4	/* don't need these pages */
#define	MADV_SPACEAVAIL	5	/* insure that resources are reserved */
.DE
Finally, a process may obtain information about whether pages are
core resident by using the call
.DS
mincore(addr, len, vec)
caddr_t addr; int len; result char *vec;
.DE
Here the current core residency of the pages is returned
in the character array \fIvec\fP, with a value of 1 meaning
that the page is in-core.
.NH 3
Synchronization primitives
.PP
Primitives are provided for synchronization using semaphores in shared memory.
Semaphores must lie within a MAP_SHARED region with at least modes
PROT_READ and PROT_WRITE.
The MAP_HASSEMAPHORE flag must have been specified when the region was created.
To acquire a lock a process calls:
.DS
value = mset(sem, wait)
result int value; semaphore *sem; int wait;
.DE
\fIMset\fP indivisibly tests and sets the semaphore \fIsem\fP.
If the the previous value is zero, the process has acquired the lock
and \fImset\fP returns true immediately.
Otherwise, if the \fIwait\fP flag is zero,
failure is returned.
If \fIwait\fP is true and the previous value is non-zero,
the ``want'' flag is set and the test-and-set is retried;
if the lock is still unavailable \fImset\fP relinquishes the processor
until notified that it should retry.
.LP
To release a lock a process calls:
.DS
mclear(sem)
semaphore *sem;
.DE
\fIMclear\fP indivisibly tests and clears the semaphore \fIsem\fP.
If the ``want'' flag is zero in the previous value,
\fImclear\fP returns immediately.
If the ``want'' flag is non-zero in the previous value,
\fImclear\fP arranges for waiting processes to retry before returning.
.PP
Two routines provide services analogous to the kernel
\fIsleep\fP and \fIwakeup\fP functions interpreted in the domain of
shared memory.
A process may relinquish the processor by calling \fImsleep\fP:
.DS
msleep(sem)
semaphore *sem;
.DE
The process will remain in a sleeping state
until some other process issues an \fImwakeup\fP for the same semaphore
within the region using the call:
.DS
mwakeup(sem)
semaphore *sem;
.DE
An \fImwakeup\fP may awaken all sleepers on the semaphore,
or may awaken only the next sleeper on a queue.
