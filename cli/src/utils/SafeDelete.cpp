#include "utils/SafeDelete.h"
#include "comfyx_paths.h"
using namespace comfyx;
#include <filesystem>
#include <set>

bool SafeDelete::is_safe_to_remove(const std::string& path) {
    if (path.empty()) return false;
    std::filesystem::path abs_path = std::filesystem::absolute(path);
    std::filesystem::path data_root = std::filesystem::absolute(comfyx::kDataRoot);
    // Only allow deletion inside the ComfyXData directory
    if (abs_path == "/" || abs_path == data_root || abs_path.string().find(data_root.string()) != 0)
        return false;
    if (!std::filesystem::is_directory(abs_path)) return false;
    return true;
}

bool SafeDelete::contains_forbidden_files(const std::string& dir) {
    static const std::set<std::string> forbidden_exts = {
        ".xcodeproj", ".xcworkspace", ".swift", ".h", ".hpp", ".c", ".cpp", ".m", ".mm"
    };
    static const std::set<std::string> forbidden_names = {
        ".xcodeproj", ".xcworkspace"
    };
    namespace fs = std::filesystem;
    fs::path root(dir);
    if (!fs::exists(root) || !fs::is_directory(root)) return false;
    for (auto& entry : fs::recursive_directory_iterator(root)) {
        if (entry.is_regular_file()) {
            auto ext = entry.path().extension().string();
            if (forbidden_exts.count(ext)) return true;
        }
        if (entry.is_directory()) {
            auto name = entry.path().filename().string();
            if (forbidden_names.count(name)) return true;
        }
    }
    return false;
}
