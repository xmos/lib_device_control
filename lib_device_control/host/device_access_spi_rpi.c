// Copyright (c) 2017, XMOS Ltd, All rights reserved
#if USE_SPI && RPI

#include "control_host.h"
#include "control_host_support.h"

//#define DBG(x) x
#define DBG(x)

#endif /* USE_SPI && RPI */

control_ret_t
control_init_spi(spi_mode_t spi_mode, int spi_bitrate, unsigned delay_for_read)
{
  return CONTROL_SUCCESS;
}

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
                      const uint8_t payload[], size_t payload_len)
{
  return CONTROL_SUCCESS;
}

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
                     uint8_t payload[], size_t payload_len)
{
  return CONTROL_SUCCESS;
}

control_ret_t control_cleanup_spi(void)
{
  return CONTROL_SUCCESS;
}