// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#ifndef __pause_h__
#define __pause_h__

#include <xs1.h>
#include <timer.h>

static void pause_short(void)
{
  delay_milliseconds(100);
}

static void pause_long(void)
{
  delay_milliseconds(1000);
}

#endif // __pause_h__
