// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_h__
#define __control_h__

#include <stdint.h>
#include <stddef.h>

#define CONTROL_VERSION 0x10

typedef uint8_t control_resid_t;
typedef uint8_t control_cmd_t;

typedef uint8_t control_ret_t;
enum {  // force short enum
  CONTROL_SUCCESS = 0,
  CONTROL_REGISTRATION_FAILED,
  CONTROL_BAD_COMMAND,
  CONTROL_DATA_LENGTH_ERROR,
  CONTROL_OTHER_TRANSPORT_ERROR,
  CONTROL_ERROR
};

#define MAX_RESOURCES_PER_INTERFACE 64
#define MAX_RESOURCES 256

#define XSCOPE_UPLOAD_MAX_WORDS 64
#define XSCOPE_CONTROL_PROBE "Control Probe"

#ifdef __XC__

typedef interface control {
  void register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                          unsigned &num_resources);

  control_ret_t write_command(control_resid_t r, control_cmd_t c, const uint8_t data[n], unsigned n);

  control_ret_t read_command(control_resid_t r, control_cmd_t c, uint8_t data[n], unsigned n);
} control_if;

control_ret_t
control_init(void);

control_ret_t
control_register_resources(client interface control i[n], unsigned n);

control_ret_t
control_process_i2c_write_start(client interface control i[]);

control_ret_t
control_process_i2c_read_start(client interface control i[]);

control_ret_t
control_process_i2c_write_data(const uint8_t data,
                               client interface control i[]);

control_ret_t
control_process_i2c_read_data(uint8_t &data,
                              client interface control i[]);

control_ret_t
control_process_i2c_stop(client interface control i[]);

control_ret_t
control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                const uint8_t request_data[],
                                client interface control i[]);

control_ret_t
control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                uint8_t request_data[],
                                client interface control i[]);

/* data return is device (control library) initiated
 * require word alignment so we can cast to struct
 */
control_ret_t
control_process_xscope_upload(uint32_t data_in_and_out[XSCOPE_UPLOAD_MAX_WORDS],
                              unsigned length_in, unsigned &length_out,
                              client interface control i[]);

#endif

#endif // __control_h__
