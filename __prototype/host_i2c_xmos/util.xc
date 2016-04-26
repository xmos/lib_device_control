#include <stdio.h>
#include "util.h"

void print_bytes(const unsigned char data[], int num_bytes)
{
  int i;
  for (i = 0; i < num_bytes; i++) {
    printf("%02x ", data[i]);
  }
  printf("\n");
}

