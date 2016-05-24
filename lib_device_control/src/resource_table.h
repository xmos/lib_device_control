// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __resource_table_h__
#define __resource_table_h__

#include "control.h"
#include "control_transport.h"

#define RESOURCE_TABLE_MAX 256

void resource_table_add(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                        unsigned num_resources, unsigned ifnum);

/* direct table lookup */
int resource_table_find_resid_hash(control_resid_hash_t hash, control_resid_t &resid, unsigned &ifnum);

/* linear search of table */
int resource_table_find_resid(control_resid_t resid, unsigned &ifnum);

void resource_table_clear(void);

#endif // __resource_table_h__
