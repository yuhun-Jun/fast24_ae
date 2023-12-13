#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

//all-in-one overwrite maker, YH

#define GET_SIZE_K(x)   ((x)*1024)
#define GET_SIZE_M(x)   ((x)*1024*1024)

#define SIZE_200M   (200*1024*1024)
#define SIZE_8192K   (8192*1024)
#define SIZE_1024K   (1024*1024)
#define SIZE_128K   (128*1024)
#define SIZE_64K   (64*1024)
#define SIZE_16K    (16*1024)
#define SIZE_4K    (4*1024)

#define FILENAMELENGTH  (128)

//define at compile time
#if (0)
#define FILE_SIZE   (4*1024*1024)
#define APPEND_SIZE (32*1024)
#define WRITE_COUNT (FILE_SIZE/APPEND_SIZE)
#define DUMMYAPPEND_SIZE (64*1024)
#define OPT_DIRECT       (1)
#endif
//

#define READ_ITER       (10)
#define DUMMYAPPEND_UNIT    (4096)
#define DUMMYFILECOUNT (DUMMYAPPEND_SIZE/DUMMYAPPEND_UNIT)

typedef unsigned int UINT32;

int g_Targetfd;
int g_Dummyfd[DUMMYFILECOUNT];

char TargetFilename[FILENAMELENGTH];
char DummyFilename[1000];

void *writebuffer200m;
void *writebuffer8192k;
void *writebuffer128k;
void *readbuffer1024k;
void *readbuffer128k;

unsigned char writebuffer64k[64*1024];
unsigned char writebuffer16k[16*1024];

#if (OPT_DIRECT == 1)
    int Opt_Direct = O_DIRECT;
#else
    int Opt_Direct = 0;
#endif

void UserDelay(UINT32 nSec)
{
    printf("Waiting");
    fflush(stdout);
    while(nSec--)
    {
        printf(".");
        fflush(stdout);
        sleep(1);
    }
    printf("\n");
    fflush(stdout);

}

/*
 * timecheck function
 */
double GetTimeDiff(unsigned int nFlag){
    static struct timespec  begin, end;

    if(nFlag == 0){
        if(clock_gettime(CLOCK_MONOTONIC, &begin) == -1){
            printf("clock start failed\n");
        }
    } else{
        if(clock_gettime(CLOCK_MONOTONIC, &end) == -1){
            printf("clock start failed\n");
        }
        return ((end.tv_sec - begin.tv_sec) + (end.tv_nsec - begin.tv_nsec) / 1000000000.0);
    }

    return 0;
}

char const TargetFolder[]=TARGET_FOLDER;

extern char *program_invocation_short_name;

