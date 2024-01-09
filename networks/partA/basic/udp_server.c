#include "server_headers.h"

int main() {
    int server_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);
    char buffer[MAX_BUFFER_SIZE];

    // Create socket
    server_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socket == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    printf("Server is listening on UDP port %d...\n", PORT);
    
    // Receive data from client
    ssize_t recv_bytes = recvfrom(server_socket, buffer, sizeof(buffer), 0,
                                  (struct sockaddr*)&client_addr, &client_addr_len);
    if (recv_bytes == -1) {
        perror("Receiving data failed");
        close(server_socket);
        exit(1);
    }

    buffer[recv_bytes] = '\0';
    printf("Received message from client: %s\n", buffer);

    // Send a response back to the client
    char response[] = "Hello from server!";
    sendto(server_socket, response, strlen(response), 0,
           (struct sockaddr*)&client_addr, client_addr_len);

    // Close socket
    printf("Closing server socket...\n");
    close(server_socket);

    return 0;
}
