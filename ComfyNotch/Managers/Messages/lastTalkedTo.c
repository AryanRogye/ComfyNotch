//
//  lastTalkedTo.c
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/9/25.
//

#include <sqlite3.h>
#include <stdint.h>
#include <stdio.h>
#include "lastTalkedTo.h"

int64_t get_last_talked_to(sqlite3 *db, int64_t handle_id) {
    
//    printf("Fetching last talked to for handle_id: %lld\n", handle_id);
//    printf("DB: %p\n", db);
    
    sqlite3_stmt *stmt;
    const char *sql = "SELECT date FROM message WHERE handle_id = ? ORDER BY date DESC LIMIT 1;";
    
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK)
        return -1;
    
    sqlite3_bind_int64(stmt, 1, handle_id);
    
    int64_t result = -1;
    if (sqlite3_step(stmt) == SQLITE_ROW)
        result = sqlite3_column_int64(stmt, 0);
    
    sqlite3_finalize(stmt);
    return result;
}
