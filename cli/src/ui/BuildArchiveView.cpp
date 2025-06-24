#include "ui/BuildArchiveView.h"

#include "config.h"
#include "ftxui/component/component.hpp"
#include "ftxui/component/component_base.hpp"
#include "ftxui/component/screen_interactive.hpp"
#include "utils/ProcessRunner.h"
#include "utils/Logger.h"
#include <ftxui/dom/node.hpp>

using namespace ftxui;

BuildArchiveView::BuildArchiveView(const Config &config) : config(config) {
  run_button = Button("Run", [this, &config]() {
    message = Renderer([]() {
      return text("Running build archive process...") |
             color(Color::Green) | bgcolor(Color::Black);
    });
    build_future = ProcessRunner::Run(ProcessType::BuildArchive, config);
    build_running = true;
    build_result = 0;
  });

  main_view = Renderer([this]() {
    // Check if build is running and update state if finished
    if (build_running && build_future.valid()) {
      auto status = build_future.wait_for(std::chrono::seconds(0));
      if (status == std::future_status::ready) {
        build_result = build_future.get();
        build_running = false;
        message = Renderer([this]() {
          if (build_result == 0) {
            return text("Build completed successfully!") | color(Color::Green);
          } else {
            return text("Build failed (exit code: " + std::to_string(build_result) + ")") | color(Color::Red);
          }
        });
      }
    }
    return vbox({
               text("Build Archive Configurations") | bold | color(Color::White),
               separator(),
               run_button->Render() | border | color(Color::Green),
               separator(),
               message ? message->Render() : text("Nothing Yet"),
               separator(),
               Logger::LogComponent()->Render()
           }) |
           border | bgcolor(Color::Black);
  });

  keybindings = CatchEvent(main_view, [this](Event event) {
    // Pass all events to the run_button
    return run_button->OnEvent(event);
  });
  view = keybindings;
}

void BuildArchiveView::Run() {
  auto screen = ScreenInteractive::TerminalOutput();
  screen.Loop(view);
}