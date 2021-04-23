// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"

int main(void)
{
  if (control_init() != CONTROL_SUCCESS)
    printf("ERROR on control_init\n");
  else
    printf("Success!\n");

  return 1;
}
