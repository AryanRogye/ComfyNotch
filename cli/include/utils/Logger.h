#pragma once
#include <string>
#include <fstream>
#include <memory>
#include <vector>
#include <mutex>
#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include "comfyx_paths.h"

class Logger {
public:
    // Initialize logger for this run (call once at program start)
    static void Init();
    // Log a message (thread-safe)
    static void Log(const std::string& message);
    // Get the current log file path
    static std::string CurrentLogFile();
    // FTXUI component to show the log in the UI
    static ftxui::Component LogComponent();
    // For internal use: get the log lines
    static std::vector<std::string> GetLogLines();
private:
    static std::unique_ptr<std::ofstream> log_stream;
    static std::string log_file_path;
    static std::vector<std::string> log_lines;
    static std::mutex logger_mutex;
    static void EnsureLogDir();
    static std::string GetLogDir() {
        return comfyx::kLogsDir;
    }
};
