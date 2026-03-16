// Copyright 2016-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef CONTROL_H
#define CONTROL_H

#include <stdint.h>
#include <stddef.h>

#include "control_shared.h"
#include "control_default_conf.h"

/** Resource count limits. Sets the size of the arrays used for storing the mappings */
#define MAX_RESOURCES_PER_INTERFACE 64
#define RESOURCE_TABLE_MAX 256
#define IFNUM_RESERVED 255

/** Number of bits that can be transferred in a single SPI transaction.
 *  32-bit transactions are not supported.
 */
#define SPI_TRANSFER_SIZE_BITS  8

#if defined(__XC__) || defined(__DOXYGEN__)
#include "xccompat.h"

#ifndef __DOXYGEN__
/* This interface is used to communicate with the control library from the application */
typedef interface control {
#endif
  /** \addtogroup control
   * 
   * This interface is used to communicate with the control library from the application
   * \{
   */

  /** Request from host to register controllable resources with the control library. This is called once
   *  at startup and is necessary before control can take place.
   *
   *  \param resources      Array of resource IDs of size MAX_RESOURCES_PER_INTERFACE
   *  \param num_resources  Number of resources populated within the resources[] table
   *
   */
  void register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                          REFERENCE_PARAM(unsigned, num_resources));
  /** Request from host to write to controllable resource in the device. The command consists of a resource ID,
   *  command and a byte payload of length payload_len.
   *
   *  \param resid        Resource ID. Indicates which resource the command is intended for
   *  \param cmd          Command code. Note that this will be in the range 0x80 to 0xFF
   *                      because bit 7 set indicates a write command
   *  \param payload      Array of bytes which constitutes the data payload
   *  \param payload_len  Size of the payload in bytes
   *
   *  \returns            Whether the handling of the write data by the device was successful or not
   */
  control_ret_t write_command(control_resid_t resid, control_cmd_t cmd,
                              const uint8_t payload[payload_len], unsigned payload_len);
  /** Request from host to read a controllable resource in the device. The command consists of a resource ID,
   *  command and a byte payload of length payload_len.
   *
   *  \param resid        Resource ID. Indicates which resource the command is intended for
   *  \param cmd          Command code. Note that this will be in the range 0x00 to 0x7F
   *                      because bit 7 cleared indicates a read command
   *  \param payload      Array of bytes which constitutes the data payload
   *  \param payload_len  Size of the payload in bytes
   *
   *  \returns            Whether the handling of the read data by the device was successful or not
   */
  control_ret_t read_command(control_resid_t resid, control_cmd_t cmd,
                             uint8_t payload[payload_len], unsigned payload_len);

   /** \} */
#ifndef __DOXYGEN__
} control_if;
#endif
#endif // defined(__XC__) || defined(__DOXYGEN__)

/**
 * Macro that expands to an array of client interfaces when used in an XC
 * source file and to a pointer to the specified type when used in
 * a C/C++ source file.
 */
#ifndef CLIENT_INTERFACE_ARRAY
#ifdef __XC__
#define CLIENT_INTERFACE_ARRAY(tag, name, size) client interface tag name[size]
#else
#define CLIENT_INTERFACE_ARRAY(type, name, size) unsigned *name
#endif
#endif

/**
 * Macro that expands to an array of server interfaces when used in an XC
 * source file and to a pointer to the specified type when used in
 * a C/C++ source file.
 */
#ifndef SERVER_INTERFACE_ARRAY
#ifdef __XC__
#define SERVER_INTERFACE_ARRAY(tag, name, size) server interface tag name[size]
#else
#define SERVER_INTERFACE_ARRAY(type, name, size) unsigned *name
#endif
#endif

  /** Initialize the control library. Clears resource table to ensure nothing is registered.
   *
   *  \returns            Whether the initialization was successful or not
   */
control_ret_t
control_init(void);

  /** Sends a request to the application to register controllable resources.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *  \param n          The number of interfaces used
   *
   *  \returns          Whether the registration was successful or not
   */
control_ret_t
control_register_resources(CLIENT_INTERFACE_ARRAY(control, i, n), unsigned n);

  /** Inform the control library that an I2C slave write has started. Called from I2C callback API.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the write start was successful or not
   */
