//
//  MessageHashMap.h
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/7/25.
//

#ifndef MessageHashMap_h
#define MessageHashMap_h

#include "MessageMeta.h"

#define HASHMAP_SIZE 1024

typedef struct HashNode {
    char *key;
    MessageMeta value;
    struct HashNode *next;
} HashNode;

int getSizeOfBucketsStored(void);
void hashmap_put(const char *key, MessageMeta value);
MessageMeta *hashmap_get(const char *key);
void hashmap_free(void);

#endif
