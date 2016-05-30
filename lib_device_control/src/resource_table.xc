// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "xassert.h"
#include "control.h"
#include "resource_table.h"

#define DEBUG 0

/* 256 entries, 8B per entry -> 2KB */
static struct resource_table_entry {
  control_resid_t resid;
  unsigned ifnum;
} resource_table[RESOURCE_TABLE_MAX];

static unsigned resource_table_size = 0;

void resource_table_add(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                        unsigned num_resources, unsigned ifnum)
{
  struct resource_table_entry *e;
  control_resid_t resid;
  unsigned ifnum1;
  unsigned i;

  for (i = 0; i < num_resources; i++) {
    resid = resources[i];

#if DEBUG
    printf("register resource 0x%X on interface %d\n", resid, ifnum);
#endif

    if (resource_table_find_resid(resid, ifnum1)) {
      printf("resource 0x%X already registered on interface %d\n", resid, ifnum1);
      xassert(0);
    }

    if (resource_table_size >= RESOURCE_TABLE_MAX) {
      printf("maximum table size of %d resources reached\n", RESOURCE_TABLE_MAX);
      xassert(0);
    }

    e = &resource_table[resource_table_size];
    e->resid = resid;
    e->ifnum = ifnum;

#if DEBUG
    printf("resource 0x%X registered with index %d\n", resid, resource_table_size);
#endif
    resource_table_size++;
  }
}

int resource_table_find_index(control_idx_t idx, control_resid_t &resid, unsigned &ifnum)
{
  struct resource_table_entry *e;

  if (idx <= resource_table_size && idx > 0) {
    e = &resource_table[idx - 1];
    resid = e->resid;
    ifnum = e->ifnum;
    return 1;
  }

#if DEBUG
  printf("not found index 0x%X (table size %d)\n", idx, resource_table_size);
#endif

  return 0;
}

int resource_table_find_resid(control_resid_t resid, unsigned &ifnum)
{
  struct resource_table_entry *e;
  unsigned i;

  /* TODO add hashing for better performance */
  for (i = 0; i < resource_table_size; i++) {
    e = &resource_table[i];
    if (e->resid == resid) {
      ifnum = e->ifnum;
      return 1;
    }
  }

#if DEBUG
  printf("not found resource 0x%X\n", resid);
#endif

  return 0;
}

void resource_table_clear(void)
{
  resource_table_size = 0;
}
