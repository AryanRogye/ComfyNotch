#pragma once

#include <config.h>
#include <future>

// Enum for process types
enum class ProcessType {
    BuildArchive,
    CreateDMG,
    // Add more as needed
};

class ProcessRunner {
public:
    // Run a process based on the type and config, returns a future for async result
    static std::future<int> Run(ProcessType type, const Config& config);

private:
    static int RunBuildArchive(const Config& config);
    static int RunCreateDMG(const Config& config);
};
