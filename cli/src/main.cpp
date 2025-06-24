#include "config.h"
#include "ui/ComfyUI.h"

int main() {

    ConfigParser configParser("config/comfyx.ini");

    ComfyUI ui(configParser.config());
    ui.Run();
    return 0;
}