control_ret_t
control_process_i2c_write_start(CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that an I2C slave read has started. Called from I2C callback API.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the read start was successful or not
   */
control_ret_t
control_process_i2c_read_start(CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that an I2C slave write has occurred. Called from I2C callback API.
   *
   *  \param data       Array of byte data to be passed to the device
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the write was successful or not
   */
control_ret_t
control_process_i2c_write_data(const uint8_t data,
                               CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that an I2C slave read has occurred. Called from I2C callback API.
   *
   *  \param data       Reference to array of byte data to be passed back from the device
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the read was successful or not
   */
control_ret_t
control_process_i2c_read_data(REFERENCE_PARAM(uint8_t, data),
                              CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that an I2C transaction has stopped. Called from I2C callback API.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the stop was successful or not
   */
control_ret_t
control_process_i2c_stop(CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that a USB set (write) has occurred. Called from USB EP0 handler.
   *
   *  \param windex       wIndex field from the USB Setup packet
   *  \param wvalue       wValue field from the USB Setup packet
   *  \param wlength      wLength field from the USB Setup packet
   *  \param request_data Array of byte data to be written to the device
   *  \param i            Array of interfaces used to communicate with controllable entities
   *
   *  \returns            Whether the write was successful or not
   */
control_ret_t
control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                const uint8_t request_data[],
                                CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that a USB get (read) has occurred. Called from USB EP0 handler.
   *
   *  \param windex       wIndex field from the USB Setup packet
   *  \param wvalue       wValue field from the USB Setup packet
   *  \param wlength      wLength field from the USB Setup packet
   *  \param request_data Reference to array of byte data to be passed back from the device
   *  \param i            Array of interfaces used to communicate with controllable entities
   *
   *  \returns            Whether the read was successful or not
   */
control_ret_t
control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                uint8_t request_data[],
                                CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that an xscope transfer has occurred. Called from xscope handler.
   *  This function both reads and writes data in a single call.
   *  The data return is device (control library) initiated. Note: Data requires word alignment
   *  so we can cast to struct.
   *
   *  \param buf              Array of bytes for read and write data.
   *  \param buf_size         Array size in bytes
   *  \param length_in        Number of bytes to be written to device
   *  \param length_out       Number of bytes returned from device to be read by host
   *  \param i                Array of interfaces used to communicate with controllable entities
   *
   *  \returns                Whether the transfer was successful or not
   */
control_ret_t
control_process_xscope_upload(uint8_t buf[], unsigned buf_size,
                              unsigned length_in, REFERENCE_PARAM(unsigned, length_out),
                              CLIENT_INTERFACE(control, i[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that the SPI master has ended the transaction. If the command
   *  was a write, this is the point that a write command is emitted on the i_ctl interface.
   *
   *  \param i_ctl            Array of interfaces used to communicate with controllable entities
   *
   *  \returns                Whether the transfer was successful or not
   */
control_ret_t
control_process_spi_master_ends_transaction(CLIENT_INTERFACE(control, i_ctl[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that the SPI master requires data. If the command
   *  was a read, then this is the point that a read command is emitted on the i_ctl interface.
   *  The master will then end the transaction and pause. The data will be sent to the master
   *  on the next transaction.
   *
   *  \param data             The data to be sent over SPI
   *  \param i_ctl            Array of interfaces used to communicate with controllable entities
   *
   *  \returns                Whether the transfer was successful or not
   */
control_ret_t
control_process_spi_master_requires_data(REFERENCE_PARAM(uint32_t, data), CLIENT_INTERFACE(control, i_ctl[CONTROL_INTERFACES_NUM]));

  /** Inform the control library that the SPI master supplied data.
   *  NOTE: It is assumed that the datum is 8 bits wide, i.e. spi_slave(...) is set up with
   *        SPI_TRANSFER_SIZE_8 as its last parameter.
   *
   *  \param datum            The data provided by the SPI master
   *  \param valid_bits       The bits that are valid in datum
   *  \param i_ctl            Array of interfaces used to communicate with controllable entities
   *
   *  \returns                Whether the transfer was successful or not
   */
control_ret_t
control_process_spi_master_supplied_data(uint32_t datum, uint32_t valid_bits, CLIENT_INTERFACE(control, i_ctl[CONTROL_INTERFACES_NUM]));

#endif // CONTROL_H
