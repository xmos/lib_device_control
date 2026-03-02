// Copyright 2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "control.h"
#if CONTROL_APP_DFU

#include "dfu_control_server.h"

#include <stdint.h>
#include <string.h>
#include <stdio.h>

#define DEBUG_UNIT DFU_SERVER
#define DEBUG_PRINT_ENABLE_DFU_SERVER 0
#include "debug_print.h"

#include "control_transport_shared.h"
#include "dfu.h"

#if USE_I2C
#define DFU_CONTROL_PAYLOAD_BYTES (I2C_DATA_MAX_BYTES)
#elif USE_SPI
#define DFU_CONTROL_PAYLOAD_BYTES (SPI_DATA_MAX_BYTES)
#elif USE_USB
#define DFU_CONTROL_PAYLOAD_BYTES (USB_DATA_MAX_BYTES)
#elif USE_XSCOPE
#define DFU_CONTROL_PAYLOAD_BYTES (XSCOPE_DATA_MAX_BYTES)
#else
#error "Transport not supported"
#endif

// TODO - build lib_device_control example using this server to build.

// [[combinable]]
void dfu_control_server(server interface control dfu_control_interface) {
    uint8_t local_payload[DFU_CONTROL_PAYLOAD_BYTES];

    while(1)
    {
        select
        {
            case dfu_control_interface.register_resources(control_resid_t resources[MAX_RESOURCES_PER_INTERFACE],  unsigned &num_resources): {
                resources[0] = RESOURCE_ID_DFU;
                num_resources = 1;
                // printf("DFU control server: register resources: %d\n", RESOURCE_ID_DFU);
            break;
            }

            case dfu_control_interface.write_command(control_resid_t resid, control_cmd_t cmd,
                    const uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret: {

                debug_printf("DFU write command received: resid=%d, cmd=%d, payload_len=%d\n", resid, cmd, payload_len);
                if (payload_len > sizeof(local_payload) && payload_len >= sizeof(struct dfu_dnload_header)) {
                    ret = CONTROL_DATA_LENGTH_ERROR;
                    break;
                } else if (resid != RESOURCE_ID_DFU) {
                    ret = CONTROL_BAD_COMMAND;
                    break;
                }

                int32_t request_length = payload_len;
                int32_t block_num = 0;
                
                if (payload_len != 0) {
                    size_t header_size = sizeof(struct dfu_dnload_header);
                    struct dfu_dnload_header header = { 0, 0 };
                    memcpy(&header, payload, header_size);
                    memcpy(local_payload, &payload[header_size], (payload_len - header_size));
                    block_num = header.block_num;
                    request_length = (payload_len - header_size);
                }
                struct dfu_cmd_response dfu_response = dfu_request_with_arguments(CONTROL_CMD_VALUE(cmd), local_payload, request_length, block_num);
                debug_printf("DFU write command status=%d\n", dfu_response.status);

                if (dfu_response.status == DFU_API_SUCCESS) {
                    ret = CONTROL_SUCCESS;
                } else if (dfu_response.status == DFU_API_DATA_LENGTH_ERROR) {
                    ret = CONTROL_DATA_LENGTH_ERROR;
                } else if (dfu_response.status == DFU_API_BAD_PARAM) {
                    ret = CONTROL_BAD_COMMAND;
                } else {
                    ret = CONTROL_ERROR;
                }

                if (dfu_response.reset_type == DFU_RESET_TYPE_RESET_TO_DFU) {
                    // TODO - handle reset to DFU, e.g. by delaying response and then rebooting after response is sent, or by delaying PHY initialisation on reboot so that device doesn't come back on bus until we're ready.
                    // For now just print message.
                    debug_printf("DFU write command: device needs to reboot to DFU mode\n");
                    // TODO - possibly simulate bus reset by sending command, instead of 3610 host app?
                }

                // WAS for reset timeout handling - might be needed/helpful for poll timeout handling, TBC
                // if (dfu_write_command_state.timeout.enable) {
                //     unsigned now;
                //     dfu_timer :> now;
                //     //debug_printf("now = %d\n", now);
                //     dfu_time = now + dfu_write_command_state.timeout.delta;
                // }
                // if (dfu_write_command_state.needs_reboot) {
                //     dfu_timer :> dfu_time;
                //     dfu_timer when timerafter(dfu_time + (DELAY_BEFORE_REBOOT_TO_DFU_MS * XS1_TIMER_KHZ)) :> void;
                //     // DFUDelay(DELAY_BEFORE_REBOOT_TO_DFU_MS * XS1_TIMER_KHZ);
                //     // device_reboot();
                // }
            break;
            }

            case dfu_control_interface.read_command(control_resid_t resid, control_cmd_t cmd,
                    uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret: {

                if (payload_len > sizeof(local_payload) && payload_len >= sizeof(struct dfu_upload_header)) {
                    ret = CONTROL_DATA_LENGTH_ERROR;
                    break;
                } else if (resid != RESOURCE_ID_DFU) {
                    ret = CONTROL_BAD_COMMAND;
                    break;
                }
                memset(local_payload, 0, sizeof(local_payload));

                struct dfu_cmd_response dfu_response = dfu_request_with_arguments(CONTROL_CMD_VALUE(cmd), local_payload, (payload_len - sizeof(struct dfu_upload_header)), null);
                struct dfu_upload_header header = { 0, 0 };
                if (dfu_response.status == DFU_API_SUCCESS) {
                    header.read_length = dfu_response.return_data_len;
                    memcpy(payload, &header, sizeof(header));

                    size_t payload_for_dfu = (payload_len - sizeof(header));
                    size_t read_len = (dfu_response.return_data_len > (int)payload_for_dfu) ? payload_for_dfu : dfu_response.return_data_len;
                    memcpy(payload + sizeof(header), local_payload, read_len);
                    ret = CONTROL_SUCCESS;
                } else if (dfu_response.status == DFU_API_DATA_LENGTH_ERROR) {
                    ret = CONTROL_DATA_LENGTH_ERROR;
                } else if (dfu_response.status == DFU_API_BAD_PARAM) {
                    ret = CONTROL_BAD_COMMAND;
                } else {
                    ret = CONTROL_ERROR;
                }
                debug_printf("DFU read command: cmd=%d, read_length=%d, payload_len=%d, status=%d\n", CONTROL_CMD_VALUE(cmd), header.read_length, (payload_len - sizeof(header)), dfu_response.status);
            break;
            }

            // WAS for reset timeout handling - might be needed/helpful for poll timeout handling, TBC
            // case dfu_write_command_state.timeout.enable => dfu_timer when timerafter(dfu_time) :> void:
            //     {   timer tmr;
            //         int t;
            //         tmr :> t;
            //         //debug_printf("t = %d\n", t);
            //     }
            //     //debug_printf("GPIO server: DFU timeout\n");
            //     dfu_timeout_detach();
            //     dfu_write_command_state.timeout.enable = false;
            // break;

        }// select
    }//While 1
}

#endif // CONTROL_APP_DFU
