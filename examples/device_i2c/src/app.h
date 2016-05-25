// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include "control.h"

/* 31..27 supplier      31 (unassigned)
 * 26..24 library       4
 * 23..16 module        0xC3
 * 15..8  processor     2
 * 7..0   instance      7
 */
#define RESOURCE_ID 0xFCC30207

void app(server interface control i_control);
