// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifdef HOST_APP //Prevent XC compiler from picking this up
#ifndef __signals_h__
#define __signals_h__

typedef void (*sigint_handler_t)(void);

void signals_init(void);
void signals_setup_int(sigint_handler_t handler);

#endif // __signals_h__
#endif //HOST_APP