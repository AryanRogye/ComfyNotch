#include "utils/ProcessRunner.h"
#include "utils/Logger.h"
#include <future>
#include <cstdlib>

std::future<int> ProcessRunner::Run(ProcessType type, const Config& config) {
    Logger::Log("ProcessRunner::Run called for type " + std::to_string(static_cast<int>(type)));
    return std::async(std::launch::async, [type, config]() {
        switch (type) {
            case ProcessType::BuildArchive:
                return RunBuildArchive(config);
            case ProcessType::CreateDMG:
                return RunCreateDMG(config);
            // Add more cases as needed
            default:
                Logger::Log("Unknown ProcessType");
                return -1;
        }
    });
}

int ProcessRunner::RunBuildArchive(const Config& config) {
    if (!config.project || !config.scheme || !config.archive_configuration || !config.archive_path) {
        Logger::Log("Missing required config for BuildArchive");
        return 1;
    }
    std::string cmd = "xcodebuild -project '" + *config.project + "' -scheme '" + *config.scheme + "' -configuration '" + *config.archive_configuration + "' archive -archivePath '" + *config.archive_path + "' > /dev/null 2>&1";

    /// Make sure we delete the archive path if destructive is true
    if (config.archive_destructive && *config.archive_destructive) {
        if (std::filesystem::exists(*config.archive_path)) {
            Logger::Log("Destructive mode enabled, deleting existing archive at " + *config.archive_path);
            std::filesystem::remove_all(*config.archive_path);
        } else {
            Logger::Log("Destructive mode enabled, but no existing archive found at " + *config.archive_path);
        }
    }

    Logger::Log("Running: " + cmd);
    int result = std::system(cmd.c_str());
    if (result != 0) {
        Logger::Log("BuildArchive process failed with exit code " + std::to_string(result));
    }
    return result;
}

int ProcessRunner::RunCreateDMG(const Config& config) {
    if (!config.archive_path || !config.archive_export_path) {
        Logger::Log("Missing required config for CreateDMG");
        return 1;
    }
    std::string cmd = "hdiutil create -srcfolder '" + *config.archive_path + "' '" + *config.archive_export_path + "/ComfyNotch.dmg'";
    Logger::Log("Running: " + cmd);
    return 0;
}