// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef TRANSPORT_I2C_H
#define TRANSPORT_I2C_H

#include <xccompat.h>

#include "control.h"
#include "i2c.h"

/** I2C transport client processing function, this passes I2C data to the control interface.
 * \param i_i2c     I2C slave callback interface
 * \param i_control Control interface array
 * 
 */
void i2c_control_client(SERVER_INTERFACE(i2c_slave_callback_if, i_i2c), CLIENT_INTERFACE(control, i_control[]));

#endif // TRANSPORT_I2C_H
