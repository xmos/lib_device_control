// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_host_h__
#define __control_host_h__

#include "control.h"
#include "control_transport.h"

#ifdef __cplusplus 
extern "C" {
#endif

#if USE_I2C && __xcore__
#include "i2c.h"
#endif

#if USE_XSCOPE
control_ret_t control_init_xscope(const char *host_str, const char *port_str);
control_ret_t control_cleanup_xscope(void);
#elif USE_I2C
control_ret_t control_init_i2c(unsigned char i2c_slave_address);
control_ret_t control_cleanup_i2c(void);
#elif USE_USB
control_ret_t control_init_usb(int vendor_id, int product_id);
control_ret_t control_cleanup_usb(void);
#else
#error "Please specify transport for lib_device_control using USE_xxx define and configure in config.h"
#endif // USE_XSCOPE

#if USE_I2C && __xcore__
control_ret_t control_query_version(control_version_t *version,
                                    client interface i2c_master_if i_i2c);
#else
control_ret_t control_query_version(control_version_t *version);
#endif

control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
#if USE_I2C && __xcore__
                      client interface i2c_master_if i_i2c,
#endif
                      const uint8_t payload[], size_t payload_len);

control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
#if USE_I2C && __xcore__
                     client interface i2c_master_if i_i2c,
#endif
                     uint8_t payload[], size_t payload_len);

#ifdef __cplusplus
}
#endif

#endif // __control_host_h__
