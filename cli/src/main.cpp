#include "config.h"
#include "iostream"
#include "ui/ComfyUI.h"

int main() {

    Config config;
    try {
        config = ConfigParser::parse("config/comfyx.ini");
        if (config.ini_path) {
            std::cout << "Loaded configuration from: " << *config.ini_path << std::endl;
        } else {
            std::cerr << "No configuration file specified." << std::endl;
            return 1; // Exit if no config file is provided
        }
    } catch (const std::runtime_error& e) {
        std::cerr << "Error loading configuration: " << e.what() << std::endl;
        return 1; // Exit if config cannot be loaded
    }

    ComfyUI ui(config);
    ui.Run();
    return 0;
}
