#pragma once

#include <config.h>
#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include <ftxui/component/screen_interactive.hpp>

class ConfigView {
public:
  ConfigView(const Config& config);

    // Render the configuration view
  void Run();

private:
  Config config;
  int selected_option = 0;

  std::vector<std::string> options;

  ftxui::Component view;
  ftxui::Component form;
  ftxui::Component keybindings;

  void build_keybindings();
};
