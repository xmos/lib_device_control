// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __resource_table_h__
#define __resource_table_h__

#include "control.h"

struct resource_table_entry {
  control_resid_t resid;
  unsigned ifnum;
};

void resource_table_register(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                             unsigned num_resources, unsigned ifnum);

/* returns -1 if not found */
unsigned resource_table_lookup(control_resid_t resid);

void resource_table_clear(void);

#endif // __resource_table_h__
