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
  const Config& GetConfig() const { return config; }

private:
  Config config;
  int selected_option = 0;
  int editing_field = -1;

  std::vector<std::string> field_values;
  std::vector<ftxui::Component> input_fields;

  ftxui::Component view;
  ftxui::Component form;
  ftxui::Component form_renderer;
  ftxui::Component keybindings;

  void build_keybindings();
  void refresh();
};
