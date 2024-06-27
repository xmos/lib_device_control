// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __control_shared_h__
#define __control_shared_h__

#include <stdint.h>
#include <stddef.h>

/**
 * \defgroup control_shared
 *
 * The shared API for using the device control library on the device and host
 * @{
 */

/**
 * This is the version of control protocol. Used to check compatibility
 */
#define CONTROL_VERSION 0x10

/**
 * @{
 * These types are used in control functions to identify the resource id,
 * command, version, and status.
 */
typedef uint8_t control_resid_t;
typedef uint8_t control_cmd_t;
typedef uint8_t control_version_t;
typedef uint8_t control_status_t;
/**@}*/

/**
 * This type enumerates the possible outcomes from a control transaction.
 */
/* TODO: Some of the enum values below should be used
    when https://xmosjira.atlassian.net/browse/LSM-71 is addressed */
typedef enum {
    CONTROL_SUCCESS = 0,
    CONTROL_REGISTRATION_FAILED,
    CONTROL_BAD_COMMAND,
    CONTROL_DATA_LENGTH_ERROR,
    CONTROL_OTHER_TRANSPORT_ERROR,
    CONTROL_BAD_RESOURCE,
    CONTROL_MALFORMED_PACKET,
    CONTROL_COMMAND_IGNORED_IN_DEVICE,
    CONTROL_ERROR,

    SERVICER_COMMAND_RETRY = 64,
    SERVICER_WRONG_COMMAND_ID,
    SERVICER_WRONG_COMMAND_LEN,
    SERVICER_WRONG_PAYLOAD,
    SERVICER_QUEUE_FULL,
    SERVICER_RESOURCE_ERROR,

} control_ret_t;

/**@}*/

#endif /* __control_shared_h__ */
