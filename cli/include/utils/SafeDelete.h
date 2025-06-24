#pragma once
#include <string>

class SafeDelete {
public:
    // Returns true if the path is safe to remove (inside project, not root, is directory)
    static bool is_safe_to_remove(const std::string& path);
    // Returns true if the directory contains forbidden files or folders (e.g. source code, project files)
    static bool contains_forbidden_files(const std::string& dir);
};
