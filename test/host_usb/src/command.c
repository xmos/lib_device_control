#include <memory.h>
#include <stddef.h>
#include <assert.h>
#include "command.h"

int make_command(struct command *c, uint8_t direction, uint8_t entity,
  unsigned address_24b, uint8_t payload_length, const uint8_t payload[])
{
  c->direction = direction;
  c->entity = entity;
  c->address[0] = (address_24b >> 16) & 0xFF;
  c->address[1] = (address_24b >> 8) & 0xFF;
  c->address[2] = address_24b & 0xFF;
  c->payload_length = payload_length;
  if (payload != NULL) {
    memcpy(c->payload, payload, payload_length);
    return offsetof(struct command, payload) + payload_length;
  }
  else {
    return offsetof(struct command, payload);
  }
}
