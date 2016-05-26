// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __resource_h__
#define __resource_h__

#include "control.h"
/* 31..27 supplier      31 (unassigned)
 * 26..24 library       4
 * 23..16 module        0xC3
 * 15..8  processor     2
 * 7..0   instance      7
 */
control_res_t resource_id = (control_res_t)0xFCC30207U;

#endif // __resource_h__
