typedef void (*sigint_handler_t)(void);

void signals_init(void);
void signals_setup_int(sigint_handler_t handler);
