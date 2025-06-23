cmake_minimum_required(VERSION 3.14)
project(comfyx-cli)

include(FetchContent)

FetchContent_Declare(
  ftxui
  GIT_REPOSITORY https://github.com/ArthurSonzogni/FTXUI
  GIT_TAG        main
)
FetchContent_MakeAvailable(ftxui)

# Include third-party + src
include_directories(include third_party)

# Add executable
file(GLOB SRC_FILES src/*.cpp third_party/*.c)
add_executable(comfyx ${SRC_FILES})
set_target_properties(comfyx PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
target_link_libraries(comfyx PRIVATE ftxui::screen ftxui::dom ftxui::component)
