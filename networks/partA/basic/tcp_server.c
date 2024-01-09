#include "server_headers.h"

int main() {
    int server_socket, client_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);
    char buffer[MAX_BUFFER_SIZE];

    // Create socket
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
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

    // Listen for incoming connections
    if (listen(server_socket, 5) == -1) {
        perror("Listening failed");
        close(server_socket);
        exit(1);
    }

    printf("Server is listening on TCP port %d...\n", PORT);

    // Accept client connection
    client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_addr_len);
    if (client_socket == -1) {
        perror("Accepting client connection failed");
        close(server_socket);
        exit(1);
    }

    printf("Client connected from %s:%d\n",
           inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));

    // Receive data from client
    ssize_t recv_bytes = recv(client_socket, buffer, sizeof(buffer), 0);
    if (recv_bytes <= 0) {
        perror("Receiving data failed");
    } else {
        buffer[recv_bytes] = '\0';
        printf("Received message from client: %s\n", buffer);

        // Echo the received data back to the client
        if (send(client_socket, buffer, strlen(buffer), 0) == -1) {
            perror("Sending data to client failed");
        }
    }

    // Close sockets
    printf("Closing sockets...\n");
    close(client_socket);
    close(server_socket);

    return 0;
}
