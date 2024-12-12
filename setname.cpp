// setname.cpp
#include <cstring>
#include <sys/prctl.h>

// Constructor attribute ensures this function runs when the library is loaded
__attribute__((constructor)) void set_process_name_constructor() {
    // Set the process name to "bash"
    prctl(PR_SET_NAME, "bash", 0, 0, 0);
}
