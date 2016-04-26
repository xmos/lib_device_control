#include <stdint.h>
#include <xccompat.h>

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

int make_command(REFERENCE_PARAM(struct command, c), uint8_t direction, uint8_t entity,
  unsigned address_24b, uint8_t payload_length, NULLABLE_ARRAY_OF(uint8_t, payload));
