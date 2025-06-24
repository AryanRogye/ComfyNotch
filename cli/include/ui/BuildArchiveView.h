#pragma once

#include <atomic>
#include <config.h>
#include <comfyx_paths.h>
#include <ftxui/component/component.hpp>
#include <ftxui/component/component_base.hpp>
#include <ftxui/component/screen_interactive.hpp>
#include <future>

class BuildArchiveView {
public:
  BuildArchiveView(const Config& config);

    // Render the configuration view
  void Run();
  const Config& GetConfig() const { return config; }

private:
  Config config;
  int selected_option = 0;
  int editing_field = -1;

  std::vector<std::string> field_values;

  ftxui::Component view;
  ftxui::Component main_view;
  ftxui::Component keybindings;

  ftxui::Component run_button;
  ftxui::Component message;

  std::future<int> build_future; // Store the async process future
  std::atomic<bool> build_running{false};    // Track if build is running (thread-safe)
  int build_result = 0;          // Store result when done

  void befresh();
  void build_keybindings();
};
