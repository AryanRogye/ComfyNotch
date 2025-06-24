#include "ui/ComfyUI.h"
#include "ui/ConfigView.h"
#include "ui/BuildArchiveView.h"
#include "utils/ProcessRunner.h"
#include <filesystem>
#include "utils/Logger.h"
#include "utils/SafeDelete.h"
#include "comfyx_paths.h"

#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include <ftxui/component/event.hpp>
#include <memory>

using namespace ftxui;

// MARK: Run
void ComfyUI::Run() { screen.Loop(renderer); }


// MARK: Constructors
ComfyUI::ComfyUI(const Config config) : config(config), screen(ScreenInteractive::TerminalOutput()) {
    // Assign commands for each menu option
    commands = {
        [this]() { show_build_archive_view(); },
        [this]() { show_create_dmg_view(); },
        [this]() { show_config_view(); },
        [this]() { clean_archive_folder(); },
        [this]() { clean_dmg_folder(); },
    };
    options = {"Build Archive", "Create DMG", "Configuration", "Clean Archive Folder", "Clean DMG Folder"};

    build_menu_renderer();
    build_keybindings();
    build_renderer();
}

// MARK: Main Renderer

// This function builds the main renderer for the ComfyUI.
// It creates a Renderer object that combines the title, keybindings, and message into a vertical box layout.
// The title is displayed at the top, followed by a separator, the keybindings, and the message.
// The keybindings are displayed in a smaller font size and are gray in color.
// The message is displayed in white color.
// The entire layout is centered both horizontally and vertically on the screen.
void ComfyUI::build_renderer() {
    renderer = Renderer(keybindings, [this] {
        return vbox({
                   text(title),
                   separator(),
                   keybindings->Render() | 
                       border | color(Color::GrayDark) | bgcolor(Color::Black),
                   separator(),
                   text(message.empty() ? "Select an option" : message),
                   text("Ctrl+C to exit"),
               }) |
               border;
    });
}


// MARK: Menu Picker

// This function builds the menu renderer, which displays the available options.
// The selected option is highlighted in green, while unselected options are displayed in gray.
// The menu_renderer is a Component that can be rendered in the UI.
// It uses a lambda function to generate the content dynamically based on the current state of options and selected_option.
// The options are displayed with a leading space for better readability.
// The selected option is styled with inverted colors, bold text, and green color.
// Unselected options are styled with a dark gray color.
// The menu_renderer is then used in the main renderer to display the menu in the UI.
void ComfyUI::build_menu_renderer() {
    menu_renderer = Renderer([this] {
        Elements entries;
        for (size_t i = 0; i < options.size(); ++i) {
            Element line = text(" " + options[i]);
            if (i == selected_option)
                line = line | inverted | bold | color(Color::Green);
            else
                line = line | color(Color::GrayDark);
            entries.push_back(line);
        }
        return vbox(std::move(entries));
    });
}

// MARK: Keybindings

// This function sets up keybindings for the menu navigation and command execution.
// It uses the CatchEvent function to handle key events and update the selected option or execute commands
void ComfyUI::build_keybindings() {
    keybindings = CatchEvent(menu_renderer, [this](Event event) {
        if (event == Event::Character("j") || event == Event::ArrowDown) {
            selected_option = (selected_option + 1) % options.size();
            return true;
        }
        if (event == Event::Character("k") || event == Event::ArrowUp) {
            selected_option = (selected_option - 1 + options.size()) % options.size();
            return true;
        }
        if (event == Event::Return) {
            if (selected_option >= 0 && selected_option < (int)commands.size()) {
                commands[selected_option]();
            }
            return true;
        }
        return false;
    });
}

// MARK: Command Functions

void ComfyUI::show_config_view() {
    // Always reload the config from disk before showing the config view
    if (config.ini_path) {
        try {
            config = ConfigParser::parse(*config.ini_path);
        } catch (...) {
            // Optionally handle error (e.g., show a message)
        }
    }
    config_view = std::make_unique<ConfigView>(config);
    config_view->Run();
    // After returning, reload config again in case it was changed in the view
    if (config.ini_path) {
        try {
            config = ConfigParser::parse(*config.ini_path);
        } catch (...) {
            // Optionally handle error
        }
    }
    message = "Returned from configuration view.";
    build_menu_renderer();
    build_keybindings();
    build_renderer();
}

void ComfyUI::show_build_archive_view() {
    // Create the build archive view (pass config as needed)
    build_archive_view = std::make_unique<BuildArchiveView>(config);
    build_archive_view->Run();
    message = "Returned from build archive view.";
    build_menu_renderer();
    build_keybindings();
    build_renderer();
}

// MARK: - Cleanup

void ComfyUI::show_create_dmg_view() {
    ProcessRunner::Run(ProcessType::CreateDMG, config);
}

void ComfyUI::clean_archive_folder() {
    namespace fs = std::filesystem;
    bool removed = false;
    std::string archive_dir = comfyx::kArchiveDir;
    std::string export_dir = comfyx::kExportDir;
    if (SafeDelete::is_safe_to_remove(archive_dir) && !SafeDelete::contains_forbidden_files(archive_dir)) {
        std::error_code ec;
        if (fs::exists(archive_dir)) {
            fs::remove_all(archive_dir, ec);
            Logger::Log("Removed archive folder: " + archive_dir + (ec ? (" (error: " + ec.message() + ")") : ""));
            removed = true;
        }
    } else if (SafeDelete::contains_forbidden_files(archive_dir)) {
        Logger::Log("Aborted: forbidden files/folders found in " + archive_dir);
    }
    if (SafeDelete::is_safe_to_remove(export_dir) && !SafeDelete::contains_forbidden_files(export_dir)) {
        std::error_code ec;
        if (fs::exists(export_dir)) {
            fs::remove_all(export_dir, ec);
            Logger::Log("Removed export folder: " + export_dir + (ec ? (" (error: " + ec.message() + ")") : ""));
            removed = true;
        }
    } else if (SafeDelete::contains_forbidden_files(export_dir)) {
        Logger::Log("Aborted: forbidden files/folders found in " + export_dir);
    }
    message = removed ? "Archive and/or export folders cleaned." : "No archive/export folders to clean, unsafe path, or forbidden files present.";
    build_menu_renderer();
    build_keybindings();
    build_renderer();
}

void ComfyUI::clean_dmg_folder() {
    namespace fs = std::filesystem;
    bool removed = false;
    std::string dmg_folder = comfyx::kUpdatesDir;
    if (SafeDelete::is_safe_to_remove(dmg_folder) && !SafeDelete::contains_forbidden_files(dmg_folder)) {
        std::error_code ec;
        if (fs::exists(dmg_folder)) {
            fs::remove_all(dmg_folder, ec);
            Logger::Log("Removed DMG folder: " + dmg_folder + (ec ? (" (error: " + ec.message() + ")") : ""));
            removed = true;
        }
    } else if (SafeDelete::contains_forbidden_files(dmg_folder)) {
        Logger::Log("Aborted: forbidden files/folders found in " + dmg_folder);
    }
    message = removed ? "DMG folder cleaned." : "No DMG folder to clean, unsafe path, or forbidden files present.";
    build_menu_renderer();
    build_keybindings();
    build_renderer();
}
