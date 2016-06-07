// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __control_h__
#define __control_h__

#include <stdint.h>
#include <stddef.h>

typedef uint8_t control_resid_t;
typedef uint8_t control_cmd_t;
typedef enum {
  CONTROL_SUCCESS,
  CONTROL_ERROR
} control_res_t;

#define MAX_RESOURCES_PER_INTERFACE 64
#define MAX_RESOURCES 256

#define XSCOPE_UPLOAD_MAX_WORDS 64
#define XSCOPE_CONTROL_PROBE "Control Probe"

#ifdef __XC__

typedef interface control {
  void register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],
                          unsigned &num_resources);

  control_res_t write_command(control_resid_t r, control_cmd_t c, const uint8_t data[n], unsigned n);

  control_res_t read_command(control_resid_t r, control_cmd_t c, uint8_t data[n], unsigned n);
} control_if;

void control_init(client interface control i[n], unsigned n);

control_res_t
control_process_i2c_write_start(client interface control i[n], unsigned n);

control_res_t
control_process_i2c_read_start(client interface control i[n], unsigned n);

control_res_t
control_process_i2c_write_data(const uint8_t data,
                               client interface control i[n], unsigned n);

control_res_t
control_process_i2c_read_data(uint8_t &data,
                              client interface control i[n], unsigned n);

control_res_t
control_process_i2c_stop(client interface control i[n], unsigned n);

void control_process_usb_set_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     const uint8_t request_data[],
                                     client interface control i[n], unsigned n);

void control_process_usb_get_request(uint16_t windex, uint16_t wvalue, uint16_t wlength,
                                     uint8_t request_data[],
                                     client interface control i[n], unsigned n);

/* data return is device (control library) initiated
 * require word alignment so we can cast to struct
 */
void control_process_xscope_upload(uint32_t data_in_and_out[XSCOPE_UPLOAD_MAX_WORDS],
                                   unsigned length_in, unsigned &length_out,
                                   client interface control i[n], unsigned n);

#endif

#endif // __control_h__
