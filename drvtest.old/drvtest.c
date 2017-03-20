#include <dos.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <alloc.h>
#include <string.h>
#include <math.h>
#include <limits.h>

void sector_rw(int operation, unsigned long sector_high,
	unsigned long sector_low, char far *dap, char far *sector_buffer,
   int *string_len, char value_num) {

   char cur_chs_string[1024];
   double sector_double;
   int i;
   union REGS inregs;
   union REGS outregs;
   struct SREGS segregs;

	*((char *)(dap + 0x00)) = 0x10;				/* Size of packet */
   *((unsigned int *)(dap + 0x02)) = 0x01;	/* Number of sectors */
   *((unsigned int *)(dap + 0x04)) = FP_OFF(sector_buffer);	/* buffer low */
	*((unsigned int *)(dap + 0x06)) = FP_SEG(sector_buffer); /* buffer high */
   *((unsigned long *)(dap + 0x08)) = sector_low; /* low bits of sector */
   *((unsigned long *)(dap + 0x0c)) = sector_high; /* high bits of sector */

	sector_double = sector_low + pow(2, 32) * sector_high;

   if (operation == 0) {
	  	sprintf(&cur_chs_string[0],
				"Writing %g, value = %u", sector_double, value_num);
   } else {
   	sprintf(&cur_chs_string[0],
      		"Reading %g, value = %u", sector_double, value_num);
   }

	for (i = 0; i < *string_len; i++) {
  		printf("\b");
   }

   printf("%s", &cur_chs_string);

   *string_len = strlen(&cur_chs_string[0]);

   if (operation == 0) {
		for (i = 0; i < 512; i++) {
			*(sector_buffer + i) = value_num;
	   }

		inregs.h.ah = 0x43;
		inregs.h.al = 0x02;

   } else {
   	inregs.h.ah = 0x42;
   }

	inregs.h.dl = 0x80;
   inregs.x.si = FP_OFF(dap);
   segregs.ds = FP_SEG(dap);

	int86x(0x13, &inregs, &outregs, &segregs);

   if ((outregs.x.cflag) || (outregs.h.ah)) {
		printf("\nError: %hu in sector %g, value %d\n", outregs.h.ah,
      	sector_double, value_num);
      exit(1);
   }

   if (operation == 1) {
		for (i = 0; i < 512; i++) {
			if (*(sector_buffer + i) != value_num) {
         	printf("\nError in sector %g, value was %d, should be %d\n",
            	sector_double, *(sector_buffer + i), value_num);
         }
	   }
   }
}

int main (void) {
	union REGS inregs;
   union REGS outregs;
   struct SREGS segregs;
   char far *sector_in_buf;
   char far *sector_out_buf;
   unsigned long max_sector_high;
   unsigned long max_sector_low;
   double sector_double;
   unsigned long high;
   unsigned long low;

   int string_len;
	char far *dpt;
   char far *dap;
   int i;

   unsigned char value_num;
   int value_int;

   sector_in_buf = (char far *)farmalloc(512);
   sector_out_buf = (char far *)farmalloc(512);
   dpt = (char far *)farmalloc(0x42);
   dap = (char far *)farmalloc(0x18);

   inregs.h.ah = 0x48;
	inregs.h.dl = 0x80;
   segregs.ds = FP_SEG(dpt);
   inregs.x.si = FP_OFF(dpt);

   value_num = 0;

   for (i = 0; i <= 0x41; i++) {
   	*(dpt + i) = 0;
   }

	*((unsigned int *)(dpt + 0x00)) = 0x42;

   int86x(0x13, &inregs, &outregs, &segregs);

   if ((outregs.x.cflag) || (outregs.h.ah)) {
   	printf("Error getting drive parameters (%u).\n", outregs.h.ah);
      exit (4);
   }

   max_sector_low = *((unsigned long *)(dpt + 0x10));
   max_sector_high = *((unsigned long *)(dpt + 0x14));

	sector_double = max_sector_low + pow(2, 32) * max_sector_high;
   printf("%g sectors on hard drive\n", sector_double);

   printf("Done init.\n");

	for (value_int = 0; value_int <= 255; value_int++) {

      string_len = 0;

      /* WRITE */
      for (high = max_sector_high; high > 0; high--) {
      	for (low = ULONG_MAX; low > 0; low--) {
         	sector_rw(0, high, low, dap, sector_out_buf, &string_len, value_num);
         }
         /* low == 0 */
         sector_rw(0, high, 0, dap, sector_out_buf, &string_len, value_num);
      }

      printf("\nWriting last %lu sectors.\n", low);

      /* high == 0 */
      for (low = max_sector_low; low > 0; low--) {
      	sector_rw(0, 0, low, dap, sector_out_buf, &string_len, value_num);
      }

      printf("Finished writing all sectors.\n");

      /* READ */
      for (high = max_sector_high; high > 0; high--) {
      	for (low = ULONG_MAX; low > 0; low--) {
         	sector_rw(1, high, low, dap, sector_in_buf, &string_len, value_num);
         }
         /* low == 0 */
         sector_rw(1, high, 0, dap, sector_in_buf, &string_len, value_num);
      }

      /* high == 0 */
      for (low = max_sector_low; low > 0; low--) {
      	sector_rw(1, 0, low, dap, sector_in_buf, &string_len, value_num);
      }
   }
   printf("\nDone testing all sectors with all values.\n");
   return 0;
}
