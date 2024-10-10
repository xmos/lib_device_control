// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <assert.h>
#include <xscope.h>
#include <stdio.h>
#include <stdint.h>
#include "control.h"
#include "app.h"

#define DEBUG_UNIT DEVICE
#include "debug_print.h"

#include <spi.h>
on tile[SPI_TILE]: in port                 p_sclk = PORT_SPI_SLAVE_SCLK;
on tile[SPI_TILE]: in port                 p_ss   = PORT_SPI_SLAVE_CS;
on tile[SPI_TILE]: out buffered port:32    p_miso = PORT_SPI_SLAVE_MISO;
on tile[SPI_TILE]: in buffered port:32     p_mosi = PORT_SPI_SLAVE_MOSI;
on tile[SPI_TILE]: clock                   cb     = XS1_CLKBLK_1;

static void spi_client(server spi_slave_callback_if i_spi, client interface control i_control[1])
{
  while (1) {
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
  }
}

void spi_ctrl(client interface control i_control[1])
{
  interface spi_slave_callback_if i_spi;
  control_init();
  control_register_resources(i_control, 1);
  par {
    spi_client(i_spi, i_control);
    spi_slave(i_spi, p_sclk, p_mosi, p_miso, p_ss, cb,
              SPI_MODE_3, SPI_TRANSFER_SIZE_8);
  }
}


int main(void)
{
  interface control i_control[1];
  par {
    on tile[SPI_TILE]: par {
      spi_ctrl(i_control);
    }
    on tile[0]: par {
      app(i_control[0]);
    }
  }
  return 0;
}
