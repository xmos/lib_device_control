// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
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
