#include "utils/ProcessRunner.h"
#include "utils/Logger.h"
#include <future>
#include <cstdlib>

// Add a root data directory for all generated files
std::string comfyx_data_root = "ComfyXData";

namespace {
    std::string DataPath(const Config& config, const std::string& subdir) {
        // No longer use config.comfyx_data_root, always use fixed root
        std::string root = "ComfyXData";
        return root + "/" + subdir;
    }
}

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
    if (!config.project || !config.scheme || !config.archive_configuration) {
        Logger::Log("Missing required config for BuildArchive");
        return 1;
    }

    // Use fixed ComfyXData subfolders for all generated paths
    std::string archive_dir = "ComfyXData/Archive";
    std::string export_dir = "ComfyXData/Export";
    std::string updates_dir = "ComfyXData/Updates";
    std::filesystem::create_directories(archive_dir);
    std::filesystem::create_directories(export_dir);
    std::filesystem::create_directories(updates_dir);
    std::string archive_path = archive_dir + "/ComfyNotch.xcarchive";
    std::string archive_export_path = export_dir;
    std::string dmg_folder = updates_dir;

    std::string cmd = "xcodebuild -project '" + *config.project + "' -scheme '" + *config.scheme + "' -configuration '" + *config.archive_configuration + "' archive -archivePath '" + archive_path + "' > /dev/null 2>&1";

    if (config.archive_destructive && *config.archive_destructive) {
        if (std::filesystem::exists(archive_path)) {
            Logger::Log("Destructive mode enabled, deleting existing archive at " + archive_path);
            std::filesystem::remove_all(archive_path);
        } else {
            Logger::Log("Destructive mode enabled, but no existing archive found at " + archive_path);
        }
    }

    Logger::Log("Running: " + cmd);
    int result = std::system(cmd.c_str());
    if (result != 0) {
        Logger::Log("BuildArchive process failed with exit code " + std::to_string(result));
    }

    // Always use ExportOptions.plist from ComfyXData/Export if present, else fallback to config/ExportOptions.plist
    std::string export_options = "ComfyXData/Export/ExportOptions.plist";
    if (!std::filesystem::exists(export_options)) {
        export_options = "config/ExportOptions.plist";
    }
    if (result != 0) {
        Logger::Log("Archive step failed, skipping export step.");
        return result;
    }

    cmd = "xcodebuild -exportArchive -archivePath '" + archive_path + "' -exportPath '" + archive_export_path + "' -exportOptionsPlist '" + export_options + "' > /dev/null 2>&1";

    if (config.archive_destructive && *config.archive_destructive) {
        if (std::filesystem::exists(archive_export_path)) {
            Logger::Log("Destructive mode enabled, deleting existing export at " + archive_export_path);
            std::filesystem::remove_all(archive_export_path);
        } else {
            Logger::Log("Destructive mode enabled, but no existing export found at " + archive_export_path);
        }
    }

    Logger::Log("Running export command: " + cmd);
    result = std::system(cmd.c_str());
    if (result != 0) {
        Logger::Log("Export process failed with exit code " + std::to_string(result));
    } else {
        Logger::Log("Export completed successfully to " + archive_export_path);
    }

    return result;
}

int ProcessRunner::RunCreateDMG(const Config& config) {
    std::string dmg_folder = "ComfyXData/Updates";
    std::filesystem::create_directories(dmg_folder);
    if (!config.dmg_app_name || !config.dmg_name || !config.dmg_volume_name) {
        Logger::Log("Missing required config for CreateDMG");
        return 1;
    }

    // Always copy from fixed export path
    std::string src = "ComfyXData/Export/" + *config.dmg_app_name;
    std::string dst = dmg_folder + "/" + *config.dmg_app_name;
    std::error_code ec;
    if (std::filesystem::exists(src)) {
        std::filesystem::create_directories(dmg_folder, ec); // Ensure target folder exists
        Logger::Log("Copying .app from " + src + " to " + dst);
        std::filesystem::copy(src, dst, std::filesystem::copy_options::recursive | std::filesystem::copy_options::overwrite_existing, ec);
        if (ec) {
            Logger::Log("Failed to copy .app: " + ec.message());
            return 1;
        } else {
            Logger::Log(".app copied successfully to " + dst);
        }
    } else {
        Logger::Log("Source .app does not exist at " + src + ", cannot copy .app.");
        return 1;
    }

    // Always use just the filename for DMG, output folder is dmg_folder
    std::string dmg_filename = *config.dmg_name;
    // If the user provided a path, strip to just the filename
    size_t last_slash = dmg_filename.find_last_of("/\\");
    if (last_slash != std::string::npos) {
        dmg_filename = dmg_filename.substr(last_slash + 1);
    }
    std::string full_dmg_path = dmg_folder + "/" + dmg_filename;
    std::string cmd = "create-dmg --volname '" + *config.dmg_volume_name +
                      "' --window-pos 200 120 --window-size 800 400 --icon-size 100" +
                      " --icon '" + *config.dmg_app_name + "' 200 190 --hide-extension '" + *config.dmg_app_name + "'" +
                      " --app-drop-link 600 185 '" +  full_dmg_path + "' '" + dmg_folder + "' > /dev/null 2>&1";

    Logger::Log("Running CreateDMG command: " + cmd);

    int result = std::system(cmd.c_str());

    if (result != 0) {
      Logger::Log("CreateDMG process failed with exit code " +
                  std::to_string(result));
    } else {
      Logger::Log("DMG created successfully at " + full_dmg_path);
    }

    return result;
}


// create-dmg \
//     --volname "ComfyNotch Installer" \
//     --window-pos 200 120 \
//     --window-size 800 400 \
//     --icon-size 100 \
//     --icon "ComfyNotch.app" 200 190 \
//     --hide-extension "ComfyNotch.app" \
//     --app-drop-link 600 185 \
//     "ComfyNotch-Installer.dmg" \
//     "./"
