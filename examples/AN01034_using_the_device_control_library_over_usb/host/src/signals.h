// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __signals_h__
#define __signals_h__

typedef void (*sigint_handler_t)(void);

void signals_init(void);
void signals_setup_int(sigint_handler_t handler);

#endif // __signals_h__