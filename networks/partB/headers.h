#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <pthread.h>
#include <sys/time.h>

#define STRINGSIZE 1024
#define PORT 5000
#define CHUNKSIZE 5
#define SERVER_IP "127.0.0.1"
#define TIMEOUT 2
#define MAX_RESEND 3
