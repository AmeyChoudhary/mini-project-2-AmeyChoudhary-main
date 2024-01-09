#include "headers.h"

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
    int server_socketA, server_socketB;
    struct sockaddr_in server_addr_A, server_addr_B, client_addr_A, client_addr_B;
    socklen_t client_addr_len_A = sizeof(client_addr_A);
    socklen_t client_addr_len_B = sizeof(client_addr_B);
    char bufferA[MAX_BUFFER_SIZE];
    char bufferB[MAX_BUFFER_SIZE];
    char choiceA[MAX_BUFFER_SIZE];
    char choiceB[MAX_BUFFER_SIZE];

    server_socketA = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socketA == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address for clientA
    server_addr_A.sin_family = AF_INET;
    server_addr_A.sin_port = htons(PORT_A);
    server_addr_A.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket for clientA
    if (bind(server_socketA, (struct sockaddr *)&server_addr_A, sizeof(server_addr_A)) == -1)
    {
        perror("Binding failed");
        close(server_socketA);
        exit(1);
    }

    printf("Server is waiting for clientA to connect...\n");

    // Create socket for clientB
    server_socketB = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socketB == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address for clientB
    server_addr_B.sin_family = AF_INET;
    server_addr_B.sin_port = htons(PORT_B);
    server_addr_B.sin_addr.s_addr = INADDR_ANY;
    
    // Bind the socket for clientB
    if (bind(server_socketB, (struct sockaddr *)&server_addr_B, sizeof(server_addr_B)) == -1)
    {
        perror("Binding failed");
        close(server_socketB);
        exit(1);
    }

    printf("Server is waiting for clientB to connect...\n");


    while (1)
    {
        printf("\nRock, Paper, Scissors Game\n");
        // Receive choices from both clients
        ssize_t recv_bytesA = recvfrom(server_socketA, choiceA, sizeof(choiceA), 0,
                                       (struct sockaddr *)&client_addr_A, &client_addr_len_A);

        if(recv_bytesA == -1)
        {
            perror("Receiving data from clients failed");
            close(server_socketA);
            close(server_socketB);
            exit(1);
        }


        choiceA[recv_bytesA] = '\0';


        ssize_t recv_bytesB = recvfrom(server_socketB, choiceB, sizeof(choiceB), 0,
                                        (struct sockaddr *)&client_addr_B, &client_addr_len_B); 

        if ( recv_bytesB <= 0)
        {
            perror("Receiving data from clients failed");
            close(server_socketA);
            close(server_socketB);
            exit(1);
        }

        choiceB[recv_bytesB] = '\0';

        printf("Received choice from client A: %s\n", choiceA);
        printf("Received choice from client B: %s\n", choiceB);

        // Determine the winner
        char *result = determineWinner(choiceA, choiceB);

        // Send the result back to both clients
        if(sendto(server_socketA, result, strlen(result), 0, (struct sockaddr*)&client_addr_A, client_addr_len_A) == -1 ||
            sendto(server_socketB, result, strlen(result), 0, (struct sockaddr*)&client_addr_B, client_addr_len_B) == -1)
        {
            perror("Sending data to clients failed");
            close(server_socketA);
            close(server_socketB);
            exit(1);
        }

        printf("Result sent to clients: %s\n", result);

        // Prompt for another game
        char playAgainA[MAX_BUFFER_SIZE];
        char playAgainB[MAX_BUFFER_SIZE];

        ssize_t recv_bytesA2 = recvfrom(server_socketA, playAgainA, sizeof(playAgainA), 0,
                                       (struct sockaddr *)&client_addr_A, &client_addr_len_A);
        
        if (recv_bytesA2 <= 0)
        {
            perror("Receiving playAgain data from clients failed");
            close(server_socketA);
            close(server_socketB);
            exit(1);
        }

        playAgainA[recv_bytesA2] = '\0';

        ssize_t recv_bytesB2 = recvfrom(server_socketB, playAgainB, sizeof(playAgainB), 0,
                                        (struct sockaddr *)&client_addr_B, &client_addr_len_B);


        if (recv_bytesB2 <= 0)
        {
            perror("Receiving playAgain data from clients failed");
            close(server_socketA);
            close(server_socketB);
            exit(1);
        }

        playAgainB[recv_bytesB2] = '\0';

        int nextRound = getNextRound(playAgainA, playAgainB);

        if (nextRound != 0)
        {
            printf("Next round: %d\n", nextRound);
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

            if( sendto(server_socketA, reason, strlen(reason), 0, (struct sockaddr*)&client_addr_A, client_addr_len_A) == -1 ||
                sendto(server_socketB, reason, strlen(reason), 0, (struct sockaddr*)&client_addr_B, client_addr_len_B) == -1 )
            {
                perror("Sending end signal to clients failed");
                close(server_socketA);
                close(server_socketB);
                exit(1);
            }

            break; // Exit the loop if either player doesn't want to play another game
        }
        else
        {
            // Send signal to both clients to start the next round
            if (sendto(server_socketA, "start", strlen("start"), 0, (struct sockaddr*)&client_addr_A, client_addr_len_A) == -1 ||
                sendto(server_socketB, "start", strlen("start"), 0, (struct sockaddr*)&client_addr_B, client_addr_len_B) == -1)
            {
                perror("Sending playAgain signal to clients failed");
                close(server_socketA);
                close(server_socketB);
                exit(1);
            }
        }
    }

    // Close sockets (moved outside of the game loop)
    close(server_socketA);
    close(server_socketB);

    return 0;
}
