#pragma once

#include <string>
#include <optional>
#include <vector>
struct Config {
  std::optional<std::string> ini_path;
  // [build]
  std::optional<std::string> project;
  std::optional<std::string> scheme;
  // [archive]
  std::optional<std::string> archive_configuration;
  std::optional<bool>        archive_destructive;
  // [dmg] section
  std::optional<std::string> dmg_name;
  std::optional<std::string> dmg_app_name;
  std::optional<std::string> dmg_volume_name;
  std::optional<bool> dmg_move_from_archive;

  // Returns a vector of missing required keys
  std::vector<std::string> validate() const;
};

class ConfigParser {
public:
  // Parse the given ini file. Throws std::runtime_error on failure.
  static Config parse(const std::string& ini_path);

  // Save the given config to the ini file. Returns true on success, false on failure.
  static bool save(const Config& config);

private:
  static int iniHandler(void* user, const char* section, const char* name, const char* value);
  static void logMissingKeys(const std::vector<std::string>& missing);
};