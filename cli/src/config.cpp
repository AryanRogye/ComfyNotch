#include "config.h"
#include "ini.h"
#include <stdexcept>
#include <cstring>
#include <iostream>
#include <fstream>

// MARK: Validation

/// Function to validate the configuration and return missing keys
/// @return A vector of strings containing the names of missing required keys
std::vector<std::string> Config::validate() const {
    std::vector<std::string> missing;
    if (!project) missing.push_back("project");
    if (!scheme) missing.push_back("scheme");
    if (!archive_configuration) missing.push_back("archive_configuration");
    return missing;
}

// MARK: ConfigParser Implementation

/// Parse the INI file at the given path and return a Config object
/// @param ini_path Path to the INI file to parse
/// @return A Config object populated with the values from the INI file
/// @throws std::runtime_error if the file cannot be opened or parsed
Config ConfigParser::parse(const std::string& ini_path) {
    Config config;
    config.ini_path = ini_path;
    int error = ini_parse(ini_path.c_str(), ConfigParser::iniHandler, &config);
    if (error < 0) {
        throw std::runtime_error("Could not open INI file: " + ini_path);
    } else if (error > 0) {
        throw std::runtime_error("INI parse error on line: " + std::to_string(error));
    }
    auto missing = config.validate();
    if (!missing.empty()) {
        logMissingKeys(missing);
    }
    // comfyx_data_root and all generated paths are now fixed, no need to parse from ini
    return config;
}

// MARK: Save Config
/// Save the given Config object to an INI file
/// @param config The Config object to save
/// @return true if successful, false otherwise
bool ConfigParser::save(const Config& config) {
    if (!config.ini_path) return false;

    // Sanitize and trim config values
    auto trim = [](std::string& s) {
        // Remove leading whitespace
        s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) { return !std::isspace(ch); }));
        // Remove trailing whitespace
        s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) { return !std::isspace(ch); }).base(), s.end());
    };
    Config sanitized_config = config;
    if (sanitized_config.project) {
        sanitized_config.project->erase(std::remove(sanitized_config.project->begin(), sanitized_config.project->end(), '\n'), sanitized_config.project->end());
        trim(*sanitized_config.project);
    }
    if (sanitized_config.scheme) {
        sanitized_config.scheme->erase(std::remove(sanitized_config.scheme->begin(), sanitized_config.scheme->end(), '\n'), sanitized_config.scheme->end());
        trim(*sanitized_config.scheme);
    }
    if (sanitized_config.archive_configuration) {
        sanitized_config.archive_configuration->erase(std::remove(sanitized_config.archive_configuration->begin(), sanitized_config.archive_configuration->end(), '\n'), sanitized_config.archive_configuration->end());
        trim(*sanitized_config.archive_configuration);
    }
    // No more archive_path, archive_export_path, archive_export_options, etc.
    if (!sanitized_config.ini_path) return false;
    // Validate before writing
    auto missing = sanitized_config.validate();
    if (!missing.empty()) {
        logMissingKeys(missing);
        return false; // Cannot save if validation fails
    }
    // Write to a temp file first for atomicity
    std::string tmp_path = *sanitized_config.ini_path + ".tmp";
    {
        std::ofstream out(tmp_path);
        if (!out) return false;
        // [build] section
        out << "[build]\n";
        if (sanitized_config.project) out << "project = " << *sanitized_config.project << "\n";
        if (sanitized_config.scheme) out << "scheme = " << *sanitized_config.scheme << "\n";
        // [archive] section (only archive_configuration and archive_destructive remain)
        out << "\n[archive]\n";
        if (sanitized_config.archive_configuration) out << "archive_configuration = " << *sanitized_config.archive_configuration << "\n";
        if (sanitized_config.archive_destructive.has_value()) {
            out << "archive_destructive = " << (sanitized_config.archive_destructive.value() ? "true" : "false") << "\n";
        }
        // [dmg] section
        if (sanitized_config.dmg_name || sanitized_config.dmg_app_name || sanitized_config.dmg_volume_name || sanitized_config.dmg_move_from_archive) {
            out << "\n[dmg]\n";
            if (sanitized_config.dmg_name) out << "dmg_name = " << *sanitized_config.dmg_name << "\n";
            if (sanitized_config.dmg_app_name) out << "dmg_app_name = " << *sanitized_config.dmg_app_name << "\n";
            if (sanitized_config.dmg_volume_name) out << "dmg_volume_name = " << *sanitized_config.dmg_volume_name << "\n";
            if (sanitized_config.dmg_move_from_archive.has_value()) {
                out << "dmg_move_from_archive = " << (sanitized_config.dmg_move_from_archive.value() ? "true" : "false") << "\n";
            }
        }
        // No [general] section needed
    }
    // Verify the temp file parses
    try {
        Config verified = ConfigParser::parse(tmp_path);
        // If parse is good, move temp file to real file
        std::rename(tmp_path.c_str(), sanitized_config.ini_path->c_str());
        return true;
    } catch (const std::exception& e) {
        std::remove(tmp_path.c_str());
        logMissingKeys({"Failed to verify config after save: " + std::string(e.what())});
        return false;
    }
}

// MARK: INI Handler

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
    if (std::strcmp(section, "build") == 0) {
        if (std::strcmp(name, "project") == 0) {
            config->project = value;
        } else if (std::strcmp(name, "scheme") == 0) {
            config->scheme = value;
        }
    } else if (std::strcmp(section, "archive") == 0) {
        if (std::strcmp(name, "archive_configuration") == 0) {
            config->archive_configuration = value;
        } else if (std::strcmp(name, "archive_destructive") == 0) {
            std::string val = value;
            std::transform(val.begin(), val.end(), val.begin(), ::tolower);
            config->archive_destructive = (val == "true" || val == "1" || val == "yes");
        }
    } else if (std::strcmp(section, "dmg") == 0) {
        if (std::strcmp(name, "dmg_name") == 0) {
            config->dmg_name = value;
        } else if (std::strcmp(name, "dmg_app_name") == 0) {
            config->dmg_app_name = value;
        } else if (std::strcmp(name, "dmg_volume_name") == 0) {
            config->dmg_volume_name = value;
        } else if (std::strcmp(name, "dmg_move_from_archive") == 0) {
            std::string val = value;
            std::transform(val.begin(), val.end(), val.begin(), ::tolower);
            config->dmg_move_from_archive = (val == "true" || val == "1" || val == "yes");
        }
    }
    return 1;
}

// MARK: Logging Missing Keys

/// Log missing required keys to standard error
/// @param missing A vector of strings containing the names of missing keys
void ConfigParser::logMissingKeys(const std::vector<std::string>& missing) {
    std::cerr << "Warning: Missing required config keys:";
    for (const auto& key : missing) {
        std::cerr << " " << key;
    }
    std::cerr << std::endl;
}
