# Mini Project 2 Networks

Amey Choudhary

2021113017

## Disclaimer

I have utilised ChatGPT and Copilot for assistance.

## Part A

### Basic

- Implemented TCP and UDP with error handling. PORT taken is 8081.

### RPC

- Implemented Rock Paper Scissors game in both TCP and UDP. PORTs are 8083 and 8084 for clients. 

- Assumed server is running and then clientA connects, followed by clientB.

## Part B 

- Compile with `gcc client.c -o client -pthread` & `gcc server.c -o server -pthread`
- Run server with `./server` and client with `./client`
- The client will send a message to the server first  and the server will receive and acknowledge it.
- Then the server will send a message to the client and the client will receive and acknowledge it.
- Happens in a while loop and can be exited by pressing `Ctrl+C` on both client and server.

Report in Reports folder, under "MP2 Networking Report.pdf"