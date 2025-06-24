#include "ui/ConfigView.h"

#include "ftxui/component/component.hpp"
#include "ftxui/component/component_base.hpp"
#include "ftxui/component/screen_interactive.hpp"
#include <ftxui/dom/node.hpp>

using namespace ftxui;

ConfigView::ConfigView(const Config &config) : config(config) {
  options = {"Project: " + config.project.value_or("N/A"),
             "Scheme: " + config.scheme.value_or("N/A"),
             "Scheme: " + config.scheme.value_or("N/A"),
             "Configuration: " + config.configuration.value_or("N/A"),
             "Archive Path: " + config.archive_path.value_or("N/A"),
             "Export Path: " + config.export_path.value_or("N/A"),
             "Export Options:  " + config.export_options.value_or("N/A")};


  // Initialize the form with the configuration values
  form = Renderer([this]() {
    Elements entries;

    for (size_t i = 0; i < options.size(); ++i) {
        Element line = text(options[i]);
        if (i == selected_option)
            line = line | inverted | bold | color(Color::Green);
        else
            line = line | color(Color::GrayDark);
        entries.push_back(line);
    }
    return vbox(std::move(entries));
  });

  build_keybindings();

  view = Renderer(keybindings ,[this]() {
    return vbox({
        text("Configuration View"),
        separator(),
        text("Ctrl+C to exit."),
        keybindings->Render(),
        text("Use 'j'/'k' to navigate, 'q' to quit.")
    });
  });
}

void ConfigView::Run() {
  auto screen = ScreenInteractive::TerminalOutput();
  screen.Loop(view);
}

void ConfigView::build_keybindings() {
    keybindings = CatchEvent(form, [this](Event event) {
        if (event == Event::Character("j") || event == Event::ArrowDown) {
            selected_option = (selected_option + 1) % options.size();
            return true;
        }
        if (event == Event::Character("k") || event == Event::ArrowUp) {
            selected_option = (selected_option - 1 + options.size()) % options.size();
            return true;
        }
        return false;
    });
}