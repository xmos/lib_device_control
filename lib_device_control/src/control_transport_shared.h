// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __control_transport_shared_h__
#define __control_transport_shared_h__

#include "control_shared.h"

/**
 * \defgroup control_transport_shared
 *
 * The internal defines and structs for using the device control library on the device and host
 * @{
 */

/**
 * Checks if the read bit is set in a command code.
 *
 * \param[in] c The command code to check
 *
 * \returns true if the read bit in the command is set
 * \returns false if the read bit is not set
 */
#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)

/**
 * Sets the read bit on a command code
 *
 * \param[in,out] c The command code to set the read bit on.
 */
#define CONTROL_CMD_SET_READ(c) ((c) | 0x80)

/**
 * Clears the read bit on a command code
 *
 * \param[in,out] c The command code to clear the read bit on.
 */
#define CONTROL_CMD_SET_WRITE(c) ((c) & ~0x80)

/**
 * This is the special resource ID owned by the control library.
 * It can be used to check the version of the control protocol.
 * Servicers may not register this resource ID.
 */
#define CONTROL_SPECIAL_RESID 0

/**
 * The command to read the version of the control protocol.
 * It must be sent to resource ID CONTROL_SPECIAL_RESID.
 */
#define CONTROL_GET_VERSION CONTROL_CMD_SET_READ(0)

/**
 * The command to read the return status of the last command.
 * It must be sent to resource ID CONTROL_SPECIAL_RESID.
 */
#define CONTROL_GET_LAST_COMMAND_STATUS CONTROL_CMD_SET_READ(1)

#if USE_XSCOPE
struct control_xscope_packet {
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload_len;
  uint8_t pad;
};

struct control_xscope_response {
  control_resid_t resid;
  control_cmd_t cmd;
  uint8_t payload_len;
  control_ret_t ret;
};
#endif

/**@}*/

#endif // __control_transport_shared_h_