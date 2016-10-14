// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifdef HOST_APP //Prevent XC compiler from picking this up
#ifndef __pause_h__
#define __pause_h__

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

#ifdef _WIN32

static void pause_short(void)
{
  Sleep(1);
}

static void pause_long(void)
{
  Sleep(1000);
}

#else

static void pause_short(void)
{
  usleep(100000);
}

static void pause_long(void)
{
  sleep(1);
}

#endif // WIN32

#endif // __pause_h__
#endif //HOST_APP