// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef SIGNALS_H_
#define SIGNALS_H_

typedef void (*sigint_handler_t)(void);

void signals_init(void);
void signals_setup_int(sigint_handler_t handler);

#endif // SIGNALS_H_