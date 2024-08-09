// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <platform.h>
#include <stdio.h>
#include <syscall.h>
#include <timer.h>
#include "i2c.h"
#include "control.h"
#include "mic_array_board_support.h"
#include "app.h"

on tile[0]: port p_scl = PORT_I2C_SCL;
on tile[0]: port p_sda = PORT_I2C_SDA;
//on tile[1]: out port p_eth_phy_reset = XS1_PORT_4F; /* X1D29, bit 1 of port 4F */

//on tile[0]: mabs_led_ports_t p_leds = on tile[0]: MIC_BOARD_SUPPORT_LED_PORTS;
//on tile[0]: in port p_buttons = MIC_BOARD_SUPPORT_BUTTON_PORTS;

const char i2c_device_addr = 0x2C;

[[combinable]]
void i2c_client(server i2c_slave_callback_if i_i2c, client interface control i_control[1])
{
  while (1) {
    select {
      case i_i2c.ack_write_request(void) -> i2c_slave_ack_t resp:
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
        if (control_process_i2c_write_start(i_control) == CONTROL_SUCCESS)
#pragma warning enable
          resp = I2C_SLAVE_ACK;
        else
          resp = I2C_SLAVE_NACK;
        break;

      case i_i2c.ack_read_request(void) -> i2c_slave_ack_t resp:
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
        if (control_process_i2c_read_start(i_control) == CONTROL_SUCCESS)
#pragma warning enable
          resp = I2C_SLAVE_ACK;
        else
          resp = I2C_SLAVE_NACK;
        break;

      case i_i2c.master_sent_data(uint8_t data) -> i2c_slave_ack_t resp:
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
        if (control_process_i2c_write_data(data, i_control) == CONTROL_SUCCESS)
#pragma warning enable

          resp = I2C_SLAVE_ACK;
        else {
          resp = I2C_SLAVE_NACK;
        }
        break;

      case i_i2c.master_requires_data(void) -> uint8_t data:
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
        control_process_i2c_read_data(data, i_control);
#pragma warning enable
        break;

      case i_i2c.stop_bit(void):
#pragma warning disable unusual-code // Suppress slice interface warning (no array size passed)
        control_process_i2c_stop(i_control);
#pragma warning enable
        break;
    }
  }
}

int main(void)
{
  i2c_slave_callback_if i_i2c;
  interface control i_control[1];
  //interface mabs_led_button_if i_leds_buttons[1];

  par {
    on tile[1]: par {
      app(i_control[0]/*, i_leds_buttons[0]*/);
      //mabs_button_and_led_server(i_leds_buttons, 1, p_leds, p_buttons);
      }
    on tile[0]: {
      /* hold Ethernet PHY in reset to ensure it is not driving clock */
      //p_eth_phy_reset <: 0;
      control_init();
      control_register_resources(i_control, 1);

      /* bug 17317 - [[combine]] */
      par {
        i2c_client(i_i2c, i_control);
        i2c_slave(i_i2c, p_scl, p_sda, i2c_device_addr);
      }
    }
  }
  return 0;
}
