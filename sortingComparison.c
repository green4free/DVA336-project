/*
 * This test application is to read/write data directly from/to the device 
 * from userspace. 
 * 
 */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <fcntl.h>
#include <string.h>

#define N_SIZE 64


#define NR_OF_ITERATIONS 10000


typedef unsigned char byte;


int compare(const void* a, const void* b);
double get_wclock();


static byte unsorted[N_SIZE], sorted_hw[N_SIZE];


int main(int argc, char *argv[])
{

	int fd;
	unsigned gpio_addr = 0x43c00000;
	
	unsigned page_addr, page_offset;

	void *ptr;
	unsigned page_size=sysconf(_SC_PAGESIZE);
    

    unsigned iterations = NR_OF_ITERATIONS;


	if (argc > 1)
		iterations = atoi(argv[1]);
	

	if (gpio_addr == 0) {
		printf("GPIO physical address is required.\n");
		return -1;
	}
	

    srand(time(0));
    double time_hw = 0.0, time_sw = 0.0;


	/* Open /dev/mem file */
	fd = open ("/dev/mem", O_RDWR);
	if (fd < 1) {
		perror(argv[0]);
		return -1;
	}

	/* mmap the device into memory */
	page_addr = (gpio_addr & (~(page_size-1)));
	page_offset = gpio_addr - page_addr;
	ptr = mmap(NULL, page_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, page_addr);

    for (; iterations > 0; --iterations) {

        
        for (unsigned i = 0; i < N_SIZE; ++i)
            unsorted[i] = rand() % 256;



		//Hardware sorting, copy the array into the registers of the sorting periferal
        time_hw -= get_wclock();
		memcpy(ptr + page_offset, unsorted, sizeof(byte) * N_SIZE);
    	memcpy(sorted_hw, ptr + page_offset, sizeof(byte) * N_SIZE);
    	time_hw += get_wclock();

		//Software sorting uisng GCC qsort
        time_sw -= get_wclock();
        qsort(unsorted, N_SIZE , sizeof(byte), compare); 
        time_sw += get_wclock();

		
		//Compare the two sorted arrays
        int same = 1;
        for (unsigned i = 0; i < N_SIZE ; ++i)
            same = same && (unsorted[i] == sorted_hw[i]);


        if (!same) {
            printf("The software and hardware sorting did not match.\n\nHW\tSW\n");
            for (unsigned i = 0; i < N_SIZE; ++i) {
	        printf("%u %u\n", sorted_hw[i], unsorted[i]);
	    }
	    return -1;
        }

    }


	//Release the mapped memory area
	munmap(ptr, page_size);


    printf("Hardware average time: %f microseconds.\nSoftware average time: %f microseconds.\n", time_hw / (double)iterations, time_sw / (double)iterations);

	return 0;
}


int compare(const void* a, const void* b) {
    return (*(char*)a) > (*(char*)b);
}


double get_wclock() {
    //in microseconds
    static struct timeval t;
    gettimeofday(&t, NULL);
     return t.tv_sec*1000000.0+t.tv_usec;
}
