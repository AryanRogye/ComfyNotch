#include "ui/ComfyUI.h"
#include "ui/ConfigView.h"
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
        [this]() { message = "[Build Archive] command executed."; },
        [this]() { message = "[Create DMG] command executed."; },
        [this]() { show_config_view(); }
    };
    options = {"Build Archive", "Create DMG", "Configuration"};

    build_menu_renderer();
    build_keybindings();
    build_renderer();
}

// MARK: Main Renderer

// This function builds the main renderer for the ComfyUI.
// It creates a Renderer object that combines the title, keybindings, and message into a vertical box layout.
// The title is displayed at the top, followed by a separator, the keybindings,
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
    // Create the config view (pass config as needed)
    config_view = std::make_unique<ConfigView>(config);
    // Run the config view in its own event loop
    config_view->Run();
    // After returning, you can update the message or refresh the main menu
    message = "Returned from configuration view.";
    build_menu_renderer();
    build_keybindings();
    build_renderer();
}