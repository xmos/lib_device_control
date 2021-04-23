// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdint.h>
#include <stddef.h>
#include "control.h"
#include "resource_table.h"

#define DEBUG_UNIT RESOURCE_TABLE
#include "debug_print.h"

/* table entry is interface number */
static unsigned char resource_table[RESOURCE_TABLE_MAX];

/* reuse this reserved interface number to indicate none */
#define IFNUM_NONE IFNUM_RESERVED

static control_resid_t g_reserved_id;
static int reserved_id_specified = 0;

void resource_table_init(control_resid_t reserved_id)
{
  unsigned i;

  for (i = 0; i < RESOURCE_TABLE_MAX; i++) {
    resource_table[i] = IFNUM_NONE;
  }

  g_reserved_id = reserved_id;
  reserved_id_specified = 1;
}

int resource_table_add(const control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                       unsigned num_resources, unsigned char ifnum)
{
  control_resid_t resid;
  unsigned i;

  if (ifnum == IFNUM_NONE) {
    debug_printf("cannot use reserved interface number %d\n", IFNUM_NONE);
    return 1;
  }

  for (i = 0; i < num_resources; i++) {
    resid = resources[i];

    debug_printf("register resource %d on interface %d\n", resid, ifnum);

    if (resid >= RESOURCE_TABLE_MAX) {
      debug_printf("maximum resource number is %d, unable to map %d\n", RESOURCE_TABLE_MAX, resid);
      return 2;
    }

    if (reserved_id_specified && resid == g_reserved_id) {
      debug_printf("can't use reserved resource number %d\n", g_reserved_id);
      return 3;
    }

    if (resource_table[resid] < IFNUM_NONE) {
      debug_printf("resource %d already registered on interface %d\n", resid, resource_table[resid]);
      return 4;
    }

    resource_table[resid] = ifnum;
  }
  return 0;
}

int resource_table_search(control_resid_t resid, unsigned char &ifnum)
{
  if (reserved_id_specified && resid == g_reserved_id) {
    ifnum = IFNUM_RESERVED;
    return 0;
  }
  if (resid < RESOURCE_TABLE_MAX && resource_table[resid] < IFNUM_NONE) {
    ifnum = resource_table[resid];
    return 0;
  }
  return 1;
}
