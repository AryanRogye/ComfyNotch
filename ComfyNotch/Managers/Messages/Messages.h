//
//  lastTalkedTo.h
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/9/25.
//

#ifndef LastTalkedTo_h
#define LastTalkedTo_h

#include <sqlite3.h>
#include <stdint.h>

int64_t get_last_talked_to(sqlite3 *db, int64_t handle_id);
const char *get_last_message_text(sqlite3 *db, long long handle_id);
const int has_chat_db_changed(sqlite3 *db, int64_t last_known_time);

#endif /* LastTalkedTo_h */
