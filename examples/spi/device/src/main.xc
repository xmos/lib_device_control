// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <assert.h>
#include <xscope.h>
#include <stdio.h>
#include <stdint.h>
#include "control.h"
#include "app.h"

#include <spi.h>
#include "transport_spi.h"

on tile[PORT_SPI_SLAVE_SCLK_TILE_NUM]: clock                cb     = XS1_CLKBLK_1;
on tile[PORT_SPI_SLAVE_SCLK_TILE_NUM]: in port              p_sclk = PORT_SPI_SLAVE_SCLK;
on tile[PORT_SPI_SLAVE_CS_TILE_NUM]: in port                p_ss   = PORT_SPI_SLAVE_CS;
on tile[PORT_SPI_SLAVE_MISO_TILE_NUM]: out buffered port:32 p_miso = PORT_SPI_SLAVE_MISO;
on tile[PORT_SPI_SLAVE_MOSI_TILE_NUM]: in buffered port:32  p_mosi = PORT_SPI_SLAVE_MOSI;

void spi_ctrl(client interface control i_control[1])
{
  interface spi_slave_callback_if i_spi;
  control_init();
  control_register_resources(i_control, 1);
  par {
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
    spi_control_client(i_spi, i_control);
#pragma warning enable
    spi_slave(i_spi, p_sclk, p_mosi, p_miso, p_ss, cb,
              SPI_MODE_3, SPI_TRANSFER_SIZE_8);
  }
}


int main(void)
{
  interface control i_control[1];
  par {
    on tile[PORT_SPI_SLAVE_SCLK_TILE_NUM]: par {
      spi_ctrl(i_control);
    }
    on tile[0]: par {
      app(i_control[0]);
    }
  }
  return 0;
}
