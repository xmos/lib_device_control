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
#include <xccompat.h>
#endif

#if USE_XSCOPE || __DOXYGEN__
/** Initialize the xscope host interface
 *
 *  \param host_str    String containing the name of the xscope host. Eg. "localhost"
 *  \param port_str    String containing the port number of the xscope host
 *
 *  \returns           Whether the initialization was successful or not
 */
control_ret_t control_init_xscope(const char *host_str, const char *port_str);
/** Shutdown the xscope host interface
 *
 *  \returns           Whether the shutdown was successful or not
 */
control_ret_t control_cleanup_xscope(void);
#endif
#if USE_I2C || __DOXYGEN__
/** Initialize the I2C host (master) interface
 *
 *  \param i2c_slave_address    I2C address of the slave (controlled device)
 *
 *  \returns                    Whether the initialization was successful or not
 */
control_ret_t control_init_i2c(unsigned char i2c_slave_address);
/** Shutdown the I2C host (master) interface connection
 *
 *  \returns           Whether the shutdown was successful or not
 */
control_ret_t control_cleanup_i2c(void);
#endif
#if USE_USB || __DOXYGEN__
/** Initialize the USB host interface
 *
 *  \param vendor_id    Vendor ID of controlled USB device
 *  \param product_id   Product ID of controlled USB device
 *  \param interface    USB Control interface number of controlled device
 *
 *  \returns           Whether the initialization was successful or not
 */
control_ret_t control_init_usb(int vendor_id, int product_id, int interface_num);
/** Shutdown the USB host interface connection
 *
 *  \returns           Whether the shutdown was successful or not
 */
control_ret_t control_cleanup_usb(void);
#endif
#if (!USE_USB && !USE_XSCOPE && !USE_I2C)
#error "Please specify transport for lib_device_control using USE_xxx define in Makefile"
#error "Eg. XCC_FLAGS = -DUSE_I2C=1"
#endif // USE_XSCOPE

#if USE_I2C && __xcore__
/** Checks to see that the version of control library in the device is the same as the host
 *
 *  \param version      Reference to control version variable that is set on this call
 *  \param i_i2c        The xC interface used for communication with the I2C library (only for xCore I2C host)
 *
 *  \returns            Whether the checking of control library version was successful or not
 */
control_ret_t control_query_version(control_version_t *version,
                                    CLIENT_INTERFACE(i2c_master_if, i_i2c));
#else
/** Checks to see that the version of control library in the device is the same as the host
 *
 *  \param version      Reference to control version variable that is set on this call
 *
 *  \returns            Whether the checking of control library version was successful or not
 */
control_ret_t control_query_version(control_version_t *version);
#endif

/** Request to write to controllable resource inside the device. The command consists of a resource ID,
 *  command and a byte payload of length payload_len.
 *
 *  \param resid        Resource ID. Indicates which resource the command is intended for
 *  \param cmd          Command code. Note that this will be in the range 0x80 to 0xFF
 *                      because bit 7 set indiciates a write command
 *  \param payload      Array of bytes which constitutes the data payload
 *  \param payload_len  Size of the payload in bytes
 *
 *  \returns            Whether the write to the device was successful or not
 */
control_ret_t
control_write_command(control_resid_t resid, control_cmd_t cmd,
#if USE_I2C && __xcore__
                      CLIENT_INTERFACE(i2c_master_if, i_i2c),
#endif
                      const uint8_t payload[], size_t payload_len);

/** Request to read from controllable resource inside the device. The command consists of a resource ID,
 *  command and a byte payload of length payload_len.
 *
 *  \param resid        Resource ID. Indicates which resource the command is intended for
 *  \param cmd          Command code. Note that this will be in the range 0x80 to 0xFF
 *                      because bit 7 set indiciates a write command
 *  \param payload      Array of bytes which constitutes the data payload
 *  \param payload_len  Size of the payload in bytes
 *
 *  \returns            Whether the read from the device was successful or not
 */
control_ret_t
control_read_command(control_resid_t resid, control_cmd_t cmd,
#if USE_I2C && __xcore__
                     CLIENT_INTERFACE(i2c_master_if, i_i2c),
#endif
                     uint8_t payload[], size_t payload_len);

#ifdef __cplusplus
}
#endif

#endif // __control_host_h__
