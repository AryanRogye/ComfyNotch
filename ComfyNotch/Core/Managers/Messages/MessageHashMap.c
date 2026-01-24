//
//  MessageHashMap.c
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/7/25.
//

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "MessageHashMap.h"

/// This is the buckets where we store our hash map entries.
static HashNode *buckets[HASHMAP_SIZE] = { 0 };

int getSizeOfBucketsStored(void) {
    int count = 0;
    for (int i = 0; i < HASHMAP_SIZE; i++) {
        HashNode *node = buckets[i];
        while (node != NULL) {
            count++;
            node = node->next;
        }
    }
    
    return count;
}

// MARK: - Function to get the hash index for a given key
int getHashIndex(const char *key) {
    unsigned long hash = 5381;
    int c;
    
    while ((c = *key++)) {
        hash = ((hash << 5) + hash) + c; // hash * 33 + c
    }
    
    return hash % HASHMAP_SIZE;
}

// MARK: - Function to put a key -value pair into the hash map
// NOTE: no hasmap should be replaced, so we must make sure that we handle collisions properly.
void hashmap_put(const char *key, MessageMeta value) {
    /// first we get the hashIndex for the key
    int index = getHashIndex(key);
    
    /// See If we get the key something already exists in the hash map
    HashNode *node = buckets[index];
    while (node != NULL) {
        if (strcmp(node->key, key) == 0) {
            if (node->value.date == value.date) {
                printf("🟡 Duplicate message insert skipped for key: %s\n", key);
                return;
            }
            if (node->value.date != value.date) {
                node->value = value;
            }
            return;
        }
        node = node->next;
    }
    
    /// Create a new node for the key-value pair
    HashNode *newNode = malloc(sizeof(HashNode));
    newNode->key = strdup(key);
    newNode->value = value;
    newNode->next = buckets[index];
    buckets[index] = newNode;
}

MessageMeta *hashmap_get(const char *key) {
    int index = getHashIndex(key);
    
    HashNode *node = buckets[index];
    
    while(node != NULL) {
        if (strcmp(node->key, key) == 0) {
            return &node->value;
        }
        node = node->next;
    }
    /// Not Found
    return NULL;
}

void hashmap_free(void) {
    for (int i = 0; i < HASHMAP_SIZE; i++) {
        HashNode *node = buckets[i];
        while (node != NULL) {
            HashNode *next = node->next;
            
            free(node->key);  // strdup'd key
            free(node);       // node itself
            
            node = next;
        }
        buckets[i] = NULL; // clear bucket
    }
}
