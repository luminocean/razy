#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>

// quit current process with an error message
int quit(const char *msg){
    perror(msg);
    exit(1);
}

int create_tcp_server(int port){
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if( bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0 )
        quit("bind error");

    if( listen(server_fd, 1024) < 0 )
        quit("listen error");

    return server_fd;
}

int accept_client_socket(int server_fd){
    struct sockaddr_in addr;
    socklen_t client_len = sizeof(addr);

    int client_fd;
    if( (client_fd = accept(server_fd, (struct sockaddr *)&addr, &client_len)) < 0 )
        quit("accept error");

    return client_fd;
}