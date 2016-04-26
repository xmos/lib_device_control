#include <platform.h>
#include <stdio.h>
#include <assert.h>
#include <timer.h>
#include <xscope.h>
#include <stdint.h>

#define PROBE_NAME "Upstream Data"

void xscope_user_init(void)
{
  /* use JTAG for console I/O
   * xSCOPE would be xscope_config_io(XSCOPE_IO_BASIC)
   * see bug 17287
  */

  xscope_register(1, XSCOPE_CONTINUOUS, PROBE_NAME, XSCOPE_INT, "byte");
}

enum {
  COMMAND_GET = 1,
  COMMAND_SET = 2
};

struct command {
  uint8_t direction;
  uint8_t entity;
  uint8_t address[3]; /* big endian convention */
  uint8_t payload_length;
  uint8_t payload[64]; /* USB control request maximum, xSCOPE is probably 256 */
};

unsigned ntoh24(const unsigned char b[3])
{
  return ((unsigned)b[0] << 16) | ((unsigned)b[1] << 8) | (unsigned)b[0];
}

[[combinable]]
void xscope_server(chanend c_xscope, chanend c_app)
{
  unsigned char cb[256];
  struct command *c;
  int num_bytes_read;
  int i;

  xscope_connect_data_from_host(c_xscope);

  printf("xSCOPE server connected\n");

  c = (struct command*)cb;

  while (1) {
    select {
      /* tools_xtrace/xscope_api/xcore_shared/xscope_shared_xc.xc */
      case xscope_data_from_host(c_xscope, cb, num_bytes_read):
        assert(num_bytes_read <= sizeof(struct command));
        c_app <: c->direction;
        master {
          c_app <: ntoh24(c->address);
          c_app <: c->payload_length;
          if (c->direction == COMMAND_SET) {
            for (i = 0; i < c->payload_length; i++) {
              c_app <: c->payload[i];
            }
          }
        }
        if (c->direction == COMMAND_GET) {
          slave {
            for (i = 0; i < c->payload_length; i++) {
              c_app :> c->payload[i];
            }
          }
          xscope_core_bytes(0, c->payload_length, c->payload);
        }
	/* xTAG adapter should defer further calls by NAKing USB transactions */
        break;
    }
  }
}

void app(chanend c_app)
{
  char direction;
  int address;
  char n;
  int i;
  unsigned char payload[8];
  unsigned num_commands;

  printf("started\n");

  num_commands = 0;

  while (1) {
    select {
      case c_app :> direction:
        slave {
          c_app :> address;
          c_app :> n;
          if (direction == COMMAND_SET) {
            assert(n <= sizeof(payload));
            for (i = 0; i < n; i++) {
              c_app :> payload[i];
            }
          }
        }
        if (direction == COMMAND_GET) {
          master {
            assert(n == 4);
            c_app <: (char)0x12;
            c_app <: (char)0x34;
            c_app <: (char)0x56;
            c_app <: (char)0x78;
          }
        }
        printf("%u: received %s: 0x%06x %d,", num_commands, direction == COMMAND_GET ? "GET" : "SET", address, n);
        if (direction == COMMAND_SET) {
          for (i = 0; i < n; i++) {
            printf(" %02x", payload[i]);
          }
        }
        else {
          printf(" returned %d bytes", n);
        }
        printf("\n");
        num_commands++;
        break;
    }
  }
}

int main(void)
{
  chan c_xscope;
  chan c_app;
  par {
    /* xgdb -ex 'conn --xscope-realtime --xscope-port 127.0.0.1:10101' */
    xscope_host_data(c_xscope);
    on tile[0]: xscope_server(c_xscope, c_app);
    on tile[0]: app(c_app);
  }
  return 0;
}
