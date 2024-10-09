// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef CONTROL_SHARED_H_
#define CONTROL_SHARED_H_

#include <stdint.h>
#include <stddef.h>

#pragma once

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
typedef uint8_t control_ret_t;
typedef uint8_t control_status_t;

/**@}*/

/**
 * This type enumerates the possible outcomes from a control transaction.
 *
 */
enum control_ret_values { /*This looks odd but helps us force byte enum */
    CONTROL_SUCCESS = 0,
    CONTROL_REGISTRATION_FAILED,
    CONTROL_BAD_COMMAND,
    CONTROL_DATA_LENGTH_ERROR,
    CONTROL_OTHER_TRANSPORT_ERROR,
    CONTROL_ERROR
};

/**@}*/

#endif /* CONTROL_SHARED_H_ */
