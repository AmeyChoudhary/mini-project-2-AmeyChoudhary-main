#include "headers.h"

// Used ChatGPT and Copilot for assistance.

// Function to determine the winner
char *determineWinner(char *choiceA, char *choiceB)
{
    if (strcmp(choiceA, choiceB) == 0)
    {
        return "Draw";
    }
    else if ((strcmp(choiceA, "Rock") == 0 && strcmp(choiceB, "Scissors") == 0) ||
             (strcmp(choiceA, "Paper") == 0 && strcmp(choiceB, "Rock") == 0) ||
             (strcmp(choiceA, "Scissors") == 0 && strcmp(choiceB, "Paper") == 0))
    {

        return "Client A wins!";
    }
    else
    {
        return "Client B wins!";
    }
}

int getNextRound(char *playAgainA, char *playAgainB)
{
    if (strcmp(playAgainA, "no") == 0 && strcmp(playAgainB, "no") != 0)
    {
        return 1;
    }
    else if (strcmp(playAgainA, "no") != 0 && strcmp(playAgainB, "no") == 0)
    {
        return 2;
    }
    else if (strcmp(playAgainA, "no") == 0 && strcmp(playAgainB, "no") == 0)
    {
        return 3;
    }
    else
    {
        return 0;
    }
}

int main()
{
    int server_socket, client_socketA, client_socketB;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);
    char bufferA[MAX_BUFFER_SIZE];
    char bufferB[MAX_BUFFER_SIZE];
    char choiceA[MAX_BUFFER_SIZE];
    char choiceB[MAX_BUFFER_SIZE];

    // Create socket for clientA
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address for clientA
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT_A);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket for clientA
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    // Listen for incoming connections from clientA
    if (listen(server_socket, 1) == -1)
    {
        perror("Listening failed");
        close(server_socket);
        exit(1);
    }

    printf("Server is waiting for clientA to connect...\n");

    // Accept connection from clientA
    client_socketA = accept(server_socket, (struct sockaddr *)&client_addr, &client_addr_len);
    if (client_socketA == -1)
    {
        perror("Accepting clientA connection failed");
        close(server_socket);
        exit(1);
    }

    printf("Client A connected from %s:%d\n",
           inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));

    // Create socket for clientB
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address for clientB
    server_addr.sin_port = htons(PORT_B);

    // Bind the socket for clientB
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    // Listen for incoming connections from clientB
    if (listen(server_socket, 1) == -1)
    {
        perror("Listening failed");
        close(server_socket);
        exit(1);
    }

    printf("Server is waiting for clientB to connect...\n");

    // Accept connection from clientB
    client_socketB = accept(server_socket, (struct sockaddr *)&client_addr, &client_addr_len);
    if (client_socketB == -1)
    {
        perror("Accepting clientB connection failed");
        close(server_socket);
        exit(1);
    }

    printf("Client B connected from %s:%d\n",
           inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));

    while (1)
    {
        printf("\nRock, Paper, Scissors Game\n");
        // Receive choices from both clients
        ssize_t recv_bytesA = recv(client_socketA, choiceA, sizeof(choiceA), 0);
        ssize_t recv_bytesB = recv(client_socketB, choiceB, sizeof(choiceB), 0);

        if (recv_bytesA <= 0 || recv_bytesB <= 0)
        {
            perror("Receiving data from clients failed");
            close(client_socketA);
            close(client_socketB);
            close(server_socket);
            exit(1);
        }

        choiceA[recv_bytesA] = '\0';
        choiceB[recv_bytesB] = '\0';

        printf("Received choice from client A: %s\n", choiceA);
        printf("Received choice from client B: %s\n", choiceB);

        // Determine the winner
        char *result = determineWinner(choiceA, choiceB);

        // Send the result back to both clients
        if (send(client_socketA, result, strlen(result), 0) == -1 ||
            send(client_socketB, result, strlen(result), 0) == -1)
        {
            perror("Sending data to clients failed");
            close(client_socketA);
            close(client_socketB);
            close(server_socket);
            exit(1);
        }

        printf("Result sent to clients: %s\n", result);

        // Prompt for another game
        char playAgainA[MAX_BUFFER_SIZE];
        char playAgainB[MAX_BUFFER_SIZE];

        ssize_t recv_bytesA2 = recv(client_socketA, playAgainA, sizeof(playAgainA), 0);
        ssize_t recv_bytesB2 = recv(client_socketB, playAgainB, sizeof(playAgainB), 0);


        if (recv_bytesA2 <= 0 || recv_bytesB2 <= 0)
        {
            perror("Receiving playAgain data from clients failed");
            close(client_socketA);
            close(client_socketB);
            close(server_socket);
            exit(1);
        }

        playAgainA[recv_bytesA2] = '\0';
        playAgainB[recv_bytesB2] = '\0';

        int nextRound = getNextRound(playAgainA, playAgainB);

        if (nextRound != 0)
        {
            printf("Game ended\n");
            // Send signal to both clients to end the game

            char *reason;

            if (nextRound == 1)
            {
                reason = "Client A doesn't want to play another game";
            }
            else if (nextRound == 2)
            {
                reason = "Client B doesn't want to play another game";
            }
            else
            {
                reason = "Both clients don't want to play another game";
            }

            printf("Reason: %s\n", reason);

            if (send(client_socketA, reason, strlen(reason), 0) == -1 ||
                send(client_socketB, reason, strlen(reason), 0) == -1)
            {
                perror("Sending end signal to clients failed");
                close(client_socketA);
                close(client_socketB);
                close(server_socket);
                exit(1);
            }

            break; // Exit the loop if either player doesn't want to play another game
        }
        else
        {
            // Send signal to both clients to start the next round
            if (send(client_socketA, "start", strlen("start"), 0) == -1 ||
                send(client_socketB, "start", strlen("start"), 0) == -1)
            {
                perror("Sending playAgain signal to clients failed");
                close(client_socketA);
                close(client_socketB);
                close(server_socket);
                exit(1);
            }
        }
    }

    // Close sockets (moved outside of the game loop)
    close(client_socketA);
    close(client_socketB);
    close(server_socket);

    return 0;
}
