// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#include "signals.h"

#ifdef _WIN32

#define UNUSED_PARAMETER(x) (void)(x)

void signals_setup_int(sigint_handler_t handler)
{
  // Not required on Windows
  UNUSED_PARAMETER(handler);
}

void signals_init(void)
{
  // Not required on Windows
}

#else

#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <signal.h>

static sigint_handler_t sigint_handler = NULL;
static sigset_t prev_sigmask = 0;

static void sighandler(int sig)
{
  signal(sig, SIG_IGN);
  sigint_handler();
  signal(SIGINT, sighandler);
}

void signals_setup_int(sigint_handler_t handler)
{
  struct sigaction sa;
  sigemptyset(&sa.sa_mask);
  sigaddset(&sa.sa_mask, SIGINT);
  sa.sa_handler	= sighandler;
  sigint_handler = handler;
  sa.sa_flags = 0;
  sigaction(SIGINT, &sa, NULL);
  pthread_sigmask(SIG_SETMASK, &prev_sigmask, NULL);
}

void signals_init(void)
{
  /* http://stackoverflow.com/questions/6621785/posix-pthread-programming */
  sigset_t ss, prev_sigmask;
  sigemptyset(&ss);
  sigaddset(&ss, SIGINT);
  pthread_sigmask(SIG_BLOCK, &ss, &prev_sigmask);
}

#endif // _WIN32