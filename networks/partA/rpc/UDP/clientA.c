#include "headers.h"

int main()
{
    int client_socket;
    struct sockaddr_in server_addr;
    char choice[MAX_BUFFER_SIZE];
    char response[MAX_BUFFER_SIZE];

    // Create socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT_A);

    if (inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr) <= 0)
    {
        perror("Invalid server address");
        close(client_socket);
        exit(1);
    }


    printf("Rock, Paper, Scissors Game (Player A)\n");
    while (1)
    {
        printf("Enter your choice (Rock, Paper, Scissors): ");
        fgets(choice, sizeof(choice), stdin);

        // remove newline character from choice
        choice[strlen(choice) - 1] = '\0';

        // Send the choice to the server
        if (sendto(client_socket, choice, strlen(choice), 0,
                   (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1)
        {
            perror("Sending choice to server failed");
            close(client_socket);
            exit(1);
        }

        // Wait for the result from the server
        socklen_t server_addr_len = sizeof(server_addr);
        ssize_t recv_bytes = recvfrom(client_socket, response, sizeof(response), 0,
                                      (struct sockaddr*)&server_addr, &server_addr_len);
        if (recv_bytes == -1)
        {
            perror("Receiving result from server failed");
            close(client_socket);
            exit(1);
        }

        response[recv_bytes] = '\0';
        printf("Result: %s\n", response);

        // Prompt for another game
        char playAgain[MAX_BUFFER_SIZE];
        printf("Do you want to play another game? (yes/no): ");
        fgets(playAgain, sizeof(playAgain), stdin);

        // remove newline character from playAgain
        playAgain[strlen(playAgain) - 1] = '\0';

        if (sendto(client_socket, playAgain, strlen(playAgain), 0,
                   (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1)
        {
            perror("Sending playAgain data to server failed");
            close(client_socket);
            exit(1);
        }

        // Wait for server to signal the next round
        ssize_t recv_bytes1 = recvfrom(client_socket, playAgain, sizeof(playAgain), 0,
                                       (struct sockaddr*)&server_addr, &server_addr_len);
        if (recv_bytes1 <= 0)
        {
            perror("Receiving playAgain signal from server failed");
            close(client_socket);
            exit(1);
        }
        playAgain[recv_bytes1] = '\0';
        if (strcmp(playAgain, "start") != 0)
        {
            printf("Game ended\n");
            printf("Reason: %s\n", playAgain);
            break;
        }
    }

    // Close socket
    close(client_socket);

    return 0;
}
