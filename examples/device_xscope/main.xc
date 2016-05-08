#include <platform.h>
#include <stdio.h>
#include <assert.h>
#include <timer.h>
#include <xscope.h>
#include <stdint.h>
#include "control.h"
#include "app.h"

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
void xscope_client(chanend c_xscope, client interface control i_control[1])
{
  uint8_t bytes[256];
  int num_bytes_read;
  unsigned return_size;

  xscope_connect_data_from_host(c_xscope);

  printf("xSCOPE server connected\n");

  while (1) {
    select {
      /* tools_xtrace/xscope_api/xcore_shared/xscope_shared_xc.xc */
      case xscope_data_from_host(c_xscope, bytes, num_bytes_read):
        assert(num_bytes_read <= sizeof(bytes));
	control_process_xscope_upload(bytes, num_bytes_read, return_size, i_control, 1);
	if (return_size > 0) {
          xscope_core_bytes(0, return_size, bytes);
        }
	/* xTAG adapter should defer further calls by NAKing USB transactions */
        break;
    }
  }
}

int main(void)
{
  chan c_xscope;
  interface control i_control[1];
  par {
    /* xgdb -ex 'conn --xscope-realtime --xscope-port 127.0.0.1:10101' */
    xscope_host_data(c_xscope);
    on tile[0]: xscope_client(c_xscope, i_control);
    on tile[0]: app(i_control[0]);
  }
  return 0;
}
