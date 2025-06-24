#include "config.h"
#include "ini.h"
#include <stdexcept>
#include <cstring>
#include <iostream>

/// Function to validate the configuration and return missing keys
/// @return A vector of strings containing the names of missing required keys
std::vector<std::string> Config::validate() const {
    std::vector<std::string> missing;
    if (!project) missing.push_back("project");
    if (!scheme) missing.push_back("scheme");
    if (!configuration) missing.push_back("configuration");
    if (!archive_path) missing.push_back("archive_path");
    if (!export_path) missing.push_back("export_path");
    if (!export_options) missing.push_back("export_options");
    return missing;
}

/// Constructor for ConfigParser that reads the INI file and populates the config object
/// @param ini_path Path to the INI file to parse
/// @throws std::runtime_error if the file cannot be opened or parsed
ConfigParser::ConfigParser(const std::string& ini_path) {
    int error = ini_parse(ini_path.c_str(), ConfigParser::iniHandler, &config_);
    if (error < 0) {
        throw std::runtime_error("Could not open INI file: " + ini_path);
    } else if (error > 0) {
        throw std::runtime_error("INI parse error on line: " + std::to_string(error));
    }
    auto missing = config_.validate();
    if (!missing.empty()) {
        logMissingKeys(missing);
    }
}

/// Accessor for the parsed configuration
/// @return The Config object containing the parsed values
const Config& ConfigParser::config() const {
    return config_;
}

/// Static handler function for the INI parser
/// This function is called for each key-value pair in the INI file.
/// @param user Pointer to the Config object to populate
/// @param section The section name in the INI file
/// @param name The key name in the section
/// @param value The value associated with the key
/// @return 1 to continue parsing, 0 to stop
/// @throws std::runtime_error if an unknown section or key is encountered
int ConfigParser::iniHandler(void* user, const char* section, const char* name, const char* value) {
    Config* config = static_cast<Config*>(user);
    // Only handle [build] for now, but can extend for more sections
    if (std::strcmp(section, "build") == 0) {
        if (std::strcmp(name, "project") == 0) {
            config->project = value;
        } else if (std::strcmp(name, "scheme") == 0) {
            config->scheme = value;
        } else if (std::strcmp(name, "configuration") == 0) {
            config->configuration = value;
        } else if (std::strcmp(name, "archive_path") == 0) {
            config->archive_path = value;
        } else if (std::strcmp(name, "export_path") == 0) {
            config->export_path = value;
        } else if (std::strcmp(name, "export_options") == 0) {
            config->export_options = value;
        }
    }
    // For future: handle other sections here
    return 1;
}

/// Log missing required keys to standard error
/// @param missing A vector of strings containing the names of missing keys
void ConfigParser::logMissingKeys(const std::vector<std::string>& missing) const {
    std::cerr << "Warning: Missing required config keys:";
    for (const auto& key : missing) {
        std::cerr << " " << key;
    }
    std::cerr << std::endl;
}
