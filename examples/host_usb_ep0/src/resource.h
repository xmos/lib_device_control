// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __resource_h__
#define __resource_h__

/* 31..27 supplier      31 (unassigned)
 * 26..24 library       4
 * 23..16 module        0xC3
 * 15..8  processor     2
 * 7..0   instance      7
 */
#define RESOURCE_ID 0xFCC30207

/* assume only one resource, so hash is 1 */
#define RESOURCE_ID_HASH 1

#endif // __resource_h__
