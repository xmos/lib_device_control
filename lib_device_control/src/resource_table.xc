// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "xassert.h"
#include "control.h"
#include "resource_table.h"

#define DEBUG_CONTROL_RESOURCE_TABLE 0

/* table entry is interface number, or 255 if not used */
unsigned char resource_table[RESOURCE_TABLE_MAX];

void resource_table_init(void)
{
  unsigned i;

  for (i = 0; i < RESOURCE_TABLE_MAX; i++) {
    resource_table[i] = 255;
  }
}

void resource_table_add(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                        unsigned num_resources, unsigned char ifnum)
{
  control_resid_t resid;
  unsigned i;

  if (ifnum == 255) {
    printf("cannot use reserved interface number 255\n");
    xassert(0);
  }

  for (i = 0; i < num_resources; i++) {
    resid = resources[i];

#if DEBUG_CONTROL_RESOURCE_TABLE
    printf("register resource %d on interface %d\n", resid, ifnum);
#endif

    if (resid >= RESOURCE_TABLE_MAX) {
      printf("maximum resource number is %d, unable to map %d\n", RESOURCE_TABLE_MAX, resid);
      xassert(0);
    }

    if (resource_table[resid] < 255) {
      printf("resource %d already registered on interface %d\n", resid, resource_table[resid]);
      xassert(0);
    }

    resource_table[resid] = ifnum;
  }
}

int resource_table_search(control_resid_t resid, unsigned char &ifnum)
{
  if (resid < RESOURCE_TABLE_MAX && resource_table[resid] < 255) {
    ifnum = resource_table[resid];
    return 1;
  }
  return 0;
}
