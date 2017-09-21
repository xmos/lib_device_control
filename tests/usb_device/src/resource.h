// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#ifndef __resource_h__
#define __resource_h__

/* resource ID that includes interface number of given test task
 * and which resource in given task it is, if the task has more than one
 */
#define RESID(if_num, res_in_if) (0x80 | ((if_num) << 4) | ((res_in_if) + 1))
#define BADID 0xFF

#endif // __resource_h__
