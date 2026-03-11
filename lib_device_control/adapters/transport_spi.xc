// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "control.h"
#if CONTROL_USE_SPI

#include "transport_spi.h"

#include <platform.h>

#include "spi.h"

// SPI transport client processing function, this passes SPI data to the control interface.
//
// To include this file in the build, define CONTROL_USE_SPI as 1, in control_conf.h

void spi_control_client(server spi_slave_callback_if i_spi, client interface control i_control[])
{
  while (1) {
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
    select {
      case i_spi.master_ends_transaction():
        control_process_spi_master_ends_transaction(i_control);
        break;
      case i_spi.master_requires_data() -> uint32_t data:
        control_process_spi_master_requires_data(data, i_control);
        break;
      case i_spi.master_supplied_data(uint32_t datum, uint32_t valid_bits):
        control_process_spi_master_supplied_data(datum, valid_bits, i_control);
        break;
    }
#pragma warning enable
  }
}

#endif // CONTROL_USE_SPI
