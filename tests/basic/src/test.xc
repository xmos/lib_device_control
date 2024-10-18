// Copyright 2016-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"

int main(void)
{
  control_ret_t ret = control_init();
  if (ret != CONTROL_SUCCESS) {
    printf("ERROR on control_init: returned %d, expected %d\n", ret, CONTROL_SUCCESS);
    exit(1);
  }
  else
    printf("Success!\n");
  return 0;
}
