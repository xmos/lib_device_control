#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "app.h"

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

