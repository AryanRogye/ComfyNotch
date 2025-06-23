#pragma once

#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include <ftxui/component/screen_interactive.hpp>
#include <string>
#include <vector>

class ComfyUI {
public:
  ComfyUI();
  void Run();

private:
  int selected_option = -1;
  std::vector<std::string> options = {
      "Build Archive",
      "Create DMG",
  };

  std::string title = "Comfyx";
  std::string message = "";

  ftxui::Component button;
  ftxui::Component renderer;
  ftxui::Component menu_renderer;
  ftxui::Component keybindings;

  ftxui::Component menu;
  ftxui::ScreenInteractive screen;
};