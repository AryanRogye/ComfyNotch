#include "ui/ComfyUI.h"
#include "ui/ConfigView.h"
#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include <ftxui/component/event.hpp>
#include <memory>

using namespace ftxui;

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


// MARK: Internals
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

void ComfyUI::build_renderer() {
    renderer = Renderer(keybindings, [this] {
        return vbox({
                   text(title),
                   separator(),
                   keybindings->Render(),
                   separator(),
                   text(message.empty() ? "Select an option" : message),
               }) |
               border;
    });
}

void ComfyUI::Run() { screen.Loop(renderer); }