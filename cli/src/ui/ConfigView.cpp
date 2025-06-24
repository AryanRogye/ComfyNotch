#include "ui/ConfigView.h"

#include "config.h"
#include "ftxui/component/component.hpp"
#include "ftxui/component/component_base.hpp"
#include "ftxui/component/screen_interactive.hpp"
#include <ftxui/dom/elements.hpp>
#include <ftxui/dom/node.hpp>

using namespace ftxui;

// Mark: Constructors
ConfigView::ConfigView(const Config &config) : config(config), input_fields() {
  // Always load the latest config from disk if ini_path is set
  if (config.ini_path) {
    try {
      this->config = ConfigParser::parse(*config.ini_path);
    } catch (...) {
      this->config = config;
    }
  } else {
    this->config = config;
  }
  // Sync field_values with config
  field_values = {
    this->config.project.value_or("") ,
    this->config.scheme.value_or("") ,
    this->config.archive_configuration.value_or("") ,
    this->config.archive_destructive.has_value() ? (this->config.archive_destructive.value() ? "true" : "false") : "",
    this->config.dmg_name.value_or("") ,
    this->config.dmg_app_name.value_or("") ,
    this->config.dmg_volume_name.value_or("") ,
    this->config.dmg_move_from_archive.has_value() ? (this->config.dmg_move_from_archive.value() ? "true" : "false") : ""
  };
  input_fields.clear();
  for (size_t i = 0; i < field_values.size(); ++i) {
    InputOption option;
    option.on_change = []{};
    option.on_enter = []{};
    // Set cursor colors to ensure visibility
    option.cursor_position = field_values[i].size();
    input_fields.push_back(Input(&field_values[i], "Enter value...", option));
  }
  // Ensure each Input's cursor is at the end of the text
  for (size_t i = 0; i < input_fields.size(); ++i) {
    input_fields[i]->OnEvent(Event::End);
  }

  /// Create the form with input fields
  form = Container::Vertical(input_fields);
  /// Track which field is currently being edited
  editing_field = -1;


  /// Main renderer for the form
  form_renderer = Renderer([this] {
    Elements entries;
    static const std::vector<std::string> labels = {
      "Project", "Scheme", "Configuration", "Destructive", "DMG Name", "DMG App Name", "DMG Volume Name", "DMG Move From Archive"
    };
    for (size_t i = 0; i < field_values.size(); ++i) {
      if (editing_field == (int)i) {
        entries.push_back(hbox({
          text(labels[i] + ": ") | size(WIDTH, EQUAL, 18),
          input_fields[i]->Render() |
            bgcolor(Color::Blue) |
            color(field_values[i].empty() ? Color::White : Color::GrayDark)
        }));
      } else {
        Element line = text(labels[i] + ": " + field_values[i]);
        if ((int)i == selected_option)
          line = line | inverted | bold | color(Color::Green);
        else
          line = line | color(Color::GrayDark);
        entries.push_back(line);
      }
    }
    return vbox({
      text("Configuration View"),
      separator(),
      text("Use Ctrl+C to go back"),
      vbox(std::move(entries)) | border | color(Color::GrayDark) | bgcolor(Color::Black),
      separator(),
      text("Use j/k or arrows to navigate, Enter to edit, Esc to exit edit, s to save"),
      separator(),
      text("For Destructive (yes, 1, true) means true") | border
    }) | border;
  });
  build_keybindings();

  /// Assign the form renderer to the view
  view = keybindings;
}

void ConfigView::Run() {
  auto screen = ScreenInteractive::TerminalOutput();
  screen.Loop(view);
}

void ConfigView::build_keybindings() {
  keybindings = CatchEvent(form_renderer, [this](Event event) {
    if (editing_field == -1) {
      // Normal navigation mode
      if (event == Event::Character("j") || event == Event::ArrowDown) {
        selected_option = (selected_option + 1) % field_values.size();
        return true;
      }
      if (event == Event::Character("k") || event == Event::ArrowUp) {
        selected_option = (selected_option - 1 + field_values.size()) % field_values.size();
        return true;
      }
      if (event == Event::Return) {
        editing_field = selected_option;
        return true;
      }
      if (event == Event::Character("s")) {
        // Save previous config for revert
        auto previous_config = config;
        config.project = field_values[0].empty() ? std::nullopt : std::make_optional(field_values[0]);
        config.scheme = field_values[1].empty() ? std::nullopt : std::make_optional(field_values[1]);
        config.archive_configuration = field_values[2].empty() ? std::nullopt : std::make_optional(field_values[2]);
        // Convert string to bool for archive_destructive
        if (field_values[3].empty()) {
          config.archive_destructive = std::nullopt;
        } else {
          std::string val = field_values[3];
          val.erase(std::remove_if(val.begin(), val.end(), [](unsigned char c) { return std::isspace(c); }), val.end());
          std::transform(val.begin(), val.end(), val.begin(), ::tolower);
          config.archive_destructive = (val == "true" || val == "1" || val == "yes");
        }
        config.dmg_name = field_values[4].empty() ? std::nullopt : std::make_optional(field_values[4]);
        config.dmg_app_name = field_values[5].empty() ? std::nullopt : std::make_optional(field_values[5]);
        config.dmg_volume_name = field_values[6].empty() ? std::nullopt : std::make_optional(field_values[6]);
        if (field_values[7].empty()) {
          config.dmg_move_from_archive = std::nullopt;
        } else {
          std::string val = field_values[7];
          val.erase(std::remove_if(val.begin(), val.end(), [](unsigned char c) { return std::isspace(c); }), val.end());
          std::transform(val.begin(), val.end(), val.begin(), ::tolower);
          config.dmg_move_from_archive = (val == "true" || val == "1" || val == "yes");
        }
        config.validate(); // Validate the config
        // Use ConfigParser static logic for save and verify
        bool save_ok = ConfigParser::save(config);
        bool verified = false;
        if (save_ok) {
          try {
            Config verified_config = ConfigParser::parse(*config.ini_path);
            verified = true;
            refresh();
          } catch (const std::exception& e) {
            // Revert: reload previous config if parse fails
            ConfigParser::save(previous_config); // revert file
            config = previous_config; // revert in memory
            // Optionally show error to user (e.g. set a message)
          }
        } else {
          // Save failed, revert in memory
          config = previous_config;
          // Optionally show error to user
        }
        return true;
      }
    } else {
      // In edit mode for a field
      bool handled = input_fields[editing_field]->OnEvent(event);
      if (event == Event::Escape) {
        editing_field = -1;
        return true;
      }
      if (event == Event::Return) {
        editing_field = -1;
        return true;
      }
      return handled;
    }
    return false;
  });
}

void ConfigView::refresh() {
  if (config.ini_path) {
    try {
      Config latest = ConfigParser::parse(*config.ini_path);
      config = latest;
      // Update field_values to match the latest config
      field_values = {
        config.project.value_or("") ,
        config.scheme.value_or("") ,
        config.archive_configuration.value_or("") ,
        config.archive_destructive.has_value() ? (config.archive_destructive.value() ? "true" : "false") : "",
        config.dmg_name.value_or("") ,
        config.dmg_app_name.value_or("") ,
        config.dmg_volume_name.value_or("") ,
        config.dmg_move_from_archive.has_value() ? (config.dmg_move_from_archive.value() ? "true" : "false") : ""
      };
      // Update input fields as well
      for (size_t i = 0; i < field_values.size() && i < input_fields.size(); ++i) {
        // The Input component already points to field_values[i], so just updating field_values is enough
      }
    } catch (const std::exception& e) {
      // Optionally handle error (e.g., show a message)
    }
  }
}