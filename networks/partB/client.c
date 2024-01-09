// Implemet the client side of TCP socket programming
// Used ChatGPT and Copilot for assistance.

#include "headers.h"

int *ack;
struct timeval *transmission_times;

struct ThreadArgs
{
    char **chunks;
    int num_chunks;
    struct sockaddr_in server_addr;
    int client_socket;
};

struct Chunk
{
    char chunk[CHUNKSIZE];
    int chunk_index;
    int total_chunks;
    int sent_counter;
};

// function to send array of chunks to the server
void *send_chunks(void *args)
{
    struct ThreadArgs thread_args = *(struct ThreadArgs *)args;
    char **chunks = thread_args.chunks;
    int num_chunks = thread_args.num_chunks;
    struct sockaddr_in server_addr = thread_args.server_addr;
    int client_socket = thread_args.client_socket;

    transmission_times = (struct timeval *)malloc(num_chunks * sizeof(struct timeval));

    // Send chunks to the server
    for (int i = 0; i < num_chunks; i++)
    {
        struct Chunk chunk;
        strcpy(chunk.chunk, chunks[i]);
        chunk.chunk_index = i;
        chunk.total_chunks = num_chunks;
        chunk.sent_counter = 1;

        // Send chunk to the server
        if (sendto(client_socket, &chunk, sizeof(chunk), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
        {
            perror("Error in sending message");
            close(client_socket);
            exit(1);
        }
        else
        {
            gettimeofday(&transmission_times[i], NULL);
            printf("Chunk %d with message %s sent to the server\n", i, chunk.chunk);
        }
    }
}

// function to receive acknowledgement from the server
void *receive_acks(void *args)
{
    struct ThreadArgs thread_args = *(struct ThreadArgs *)args;
    int client_socket = thread_args.client_socket;
    struct sockaddr_in server_addr = thread_args.server_addr;
    int num_chunks = thread_args.num_chunks;
    // making a acknoledgement array to keep track of the chunks received

    ack = (int *)malloc(num_chunks * sizeof(int));

    // Receive acknowledgement from the server
    for (int i = 0; i < num_chunks; i++)
    {
        struct Chunk chunk;
        socklen_t server_addr_len = sizeof(server_addr);
        if (recvfrom(client_socket, &chunk, sizeof(chunk), 0, (struct sockaddr *)&server_addr, &server_addr_len) == -1)
        {
            perror("Error in receiving message");
            close(client_socket);
            exit(1);
        }
        else
        {

            ack[chunk.chunk_index] = 1;
            printf("Acknowledgement received for chunk %d\n", chunk.chunk_index);
        }
    }
}

// function to resend chunks to the server, if acknowledgement is not received and timeout occurs
void *resend_chunks(void *args)
{
    struct ThreadArgs thread_args = *(struct ThreadArgs *)args;
    int client_socket = thread_args.client_socket;
    struct sockaddr_in server_addr = thread_args.server_addr;
    int num_chunks = thread_args.num_chunks;
    char **chunks = thread_args.chunks;

    // Resend chunks to the server
    for (int i = 0; i < num_chunks; i++)
    {
        struct Chunk chunk;
        strcpy(chunk.chunk, chunks[i]);
        chunk.chunk_index = i;
        chunk.total_chunks = num_chunks;
        chunk.sent_counter = 1;

        // Resend chunk to the server if acknowledgement is not received and timeout occurs
        while (ack[i] != 1 && chunk.sent_counter < MAX_RESEND)
        {
            struct timeval current_time;
            gettimeofday(&current_time, NULL);
            timersub(&current_time, &transmission_times[i], &current_time);
            if (current_time.tv_sec > TIMEOUT)
            {
                if (sendto(client_socket, &chunk, sizeof(chunk), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
                {
                    perror("Error in sending message");
                    close(client_socket);
                    exit(1);
                }
                else
                {
                    gettimeofday(&transmission_times[i], NULL);
                    printf("Chunk %d with message %s sent to the server\n", i, chunk.chunk);
                }
                chunk.sent_counter++;
            }
        }
    }
}

// function to divide the message into chunks and send back an array of chunks
char **divide_message(char *message, int chunk_size)
{
    int num_chunks = strlen(message) / chunk_size;
    int remainder = 0;
    if (strlen(message) % chunk_size != 0) // if there is a remainder, add one more chunk
    {
        remainder = 1;
        num_chunks++;
    }
    char **chunks = (char **)malloc(num_chunks * sizeof(char *));
    for (int i = 0; i < num_chunks; i++)
    {
        chunks[i] = (char *)malloc(chunk_size * sizeof(char));
        for (int j = 0; j < chunk_size; j++)
        {
            chunks[i][j] = message[i * chunk_size + j];
        }
    }
    // terminate each chunk with a null character
    for (int i = 0; i < num_chunks - 1; i++)
    {
        chunks[i][chunk_size] = '\0';
    }

    if (remainder == 0)
    {
        chunks[num_chunks - 1][chunk_size] = '\0';
    }
    else
    {
        chunks[num_chunks - 1][strlen(message) % chunk_size] = '\0';
    }
    return chunks;
}

// function to send message to the server
void send_message()
{
    char message_client[STRINGSIZE];
    int client_socket;
    struct sockaddr_in server_addr;
    printf("Enter the input message: ");
    fgets(message_client, STRINGSIZE, stdin);
    message_client[strlen(message_client) - 1] = '\0';
    char message[STRINGSIZE];
    strcpy(message, message_client);

    // Create socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    if (inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr) <= 0)
    {
        perror("Invalid server address");
        close(client_socket);
        exit(1);
    }

    // Divide the message into chunks
    char **chunks = divide_message(message, CHUNKSIZE);
    // Number of chunks to the server
    int num_chunks = strlen(message) / CHUNKSIZE;
    if (strlen(message) % CHUNKSIZE != 0) // if there is a remainder, add one more chunk
    {
        num_chunks++;
    }

    if (sendto(client_socket, &num_chunks, sizeof(num_chunks), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Error in sending message");
        close(client_socket);
        exit(1);
    }
    else
    {
        printf("Number of chunks sent to the server are %d with length %ld\n", num_chunks, strlen(message));
    }

    // creating threads for sending , receiving and resending the chunks
    pthread_t send_thread, receive_thread, resend_thread;
    struct ThreadArgs thread_args;
    thread_args.chunks = chunks;
    thread_args.num_chunks = num_chunks;
    thread_args.server_addr = server_addr;
    thread_args.client_socket = client_socket;
    pthread_create(&send_thread, NULL, send_chunks, (void *)&thread_args);
    pthread_create(&receive_thread, NULL, receive_acks, (void *)&thread_args);
    pthread_create(&resend_thread, NULL, resend_chunks, (void *)&thread_args);

    // wait for the threads to finish
    pthread_join(send_thread, NULL);
    pthread_join(receive_thread, NULL);
    pthread_join(resend_thread, NULL);

    // close the socket
    close(client_socket);

    // free the memory allocated to the chunks
    for (int i = 0; i < num_chunks; i++)
    {
        free(chunks[i]);
    }
}

// function to receive message from the server
void receive_message()
{
    printf("Waiting for server to send message...\n");
    // Now, receive the message from the server
    int client_socket;
    struct sockaddr_in server_addr;
    socklen_t server_addr_len = sizeof(server_addr);

    // Create socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);

    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind socket to the server address
    if (bind(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Error in binding socket to the server address");
        close(client_socket);
        exit(1);
    }

    // Receive message from the server about the number of chunks being transmitted
    int num_chunks_received;
    if (recvfrom(client_socket, &num_chunks_received, sizeof(num_chunks_received), 0, (struct sockaddr *)&server_addr, &server_addr_len) == -1)
    {
        perror("Error in receiving message");
        close(client_socket);
        exit(1);
    }
    else
    {
        printf("Number of chunks received from the server are %d\n", num_chunks_received);
    }

    int received_chunks[num_chunks_received];
    memset(received_chunks, 0, num_chunks_received * sizeof(int));

    // Receive chunks from the server
    char **chunks_received = (char **)malloc(num_chunks_received * sizeof(char *));
    for (int i = 0; i < num_chunks_received; i++)
    {
        struct Chunk chunk;
        // socklen_t server_addr_len = sizeof(server_addr);
        if (recvfrom(client_socket, &chunk, sizeof(chunk), 0, (struct sockaddr *)&server_addr, &server_addr_len) == -1)
        {
            perror("Error in receiving message");
            close(client_socket);
            exit(1);
        }
        else if (received_chunks[chunk.chunk_index] == 0)
        {

            chunks_received[chunk.chunk_index] = (char *)malloc(CHUNKSIZE * sizeof(char));
            strcpy(chunks_received[chunk.chunk_index], chunk.chunk);
            printf("Chunk %d with message %s received from the server\n", chunk.chunk_index, chunk.chunk);
            received_chunks[chunk.chunk_index] = 1;
            // Send acknowledgement to the client
            if (sendto(client_socket, &chunk, sizeof(chunk), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
            {
                perror("Error in sending message");
                close(client_socket);
                exit(1);
            }
            else
            {
                printf("Acknowledgement sent for chunk %d\n", chunk.chunk_index);
            }
        }
        else
        {
            i--;
        }
    }
    // close the socket
    close(client_socket);

    // reconstruct the message from the chunks
    char message[STRINGSIZE];
    message[0] = '\0';
    for (int i = 0; i < num_chunks_received; i++)
    {
        strcat(message, chunks_received[i]);
    }
    printf("The message received from the server is %s with length %ld\n", message, strlen(message));
}

int main()
{
    while (1)
    {

        send_message();

        printf("\n\n\n");

        receive_message();
    }

    return 0;
}