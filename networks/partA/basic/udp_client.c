#include "server_headers.h"

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    char buffer[MAX_BUFFER_SIZE];
    char input_string[MAX_BUFFER_SIZE];
    printf("Enter the input message: ");
    scanf("%s", input_string);
    char message[MAX_BUFFER_SIZE];
    strncpy(message, input_string, MAX_BUFFER_SIZE);

    // Create socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client_socket == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    if (inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr) <= 0) {
        perror("Invalid server address");
        close(client_socket);
        exit(1);
    }

    // Send data to the server
    sendto(client_socket, message, strlen(message), 0,
           (struct sockaddr*)&server_addr, sizeof(server_addr));

    printf("Message sent to server: %s\n", message);

    // Receive response from the server
    socklen_t server_addr_len = sizeof(server_addr);
    ssize_t recv_bytes = recvfrom(client_socket, buffer, sizeof(buffer), 0,
                                  (struct sockaddr*)&server_addr, &server_addr_len);
    if (recv_bytes == -1) {
        perror("Receiving data failed");
        close(client_socket);
        exit(1);
    }

    buffer[recv_bytes] = '\0';
    printf("Received response from server: %s\n", buffer);

    // Close socket
    close(client_socket);

    return 0;
}
