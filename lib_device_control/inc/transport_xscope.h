// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef TRANSPORT_XSCOPE_H
#define TRANSPORT_XSCOPE_H

#include <xccompat.h>
#include <xscope.h>

#include "control.h"

/** XSCOPE transport client processing function, this passes XSCOPE data to the control interface.
 * \param c_xscope  XSCOPE channel end
 * \param i_control Control interface array
 * 
 */
void xscope_control_client(chanend c_xscope, CLIENT_INTERFACE(control, i_control[CONTROL_INTERFACES_NUM]));

#endif // TRANSPORT_XSCOPE_H
