#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <sqlite3.h>

#define RECORDNUM     (10000)
#define SIZE_1024K   (1024*1024)
#define DUMMY_SIZE   (100*1024) //128-28
// #define TARGETFOLDER "./datafolder/"
#define READ_ITER   (10)
#define APPENDCOUNT (10000)

typedef unsigned int UINT32;
void *writebuffer1024k;
int dummyfile;

char DummyFilename[1000];
char DBFilename[1000];

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

void bufferSet(){
    posix_memalign(&writebuffer1024k, getpagesize(), SIZE_1024K);
    UINT32 Byte =0;
    while(Byte < SIZE_1024K)
    {
        ((unsigned char *)writebuffer1024k)[Byte++] = rand() & 0xFF;
    }
}

void fileSet(){
    printf("File Creation\n");
    //creation and write

    dummyfile = open(DummyFilename, O_CREAT | O_TRUNC | O_RDWR, 0666);
    //O_DIRECT :read cache x
    //O_SYNC :write buffer x | O_DIRECT | O_SYNC
    if (dummyfile <0)
    {
        printf("error fd: %d\n",dummyfile);
        exit(0);
    }

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


void randomString(char* string, int len){

    for(int i=0; i<len; i++){
        string[i] = 'a' + (rand() % 26);
    }
}

void dropCache(){
    sync();
    int fd = open("/proc/sys/vm/drop_caches", O_WRONLY);
    write(fd, "3", 1);
    close(fd);
}

int callback(void *NotUsed, int argc, char **argv, char **azColName)
{    
    NotUsed = 0;
    
    for (int i = 0; i < argc; i++)
    {
        printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
    }
    
    printf("\n");
    
    return 0;
}

extern char *program_invocation_short_name;



int main(void)
{
    sqlite3 *db;
    char *err_msg = 0;
    double timegap, timesum=0;
    UINT32 curwrite=0;
    UINT32 remain=0;
    UINT32 indexcount=0;

    static struct timespec  begin, end;

    sprintf(DummyFilename, "./%s/duymmy.data",TARGET_FOLDER); 
    sprintf(DBFilename, "./%s/testdb.db",TARGET_FOLDER); 

    bufferSet();
    fileSet();

    
    //database open
    int rc = sqlite3_open(DBFilename, &db);
    rc = sqlite3_exec(db, "PRAGMA journal_mode = off;", 0, 0, &err_msg);
    rc = sqlite3_exec(db, "PRAGMA journal_mode;", callback, 0, &err_msg);
    rc = sqlite3_exec(db, "PRAGMA synchronous = on;", 0, 0, &err_msg);
    rc = sqlite3_exec(db, "PRAGMA synchronous;", callback, 0, &err_msg);

    
    if (rc != SQLITE_OK)
    {
        fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        return 1;
    }


    //table creation
    char *createQ = "CREATE TABLE DB1(id INT PRIMARY KEY, str1 VARCHAR(4096), str2 VARCHAR(4096), str3 VARCHAR(4096), str4 VARCHAR(4094));";
        
    rc = sqlite3_exec(db, createQ, 0, 0, &err_msg);
    
    if (rc != SQLITE_OK )
    {
        fprintf(stderr, "Failed to create table: %s\n", err_msg);

        sqlite3_free(err_msg);
        sqlite3_close(db);
        return 1;
    } 

    dropCache();

    //record insert
    char rstr1[4096+1];
    char rstr2[4096+1];
    char rstr3[4096+1];
    char rstr4[4094+1];
    srand((unsigned int)time(NULL));

    dummyfile = open(DummyFilename, O_RDWR | O_APPEND);	    
    curwrite = 0;

    if (dummyfile <0)
    {
        printf("error fd: %d\n",dummyfile);
        exit(0);
    } 
    
    indexcount=0;
    for(int iter=RECORDNUM-1; iter>=0; iter--)
    {
        char* insertQ1;

        randomString(rstr1, 4096);
        rstr1[4096] = '\0';
        randomString(rstr2, 4096);
        rstr2[4096] = '\0';
        randomString(rstr3, 4096);
        rstr3[4096] = '\0';
        randomString(rstr4, 4094);
        rstr4[4094] = '\0';

        asprintf(&insertQ1, "INSERT INTO DB1 VALUES(%d, '%s', '%s', '%s', '%s');", iter, rstr1, rstr2, rstr3, rstr4);
        rc = sqlite3_exec(db, insertQ1, 0, 0, &err_msg);
        free(insertQ1);

        curwrite += write(dummyfile, writebuffer1024k, DUMMY_SIZE);
        fdatasync(dummyfile);

        indexcount++;
        if (indexcount == APPENDCOUNT)
            break;
    }
    
    close(dummyfile);
    printf("after dummy written: %u\n", curwrite);


    if (rc != SQLITE_OK )
    {
        fprintf(stderr, "Failed to insert record: %s\n", err_msg);

        sqlite3_free(err_msg);
        sqlite3_close(db);
        return 1;
    } 

    sqlite3_close(db);

#if 1
    //select record
    char *selcetQ = "select * from DB1;";

    for (int readcount=0; readcount < READ_ITER; readcount++)
    {
        dropCache();
        UserDelay(5);
        dropCache();
        UserDelay(5);

        rc = sqlite3_open(DBFilename, &db);
        rc = sqlite3_exec(db, "PRAGMA journal_mode = off;", 0, 0, &err_msg);
        rc = sqlite3_exec(db, "PRAGMA journal_mode;", callback, 0, &err_msg);
        rc = sqlite3_exec(db, "PRAGMA synchronous = off;", 0, 0, &err_msg);
        rc = sqlite3_exec(db, "PRAGMA synchronous;", callback, 0, &err_msg);

        
        if (rc != SQLITE_OK)
        {
            fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
            sqlite3_close(db);
            return 1;
        }


        if(clock_gettime(CLOCK_MONOTONIC, &begin) == -1){
            printf("clock start failed\n");
        }
        rc = sqlite3_exec(db, selcetQ, 0, 0, &err_msg);

        if(clock_gettime(CLOCK_MONOTONIC, &end) == -1){
            printf("clock start failed\n");
        }
        timegap = ((end.tv_sec - begin.tv_sec) + (end.tv_nsec - begin.tv_nsec) / 1000000000.0);
        printf("read %u, time: %.9lf\n", readcount, timegap);
        timesum += timegap;

        if (rc != SQLITE_OK )
        {
            fprintf(stderr, "Failed to select record: %s\n", err_msg);

            sqlite3_free(err_msg);
            sqlite3_close(db);
            return 1;
        } 

        sqlite3_close(db);

    }

    printf("Average read time: %.9lf\n", timesum/READ_ITER);
#endif

    
    return 0;
}
