#pragma once

#include <string>
#include <optional>
#include <vector>

struct Config {
  std::optional<std::string> project;
  std::optional<std::string> scheme;
  std::optional<std::string> configuration;
  std::optional<std::string> archive_path;
  std::optional<std::string> export_path;
  std::optional<std::string> export_options;

  // Returns a vector of missing required keys
  std::vector<std::string> validate() const;
};

class ConfigParser {
public:
  // Parse the given ini file. Throws std::runtime_error on failure.
  explicit ConfigParser(const std::string& ini_path);

  // Access the parsed config
  const Config& config() const;

private:
  Config config_;
  static int iniHandler(void* user, const char* section, const char* name, const char* value);
  void logMissingKeys(const std::vector<std::string>& missing) const;
};