// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "xassert.h"
#include "control.h"
#include "resource_table.h"

#define DEBUG 0

/* 256 entries, 8B per entry -> 2KB */
static struct resource_table_entry resource_table[MAX_RESOURCES];

static unsigned resource_table_size = 0;

void resource_table_register(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                             unsigned num_resources, unsigned ifnum)
{
  struct resource_table_entry *e;
  control_resid_t resid;
  unsigned i;

  for (i = 0; i < num_resources; i++) {
    resid = resources[i];

#if DEBUG
    printf("register resource 0x%X on interface %d\n", resid, ifnum);
#endif

    if (resource_table_lookup(resid) != ~0) {
      printf("resource 0x%X already registered on interface %d\n", resid, ifnum);
      xassert(0);
    }

    if (resource_table_size >= MAX_RESOURCES) {
      printf("cannot register more than %d resources\n", resource_table_size);
      xassert(0);
    }

    e = &resource_table[resource_table_size];
    e->resid = resid;
    e->ifnum = ifnum;
    resource_table_size++;
  }
}

unsigned resource_table_lookup(control_resid_t resid)
{
  struct resource_table_entry *e;
  unsigned i;

  for (i = 0; i < resource_table_size; i++) {
    e = &resource_table[i];
    if (e->resid == resid)
      return e->ifnum;
  }

  return ~0;
}

void resource_table_clear(void)
{
  resource_table_size = 0;
}
