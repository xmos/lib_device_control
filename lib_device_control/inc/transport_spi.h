// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef TRANSPORT_SPI_H
#define TRANSPORT_SPI_H

#include <xccompat.h>

#include "control.h"
#include "spi.h"

/** SPI transport client processing function, this passes SPI data to the control interface.
 * \param i_spi     SPI slave callback interface
 * \param i_control Control interface array
 * 
 */
void spi_control_client(SERVER_INTERFACE(spi_slave_callback_if, i_spi), CLIENT_INTERFACE(control, i_control[]));

#endif // TRANSPORT_SPI_H
