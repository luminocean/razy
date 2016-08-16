#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/event.h>
#include <sys/types.h>
#include <errno.h>
#include <string.h>
#include <errno.h>
#include <string.h>

const static int MAX_FD_NUM = 1024;
const static int BUFFER_SIZE = 1024;

struct kevent changes[MAX_FD_NUM];
struct kevent events[MAX_FD_NUM];

int ready_fds[MAX_FD_NUM];
int ready_fd_modes[MAX_FD_NUM];

int k = 0; // next kevent object index
int kq; // a kqueue object

/**
 * utility functions
 */

// turn on fd flags
void turn_on_flags(int fd, int flags){
    int current_flags;
    // get and set fd flags
    if( (current_flags = fcntl(fd, F_GETFL)) < 0 ) exit(1);

    current_flags |= flags;
    if( fcntl(fd, F_SETFL, current_flags) < 0 ) exit(1);
}

// quit current process with an error message
int quit(const char *msg){
    perror(msg);
    exit(1);
}

/**
 * main functions
 */
// initialize IO multiplexing functionalities
// this function must be called before any other subsequent calls
void multiplex_initialize(){
    if( (kq = kqueue()) == -1 ) quit("kqueue error");
}

// set file descriptors in the kqueue with specified mode
// mode 1 is for read, 2 is for write, so 1 | 2 indicates both reading and writing
void multiplex_set(int *fd, int *mode, int n){
    k = 0; // reset the index k

    int i;
    for(i=0; i<n; i++){
        int ev_mode = 0;
        int j = 1;
        if( mode[i] & j ) ev_mode |= EVFILT_READ;
        j = j << 1;
        if( mode[i] & j ) ev_mode |= EVFILT_WRITE;

        if( k == MAX_FD_NUM ) quit("fd queue overflow");
        EV_SET(&changes[k++], fd[i], ev_mode, EV_ADD | EV_ENABLE, 0, 0, 0);
    }
}

// returns ready_fds's size
int multiplex_wait(){
    int nev = kevent(kq, changes, k, events, MAX_FD_NUM, NULL);
    int i;
    for(i=0; i<nev; i++){
        struct kevent event = events[i];
        if( event.flags & EV_ERROR ){
            quit(strerror(event.data));
        }
        ready_fds[i] = (int)event.ident;

        int mode = 0;
        if(event.filter & EVFILT_READ) mode = mode | 1;
        if(event.filter & EVFILT_WRITE) mode = mode | 2;
        ready_fd_modes[i] = mode;
    }
    return nev;
}

// expose ready_fds to ruby code
int multiplex_ready_fd(int index){
    return ready_fds[index];
}

// expose ready_fd_modes to ruby code
int multiplex_ready_fd_mode(int index){
    return ready_fd_modes[index];
}