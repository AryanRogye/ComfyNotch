#pragma once

#include <config.h>

#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include <ftxui/component/screen_interactive.hpp>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "ConfigView.h"

class ComfyUI {
public:
  ComfyUI(const Config);
  void Run();

  // Setters for UI components to allow safe assignment after construction
  void set_menu_renderer(const ftxui::Component& comp) { menu_renderer = comp; }
  void set_keybindings(const ftxui::Component& comp) { keybindings = comp; }
  void set_renderer(const ftxui::Component& comp) { renderer = comp; }

private:
  Config config;
  int selected_option = 0;
  std::vector<std::string> options;
  std::vector<std::function<void()>> commands;

  std::string title = "Comfyx";
  std::string message = "";

  ftxui::Component renderer;
  ftxui::Component menu_renderer;
  ftxui::Component keybindings;

  ftxui::Component menu;
  ftxui::ScreenInteractive screen;

  void build_menu_renderer();
  void build_keybindings();
  void build_renderer();

  void show_config_view();
  std::unique_ptr<ConfigView> config_view;
};