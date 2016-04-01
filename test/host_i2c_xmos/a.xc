#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include <syscall.h>
#include <assert.h>
#include <timer.h>
#include "i2c.h"
#include "command.h"
#include "util.h"

port p_scl = on tile[0]: XS1_PORT_1E; /* XE232 board J5 pin 13 */
port p_sda = on tile[0]: XS1_PORT_1F; /* J5 pin 14 */

unsigned num_commands = 0;

const char device_addr = 123;

void do_set_command(client i2c_master_if i_i2c)
{
  struct command c;
  unsigned char *cb;
  unsigned char payload[1];
  int len;
  size_t num_bytes_sent;
  i2c_res_t res;

  /* make a SET command for mic gain
   * use entity number to refer to Illusonic library as "client 0"
   * use property number to select INIT module, 0x4100
   * and mic gain parameter, 0x49 (ASCII 'I') --> 0x494100
   * send 8bit value of 1 as data
   */
  cb = (void*)&c;
  payload[0] = 1;
  len = make_command(c, COMMAND_SET, 0, 0x494100, 1, payload);

  printf("%u: send SET command: ", num_commands);
  print_bytes(cb, len);

  res = i_i2c.write(device_addr, cb, len, num_bytes_sent, 1);

  if (res != I2C_ACK)
    printf("slave sent NAK (write transfer)\n");

  if (num_bytes_sent != len)
    printf("write transfer bytes expected %d actual %d\n", len, num_bytes_sent);

  num_commands++;
}

void do_get_command(client i2c_master_if i_i2c)
{
  struct command c;
  unsigned char *cb;
  int len;
  size_t num_bytes_sent;
  i2c_res_t res;

  /* make a GET command for diagnostics
   * use entity number to refer to Illusonic library as "client 0"
   * use address to select DIAG module, 0x4C00
   * and diagnostics parameter, 0x45 (ASCII 'E') --> 0x454C00
   * request 4 bytes back
   */
  cb = (void*)&c;
  len = make_command(c, COMMAND_GET, 0, 0x454C00, 4, NULL);

  printf("%d: send GET command: ", num_commands);
  print_bytes(cb, len);

  res = i_i2c.write(device_addr, cb, len, num_bytes_sent, 1);

  if (res != I2C_ACK)
    printf("slave sent NAK (write transfer)\n");

  if (num_bytes_sent != len)
    printf("write transfer bytes expected %d actual %d\n", len, num_bytes_sent);

  res = i_i2c.read(device_addr, c.payload, c.payload_length, 1);

  if (res != I2C_ACK)
    printf("slave sent NAK (read transfer)\n");

  printf("GET data returned: ");
  print_bytes(c.payload, c.payload_length);

  num_commands++;
}

void app(client interface i2c_master_if i_i2c)
{
  int i;

  printf("started\n");
  printf("device address %d\n", device_addr);

  while (1) {
    for (i = 0; i < 4; i++) {
      do_set_command(i_i2c);
      delay_milliseconds(100);
      do_get_command(i_i2c);
      delay_seconds(1);
    }
  }
}

int main(void)
{
  i2c_master_if i_i2c[1];
  par {
    on tile[0]: i2c_master(i_i2c, 1, p_scl, p_sda, 200);
    on tile[1]: app(i_i2c[0]);
  }
  return 0;
}
