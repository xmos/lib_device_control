// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_host_support.h"
#include "resource.h"
#include "support.h"
#include "support_inline.h"
#include "user_task.h"

void test_client(client interface control i[3], chanend c_user_task[3])
{
  uint8_t buf[SPI_TRANSACTION_MAX_BYTES];
  size_t buf_len;
  struct command c1, c2;
  struct options o;
  int timeout;
  timer tmr;
  int t, j;
  uint8_t *unsafe payload_ptr;
  int fails;
  unsigned payload_size;
  chan d;
  uint32_t data_32bit;
  uint8_t write_status = 0;
  for (j = 0; j < 8; j++) {
    c1.payload[j] = j;
  }

  control_init();

  /* trigger a registration call, catch it and supply resource IDs to register */
  par {
    control_register_resources(i, 3);
    drive_user_task_registration(c_user_task, 3);
  }

  fails = 0;

  for (c1.ifnum = 0; c1.ifnum < 4; c1.ifnum++) {
    for (o.read_cmd = 0; o.read_cmd < 2; o.read_cmd++) {
      for (o.res_in_if = 0; o.res_in_if < 3; o.res_in_if++) {
        for (o.bad_id = 0; o.bad_id < 2; o.bad_id++) {
          for (o.with_payload = 0; o.with_payload < 2; o.with_payload++) {
            make_command(c1, o);

            // Prepare message header and payload
            buf_len = control_build_spi_data(buf, c1.resid, c1.cmd, c1.payload, c1.payload_size);

            /* make a sequence of processing calls, catch the result and record it */
            unsafe {
              payload_size = c1.payload_size;
              // pointer to payload used for read commands, including CONTROL_GET_LAST_COMMAND_STATUS
              payload_ptr = c2.payload;

              tmr :> t;
              timeout = 0;
              par {
                { control_ret_t ret;
                  ret = CONTROL_SUCCESS;
                  ret |= control_process_spi_master_ends_transaction(i);

                  // Send message information in a write transaction
                  for (j = 0; j < buf_len; j++) {
                    ret |= control_process_spi_master_supplied_data(buf[j], SPI_TRANSFER_SIZE_BITS, i);
                    ret |= control_process_spi_master_requires_data(data_32bit, i);

                  }
                  ret |= control_process_spi_master_ends_transaction(i);

                  // Read back values in a read transaction if it is a read message
                  if (o.read_cmd && payload_size > 0) {
                    for (j = 0; j < (payload_size); j++) {
                      ret |= control_process_spi_master_supplied_data(0, SPI_TRANSFER_SIZE_BITS, i);
                      ret |= control_process_spi_master_requires_data(data_32bit, i);

                      memcpy(payload_ptr+j, &data_32bit, sizeof(uint8_t));
                    }
                    ret |= control_process_spi_master_ends_transaction(i);
                  }

                  // Request control status for write command if it is a write command
                  if (!o.read_cmd) {
                    buf_len = control_build_spi_data(buf, CONTROL_SPECIAL_RESID, CONTROL_CMD_SET_READ(CONTROL_GET_LAST_COMMAND_STATUS), c1.payload, sizeof(control_status_t));
                    for (j = 0; j < buf_len; j++) {
                      ret |= control_process_spi_master_supplied_data(buf[j], SPI_TRANSFER_SIZE_BITS, i);
                      ret |= control_process_spi_master_requires_data(data_32bit, i);
                    }
                    ret |= control_process_spi_master_ends_transaction(i);

                    ret |= control_process_spi_master_supplied_data(data_32bit, SPI_TRANSFER_SIZE_BITS, i);
                    ret |= control_process_spi_master_requires_data(data_32bit, i);
                    memcpy(&write_status, &data_32bit, sizeof(control_status_t));
                    ret |= write_status;
                    ret |= control_process_spi_master_ends_transaction(i);

                  }
                  d <: ret;
                }
                { control_ret_t ret;
                  select {
                    case drive_user_task_commands(c2, c1, c_user_task, o.read_cmd);
                    case tmr when timerafter(t + 2000) :> void:
                      timeout = 1;
                      break;
                  }
                  d :> ret;
                  fails += check(o, c1, c2, timeout, ret, 3);
                }
              }
            }
          }
        }
      }
    }
  }

  if (fails == 0) {
    printf("Success!\n");
    exit(0);
  }
  else {
    printf("ERROR - %d fails found\n", fails);
    exit(1);
  }
}

int main(void)
{
  interface control i[3];
  chan c_user_task[3];
  par {
    test_client(i, c_user_task);
    user_task(i[0], c_user_task[0]);
    user_task(i[1], c_user_task[1]);
    user_task(i[2], c_user_task[2]);
    { delay_microseconds(10000);
      printf("ERROR - test timeout\n");
      exit(1);
    }
  }
  return 0;
}
