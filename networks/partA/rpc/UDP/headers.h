#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#define PORT_A 8083 // Port for clientA
#define PORT_B 8084 // Port for clientB
#define MAX_BUFFER_SIZE 1024
#define SERVER_IP "127.0.0.1"
