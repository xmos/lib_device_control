// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef CONTROL_SHARED_H
#define CONTROL_SHARED_H

#include <stdint.h>
#include <stddef.h>

/**
 * \defgroup control_shared_group control_shared
 *
 * The shared API for using the device control library on the device and host
 * @{
 */

/**
 * This is the version of control protocol. Used to check compatibility
 */
#define CONTROL_VERSION 0x10

/** Type used to identify a resource */
typedef uint8_t control_resid_t;
/** Type used to identify a command */
typedef uint8_t control_cmd_t;
/** Type used to identify a version */
typedef uint8_t control_version_t;
/** Type used to identify a return value */
typedef uint8_t control_ret_t;
/** Type used to identify a status */
typedef uint8_t control_status_t;

/**
 * This type enumerates the possible outcomes from a control transaction.
 */
enum control_ret_values { /*This looks odd but helps us force byte enum */
    CONTROL_SUCCESS = 0,
    CONTROL_REGISTRATION_FAILED,
    CONTROL_BAD_COMMAND,
    CONTROL_DATA_LENGTH_ERROR,
    CONTROL_OTHER_TRANSPORT_ERROR,
    CONTROL_ERROR
};

/** Expected USB Vendor request value on the control interface */
#ifndef CONTROL_VENDOR_REQUEST
#define CONTROL_VENDOR_REQUEST (0)
#endif

/** end doxygen group
 * @}
 */

/** UNUSED_RES() marks resources as unused, where (void) would be used for integer types. It works for resource: ports, interfaces, clocks, channels/chanends  */
#ifndef UNUSED_RES
#ifdef __XC__
#define UNUSED_RES(x) do { unsafe { (void)(unsigned)(x); }  } while(0);
#else
#define UNUSED_RES(x) (void)(x)
#endif
#endif // UNUSED_RES

#endif // CONTROL_SHARED_H
