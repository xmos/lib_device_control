#include <platform.h>
#include <stdio.h>
#include <assert.h>
#include <timer.h>
#include <xscope.h>
#include <stdint.h>
#include "control.h"

#define PROBE_NAME "Upstream Data"

void xscope_user_init(void)
{
  /* use JTAG for console I/O
   * xSCOPE would be xscope_config_io(XSCOPE_IO_BASIC)
   * see bug 17287
  */

  xscope_register(1, XSCOPE_CONTINUOUS, PROBE_NAME, XSCOPE_INT, "byte");
}

[[combinable]]
void xscope_server(chanend c_xscope, client interface control i_module[1])
{
  uint8_t bytes[256];
  int num_bytes_read;
  size_t return_size;

  xscope_connect_data_from_host(c_xscope);

  printf("xSCOPE server connected\n");

  while (1) {
    select {
      /* tools_xtrace/xscope_api/xcore_shared/xscope_shared_xc.xc */
      case xscope_data_from_host(c_xscope, bytes, num_bytes_read):
        assert(num_bytes_read <= sizeof(bytes));
	control_handle_message_xscope(bytes, return_size, i_module, 1);
	if (return_size > 0) {
          xscope_core_bytes(0, return_size, bytes);
        }
	/* xTAG adapter should defer further calls by NAKing USB transactions */
        break;
    }
  }
}

void app(server interface control i_module)
{
  unsigned num_commands;
  int i;

  printf("started\n");

  num_commands = 0;

  while (1) {
    select {
      case i_module.set(int address, size_t payload_length, const uint8_t payload[]):
        printf("%u: received SET: 0x%06x %d,", num_commands, address, payload_length);
        for (i = 0; i < payload_length; i++) {
          printf(" %02x", payload[i]);
        }
        printf("\n");
        num_commands++;
        break;

      case i_module.get(int address, size_t payload_length, uint8_t payload[]):
        assert(payload_length == 4);
        payload[0] = 0x12;
        payload[1] = 0x34;
        payload[2] = 0x56;
        payload[3] = 0x78;
        printf("%u: received GET: 0x%06x %d,", num_commands, address, payload_length);
        printf(" returned %d bytes", payload_length);
        printf("\n");
        num_commands++;
        break;
    }
  }
}

int main(void)
{
  chan c_xscope;
  interface control i_module[1];
  par {
    /* xgdb -ex 'conn --xscope-realtime --xscope-port 127.0.0.1:10101' */
    xscope_host_data(c_xscope);
    on tile[0]: xscope_server(c_xscope, i_module);
    on tile[0]: app(i_module[0]);
  }
  return 0;
}
