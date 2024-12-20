// wrap.cpp
#include <iostream>
#include <cstring>
#include <vector>
#include <sys/prctl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <cstdlib>
#include <cerrno>
#include <libgen.h>


// Function to set the process name using prctl
bool set_process_name(const char* name) {
    if (prctl(PR_SET_NAME, name, 0, 0, 0) != 0) {
        perror("prctl");
        return false;
    }
    return true;
}

// Function to overwrite argv[0]
void overwrite_argv0(char* argv0, const char* new_name) {
    size_t len = strlen(new_name);
    size_t argv0_len = strlen(argv0);
    if (len > argv0_len) {
        // If new_name is longer, overwrite up to argv0_len
        strncpy(argv0, new_name, argv0_len);
    } else {
        // If new_name is shorter or equal, overwrite and pad with null bytes
        strncpy(argv0, new_name, len);
        memset(argv0 + len, '\0', argv0_len - len);
    }
}

// Function to resolve a command name to an absolute path using the PATH environment variable
std::string resolve_command_path(const char* command) {
    // If the command contains a '/', treat it as an absolute or relative path
    if (strchr(command, '/')) {
        return std::string(command);
    }

    // Get the PATH environment variable
    const char* path_env = getenv("PATH");
    if (!path_env) {
        return "";
    }

    // Split PATH into directories
    std::vector<std::string> paths;
    const char* start = path_env;
    const char* end = nullptr;
    while ((end = strchr(start, ':')) != nullptr) {
        paths.emplace_back(start, end);
        start = end + 1;
    }
    paths.emplace_back(start);

    // Search for the command in each directory
    for (const auto& dir : paths) {
        std::string full_path = dir + "/" + command;
        if (access(full_path.c_str(), X_OK) == 0) {
            return full_path; // Found the executable
        }
    }

    return ""; // Command not found
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: ./wrap <command> [args...]" << std::endl;
        return EXIT_FAILURE;
    }

    // Set wrap's own process name
    overwrite_argv0(argv[0], "bash");
    if (!set_process_name("bash")) {
        std::cerr << "Failed to set wrap process name." << std::endl;
        return EXIT_FAILURE;
    }

    // Fork a child process
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return EXIT_FAILURE;
    }

    if (pid == 0) {
        // Child process

        // Overwrite argv[0] for the child process
        overwrite_argv0(argv[0], "bash");

        // Set up the LD_PRELOAD environment variable to load setname.so
        // Assumes setname.so is in the same directory as the wrap
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) == nullptr) {
            perror("getcwd");
            exit(EXIT_FAILURE);
        }

        char exe_path[1024];
        ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
        if (len == -1) {
            perror("readlink");
            return EXIT_FAILURE;
        }
        exe_path[len] = '\0';
        std::string wrap_dir = dirname(exe_path);
        std::string preload_path = std::string("LD_PRELOAD=") + wrap_dir + "/setname.so";

        // Prepare the new environment variables
        // It's safer to inherit the existing environment and append LD_PRELOAD
        extern char** environ;
        std::vector<std::string> new_env_strings;
        bool ld_preload_set = false;

        for (char** env = environ; *env != nullptr; ++env) {
            std::string env_var(*env);
            if (env_var.find("LD_PRELOAD=") == 0) {
                // Append setname.so to existing LD_PRELOAD
                env_var += ":" + std::string(cwd) + "/setname.so";
                ld_preload_set = true;
            }
            new_env_strings.push_back(env_var);
        }

        if (!ld_preload_set) {
            // If LD_PRELOAD wasn't set, add it
            new_env_strings.push_back(preload_path);
        }

        // Convert the environment variables to the format required by execve
        std::vector<char*> new_env;
        for (auto& env_str : new_env_strings) {
            new_env.push_back(const_cast<char*>(env_str.c_str()));
        }
        new_env.push_back(nullptr); // Null-terminate the array

        // Resolve the command to an absolute path
        std::string command_path = resolve_command_path(argv[1]);
        if (command_path.empty()) {
            std::cerr << "Command not found: " << argv[1] << std::endl;
            exit(EXIT_FAILURE);
        }

        // Prepare arguments for exec
        std::vector<char*> exec_args;
        exec_args.push_back(const_cast<char*>("bash")); // Fake argv[0]
        for (int i = 2; i < argc; ++i) {
            exec_args.push_back(argv[i]);
        }
        exec_args.push_back(nullptr);

        // Execute the command with the modified environment
        if (execve(command_path.c_str(), exec_args.data(), new_env.data()) == -1) {
            perror("execve");
            exit(EXIT_FAILURE);
        }
    } else {
        // Parent process
        int status;
        pid_t wpid;
        do {
            wpid = waitpid(pid, &status, 0);
        } while (wpid == -1 && errno == EINTR);

        if (wpid == -1) {
            perror("waitpid");
            return EXIT_FAILURE;
        }

        if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        } else if (WIFSIGNALED(status)) {
            std::cerr << "Child terminated by signal " << WTERMSIG(status) << std::endl;
            return EXIT_FAILURE;
        } else {
            std::cerr << "Child terminated abnormally." << std::endl;
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
