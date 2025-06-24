#include "utils/Logger.h"
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <vector>
#include <mutex>
#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>

std::unique_ptr<std::ofstream> Logger::log_stream;
std::string Logger::log_file_path;
std::vector<std::string> Logger::log_lines;
std::mutex Logger::logger_mutex;

void Logger::EnsureLogDir() {
    std::filesystem::create_directories("logs");
}

void Logger::Init() {
    EnsureLogDir();
    // Use timestamp for unique log file name
    auto now = std::chrono::system_clock::now();
    auto t = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << "logs/cli_run_" << std::put_time(std::localtime(&t), "%Y%m%d_%H%M%S") << ".log";
    log_file_path = ss.str();
    log_stream = std::make_unique<std::ofstream>(log_file_path, std::ios::out | std::ios::app);
    Log("--- Logger started ---");
}

void Logger::Log(const std::string& message) {
    std::lock_guard<std::mutex> lock(logger_mutex);
    if (log_stream && log_stream->is_open()) {
        auto now = std::chrono::system_clock::now();
        auto t = std::chrono::system_clock::to_time_t(now);
        std::stringstream ss;
        ss << std::put_time(std::localtime(&t), "%H:%M:%S") << " | " << message;
        std::string line = ss.str();
        *log_stream << line << std::endl;
        log_lines.push_back(line);
        // Limit log_lines to last 200 lines
        if (log_lines.size() > 200) log_lines.erase(log_lines.begin(), log_lines.begin() + (log_lines.size() - 200));
    }
}

std::vector<std::string> Logger::GetLogLines() {
    std::lock_guard<std::mutex> lock(logger_mutex);
    return log_lines;
}

ftxui::Component Logger::LogComponent() {
    using namespace ftxui;
    return ftxui::Renderer([] {
        auto lines = Logger::GetLogLines();
        ftxui::Elements elements;
        for (const auto& line : lines) {
            elements.push_back(ftxui::text(line));
        }
        return ftxui::vbox(std::move(elements)) | ftxui::border | ftxui::size(ftxui::HEIGHT, ftxui::LESS_THAN, 10);
    });
}

std::string Logger::CurrentLogFile() {
    return log_file_path;
}
