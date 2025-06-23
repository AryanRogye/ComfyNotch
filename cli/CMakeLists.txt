cmake_minimum_required(VERSION 3.14)
project(comfyx-cli)

include(FetchContent)

FetchContent_Declare(
  ftxui
  GIT_REPOSITORY https://github.com/ArthurSonzogni/FTXUI
  GIT_TAG        main
)

FetchContent_MakeAvailable(ftxui)

add_executable(comfyx main.cpp)
target_link_libraries(comfyx PRIVATE ftxui::screen ftxui::dom ftxui::component)
