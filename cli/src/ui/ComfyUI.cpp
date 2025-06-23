#include "ui/ComfyUI.h"
#include <ftxui/component/component.hpp>
#include <ftxui/component/event.hpp>

using namespace ftxui;

ComfyUI::ComfyUI() : screen(ScreenInteractive::TerminalOutput()) {

    /// Create Menu To Select Options
  menu_renderer = Renderer([&] {
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

  /// Create a keybindings kinda like vim

  keybindings = CatchEvent(menu_renderer, [&](Event event) {
    if (event == Event::Character("j")) {
      selected_option = (selected_option + 1) % options.size();
      return true;
    }

    if (event == Event::Character("k")) {
      selected_option = (selected_option - 1 + options.size()) % options.size();
      return true;
    }

    if (event == Event::Return) {
      message = "You selected: " + options[selected_option];
      return true;
    }

    return false;
  });

  /// Add To Renderer

  renderer = Renderer(keybindings, [&] {
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