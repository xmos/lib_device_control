// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#ifndef __control_h__
#define __control_h__

#include <stdint.h>
#include <stddef.h>

/** This is the version of control protocol. Used to check compatibility */
#define CONTROL_VERSION 0x10

/** These types are used in control functions to identify the resource id,
 *  command, version and return result.
 */
typedef uint8_t control_resid_t;
typedef uint8_t control_cmd_t;
typedef uint8_t control_version_t;
typedef uint8_t control_ret_t;

/** This type enumerates the possible outcomes from a control transaction
 */
enum control_ret_values {  /*This looks odd but helps us force byte enum */
  CONTROL_SUCCESS = 0,
  CONTROL_REGISTRATION_FAILED,
  CONTROL_BAD_COMMAND,
  CONTROL_DATA_LENGTH_ERROR,
  CONTROL_OTHER_TRANSPORT_ERROR,
  CONTROL_DEVICE_ERROR,
  CONTROL_ERROR
};

/** Resource count limits. Sets the size of the arrays used for storing the mappings
 */
#define MAX_RESOURCES_PER_INTERFACE 64
#define RESOURCE_TABLE_MAX 256
#define IFNUM_RESERVED 255

#define XSCOPE_CONTROL_PROBE "Control Probe"

#ifdef __XC__
/** This interface is used to communicate with the control library from the application
 */
typedef interface control {
  /** Request from host to register controllable resources with the control library. This is called once
   *  at startup and is necessary before control can take place.
   *
   *  \param resources      Array of resource IDs of size MAX_RESOURCES_PER_INTERFACE
   *  \param num_resources  Number of resources populated within the resources[] table
   *
   *  \returns              void
   */
  void register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                          unsigned &num_resources);
  /** Request from host to write to controllable resource in the device. The command consists of a resource ID,
   *  command and a byte payload of length payload_len.  
   *
   *  \param resid        Resource ID. Indicates which resource the command is intended for
   *  \param cmd          Command code. Note that this will be in the range 0x80 to 0xFF 
   *                      because bit 7 set indiciates a write command
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
   *                      because bit 7 cleared indiciates a read command
   *  \param payload      Array of bytes which constitutes the data payload
   *  \param payload_len  Size of the payload in bytes
   *
   *  \returns            Whether the handling of the read data by the device was successful or not
   */
  control_ret_t read_command(control_resid_t resid, control_cmd_t cmd,
                             uint8_t payload[payload_len], unsigned payload_len);
} control_if;

  /** Initiaize the control library. Clears resource table to ensure nothing is registered.
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
control_register_resources(client interface control i[n], unsigned n);

  /** Inform the control library that an I2C slave write has started. Called from I2C callback API.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the write start was successful or not
   */
control_ret_t
control_process_i2c_write_start(client interface control i[]);

  /** Inform the control library that an I2C slave read has started. Called from I2C callback API.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the read start was successful or not
   */
control_ret_t
control_process_i2c_read_start(client interface control i[]);

  /** Inform the control library that an I2C slave write has occured. Called from I2C callback API.
   *
   *  \param data       Array of byte data to be passed to the device
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the write was successful or not
   */
control_ret_t
control_process_i2c_write_data(const uint8_t data,
                               client interface control i[]);

  /** Inform the control library that an I2C slave read has occured. Called from I2C callback API.
   *
   *  \param data       Reference to array of byte data to be passed back from the device
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the read was successful or not
   */
control_ret_t
control_process_i2c_read_data(uint8_t &data,
                              client interface control i[]);

  /** Inform the control library that an I2C transaction has stopped. Called from I2C callback API.
   *
   *  \param i          Array of interfaces used to communicate with controllable entities
   *
   *  \returns          Whether the stop was successful or not
   */
control_ret_t
control_process_i2c_stop(client interface control i[]);

  /** Inform the control library that a USB set (write) has occured. Called from USB EP0 handler.
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
                                client interface control i[]);

  /** Inform the control library that a USB get (read) has occured. Called from USB EP0 handler.
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
                                client interface control i[]);

  /** Inform the control library that an xscope transfer has occured. Called from xscope handler.
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
                              unsigned length_in, unsigned &length_out,
                              client interface control i[]);

  /** Inform the control library that the SPI master has ended the transaction. If the command
   *  was a write, this is the point that a write command is emitted on the i_ctl interface.
   *
   *  \param i_ctl            Array of interfaces used to communicate with controllable entities
   *
   *  \returns                Whether the transfer was successful or not
   */
control_ret_t
control_process_spi_master_ends_transaction(client interface control i_ctl[]);

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
control_process_spi_master_requires_data(uint32_t &data, client interface control i_ctl[]);

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
control_process_spi_master_supplied_data(uint32_t datum, uint32_t valid_bits, client interface control i_ctl[]);

#endif // __XC__

#endif // __control_h__