int main()
{
    UINT32 written = 0;
    UINT32 dummywritten = 0;
    UINT32 readsize = 0;

    double read1gap = 0;
    double read2gap = 0;
    UINT32 readiter = READ_ITER;

    UINT32 curwrite=0;
    UINT32 curReadSize;

    UINT32 dummyfilenum=0;

    printf("File size = %u, Append Size = %u, Write Count = %u, DummyAppend size = %u \n",FILE_SIZE,APPEND_SIZE, WRITE_COUNT,DUMMYAPPEND_SIZE  );
    printf("Target Folder = %s\n", TARGET_FOLDER);
    printf("Target File = %s\n", TARGET_FILENAME);
    printf("Direct = %u\n", Opt_Direct);
    printf("RAND = %u\n", RAND_DUMMY);

    posix_memalign(&writebuffer200m, getpagesize(), SIZE_200M);
    posix_memalign(&writebuffer128k, getpagesize(), SIZE_128K);
    posix_memalign(&readbuffer128k, getpagesize(), SIZE_128K);
    posix_memalign(&readbuffer1024k, getpagesize(), SIZE_1024K);

    printf("PID :%d NAME : %s\n", getpid(), program_invocation_short_name);

    //buffer init
    UINT32 Byte =0;
    while(Byte < SIZE_128K)
    {
        ((unsigned char *)writebuffer128k)[Byte++] = rand() & 0xFF;
    }
    while(Byte < SIZE_200M)
    {
        ((unsigned char *)writebuffer200m)[Byte++] = rand() & 0xFF;
    }
    
    //filelist setting
    sprintf(TargetFilename, "%s%s.data", TargetFolder, TARGET_FILENAME); 

    //printf("targetfilename=%s \n",TargetFilename);



    printf("File Creation\n");
    //creation and write
    g_Targetfd = open(TargetFilename, O_CREAT | O_TRUNC | O_RDWR | Opt_Direct, 0666);
    //O_DIRECT :read cache x
    //O_SYNC :write buffer x | O_DIRECT | O_SYNC
    if (g_Targetfd <0)
    {
        printf("error fd: %d\n",g_Targetfd);
        exit(0);
    }

    while(written < (FILE_SIZE))
        written += write(g_Targetfd, writebuffer200m, SIZE_1024K);

    printf("after create written: %u\n", written);


    fsync(g_Targetfd);        
    close(g_Targetfd);

    //UserDelay(10);


#if (CREAT_READ==1)
    printf("Read File\n");
    //read all
    readiter = READ_ITER;


    while(readiter--)
    {        
        //drop cache
        FILE* fp = fopen ("/proc/sys/vm/drop_caches", "w"); fprintf (fp, "3"); fclose (fp);
        UserDelay(5);

        curReadSize=0;
        g_Targetfd = open(TargetFilename, O_RDWR | O_DIRECT );
        //O_DIRECT :read cache x
        //O_SYNC :write buffer x
        if (g_Targetfd <0)
        {
            printf("error fd: %d\n",g_Targetfd);
            exit(0);
        }  

        struct timespec  begin, end;
        clock_gettime(CLOCK_MONOTONIC, &begin);
        while(curReadSize < FILE_SIZE)
            curReadSize += read(g_Targetfd, readbuffer1024k, SIZE_1024K);
        clock_gettime(CLOCK_MONOTONIC, &end);

        double localtime =((end.tv_sec - begin.tv_sec) + (end.tv_nsec - begin.tv_nsec) / 1000000000.0);
        printf("read 1: %.9lf s \n",localtime);
        
        read1gap += localtime;

        close(g_Targetfd);
        readsize+=curReadSize;
    }
//    UserDelay(10);
#endif

    printf("OverWrite File\n");

    printf("before overwrite written: %u\n", written);
    //overwrite
    UINT32 dwrite=0;

    g_Targetfd = open(TargetFilename, O_RDWR | Opt_Direct);	
    if (g_Targetfd < 0)
    {
        printf("error target fd: %d\n", g_Targetfd);
        exit(0);
    }  

    for (UINT32 Overwrite=0; Overwrite < WRITE_COUNT; Overwrite++)
    {            
        off_t seekpointresult = Overwrite * APPEND_SIZE;
#if (RAND_DUMMY ==1)
        UINT32 dummyappendsize = ((rand()%32)+1)*APPEND_SIZE; 
#else
        UINT32 dummyappendsize = DUMMYAPPEND_SIZE;
#endif
        //printf("writecount = %u, dummy = %u\n",Overwrite, dummyappendsize);

        //overwrite
        lseek(g_Targetfd, seekpointresult, SEEK_SET);
        
        written += write(g_Targetfd, writebuffer128k, APPEND_SIZE);
        fdatasync(g_Targetfd);        

        //dummy
        sprintf(DummyFilename, "%sD%d.data", TargetFolder, dummyfilenum); 
        dummyfilenum++;

        int Dummyfd = open(DummyFilename, O_CREAT | O_RDWR | O_APPEND | Opt_Direct, 0666);
        if (Dummyfd < 0)
        {            
            printf("error target fd: %d name : %s\n", Dummyfd, DummyFilename);
            exit(0);
        }  

        write(Dummyfd, writebuffer200m, dummyappendsize);
        fdatasync(Dummyfd);
        close(Dummyfd);

    }
    fsync(g_Targetfd);
    close(g_Targetfd);

    printf("dwrite = %u\n",dwrite);
    printf("after overwrite written: %u\n", written);

    // UserDelay(10);

    //read all
    printf("Read OverWritten File\n");

    readiter = READ_ITER;
    // UINT32 curReadSize;

    while(readiter--)
    {
        //drop cache
        FILE* fp = fopen ("/proc/sys/vm/drop_caches", "w"); fprintf (fp, "3"); fclose (fp);
        UserDelay(5);

        curReadSize=0;

        g_Targetfd = open(TargetFilename, O_RDWR | O_DIRECT );
        //O_DIRECT :read cache x
        //O_SYNC :write buffer x
        if (g_Targetfd <0)
            {
            printf("error fd: %d\n",g_Targetfd);
            exit(0);
        }  

        struct timespec  begin, end;
        clock_gettime(CLOCK_MONOTONIC, &begin);

        while(curReadSize < FILE_SIZE)
            curReadSize += read(g_Targetfd, readbuffer1024k, SIZE_1024K);
        
        clock_gettime(CLOCK_MONOTONIC, &end);

        double localtime =((end.tv_sec - begin.tv_sec) + (end.tv_nsec - begin.tv_nsec) / 1000000000.0);
        printf("read 1: %.9lf s \n",localtime);
        
        read2gap += localtime;
            
        close(g_Targetfd);
        readsize+=curReadSize;
    }
    //UserDelay(10);

    double read1time = (read1gap);
    double read2time = (read2gap);

    printf("%u written,  %u read !!!\n", written, readsize);
    printf("read 1 : %.9lf s read 2 : %.9lf s \n", read1time/READ_ITER, read2time/READ_ITER);


    free(writebuffer128k);
    free(writebuffer200m);
    free(readbuffer128k);
    free(readbuffer1024k);

    return 0;
}
