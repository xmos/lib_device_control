// Copyright 2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "control.h"
#if CONTROL_APP_DFU

#include "dfu_control_server.h"

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <xs1.h>

#define DEBUG_UNIT DFU_SERVER
#define DEBUG_PRINT_ENABLE_DFU_SERVER 0
#include "debug_print.h"

#include "control_transport_shared.h"
#include "dfu.h"

#if CONTROL_USE_I2C
#define DFU_CONTROL_PAYLOAD_BYTES (I2C_DATA_MAX_BYTES)
#elif CONTROL_USE_SPI
#define DFU_CONTROL_PAYLOAD_BYTES (SPI_DATA_MAX_BYTES)
#elif CONTROL_USE_USB
#define DFU_CONTROL_PAYLOAD_BYTES (USB_DATA_MAX_BYTES)
#elif CONTROL_USE_XSCOPE
#define DFU_CONTROL_PAYLOAD_BYTES (XSCOPE_DATA_MAX_BYTES)
#else
#error "Transport not supported"
#endif

// TODO - lib_device_control should build this code in an example, or test.

static timer dfu_timer;
static unsigned dfu_time;
static enum dfu_request dfu_deferred_action = 0;

/* Profiling */
static unsigned profile_dfu_start_time;
static unsigned profile_dfu_end_time;
static unsigned profile_dfu_index;

static struct dfu_profile_data profile_data;

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
                debug_printf("DFU control server: register resources: %d\n", RESOURCE_ID_DFU);
                break;
            }

            case dfu_control_interface.write_command(control_resid_t resid, control_cmd_t cmd,
                    const uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret: {

                profile_dfu_index += 1;
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
                
                dfu_timer :> profile_dfu_start_time;
                if (payload_len != 0) {
                    size_t header_size = sizeof(struct dfu_dnload_header);
                    struct dfu_dnload_header header = { 0, 0 };
                    memcpy(&header, payload, header_size);
                    memcpy(local_payload, &payload[header_size], (payload_len - header_size));
                    block_num = header.block_num;
                    request_length = (payload_len - header_size);
                }
                if (CONTROL_CMD_VALUE(cmd) == CONTROL_CMD_VALUE(XMOS_DFU_REVERTFACTORY)) {
                    // Restore revert-factory value, as this is affected by the read-bit in lib_device_control.
                    cmd = XMOS_DFU_REVERTFACTORY;
                }
                struct dfu_cmd_response dfu_response = dfu_request_with_arguments(cmd, local_payload, request_length, block_num);
                dfu_timer :> profile_dfu_end_time;
                unsigned dfu_command_time = profile_dfu_end_time - profile_dfu_start_time;
                if (dfu_command_time > profile_data.command_time) {
                    profile_data.command_time = dfu_command_time;
                    profile_data.command_index = profile_dfu_index;
                    profile_data.cmd = CONTROL_CMD_VALUE(cmd);
                }

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

                if (dfu_response.deferred_request == DFU_DEFERRED_ACTION_REBOOT_TO_DFU) {
                    /* This is USB DFU mode entry mechanism, for non-USB ignore. */
                } else if (dfu_response.deferred_request == DFU_DEFERRED_ACTION_FLASH_CONNECT) {
                    dfu_deferred_action = dfu_response.deferred_request;
                }

                dfu_timer :> dfu_time;
                dfu_time += (1 * XS1_TIMER_KHZ);
                break;
            }

            case dfu_control_interface.read_command(control_resid_t resid, control_cmd_t cmd,
                    uint8_t payload[payload_len], unsigned payload_len) -> control_ret_t ret: {

                profile_dfu_index += 1;
                if (payload_len > sizeof(local_payload) || payload_len < sizeof(struct dfu_upload_header)) {
                    ret = CONTROL_DATA_LENGTH_ERROR;
                    break;
                } else if (resid != RESOURCE_ID_DFU) {
                    ret = CONTROL_BAD_COMMAND;
                    break;
                }
                memset(local_payload, 0, sizeof(local_payload));

                /* Read profile data */
                if (CONTROL_CMD_VALUE(cmd) == CONTROL_CMD_VALUE(XMOS_DFU_GETPROFILE)) {
                    struct dfu_upload_header prof_header = { 0, 0 };
                    prof_header.read_length = sizeof(struct dfu_profile_data);
                    memcpy(payload, &prof_header, sizeof(prof_header));

                    profile_data.index_total = profile_dfu_index;
                    memcpy(payload + sizeof(prof_header), &profile_data, (payload_len - sizeof(prof_header)));
                    ret = CONTROL_SUCCESS;
                    break;
                }

                dfu_timer :> profile_dfu_start_time;
                struct dfu_cmd_response dfu_response = dfu_request_with_arguments(CONTROL_CMD_VALUE(cmd), local_payload, (payload_len - sizeof(struct dfu_upload_header)), null);
                struct dfu_upload_header header = { 0, 0 };
                if (dfu_response.status == DFU_API_SUCCESS) {
                    header.read_length = dfu_response.return_data_len;
                    dfu_deferred_action = dfu_response.deferred_request;
                    if (dfu_deferred_action != 0) {
                        debug_printf("DFU read command: deferred action %d\n", dfu_deferred_action);
                    }
                    // TODO - get at block_num here.
                    // header.block_num = dfu_response.block_num;
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
                dfu_timer :> profile_dfu_end_time;
                unsigned dfu_command_time = profile_dfu_end_time - profile_dfu_start_time;
                if (dfu_command_time > profile_data.command_time) {
                    profile_data.command_time = dfu_command_time;
                    profile_data.command_index = profile_dfu_index;
                    profile_data.cmd = CONTROL_CMD_VALUE(cmd);
                }

                debug_printf("DFU read command: cmd=%d, read_length=%d, payload_len=%d, status=%d\n", CONTROL_CMD_VALUE(cmd), header.read_length, (payload_len - sizeof(header)), dfu_response.status);
                dfu_timer :> dfu_time;
                dfu_time += (1 * XS1_TIMER_KHZ);
                break;
            }

            case (dfu_deferred_action != 0) => dfu_timer when timerafter(dfu_time) :> void: {

                debug_printf("deferred action: %d\n", dfu_deferred_action);
                dfu_request_with_arguments(dfu_deferred_action, null, 0, null);
                dfu_deferred_action = 0;
                break;
            }

        }// select
    }//While 1
}

#endif // CONTROL_APP_DFU
