#include <stdio.h>
#include <windows.h>
#include "SetupAPI.h"
#include "winusb.h"

int init(void)
{
  // https://msdn.microsoft.com/en-us/library/windows/hardware/ff540196(v=vs.85).aspx
  // https://msdn.microsoft.com/en-us/library/windows/hardware/dn376872(v=vs.85).aspx
  // Visual Studio Community 2015 with Windows Driver Kit (2GB)

  HDEVINFO devinfo;
  GUID guid = { // A7A10F0B-9AF1-45A6-9284-6C7243A229B0
    0xA7A10F0B, 0x9AF1, 0x45A6,
    {0x92, 0x84, 0x6C, 0x72, 0x43, 0xA2, 0x29, 0xB0}
  };
  SP_DEVICE_INTERFACE_DATA interface_data;
  HRESULT hresult;
  BOOL ret;

  printf("SetupDiGetClassDevs\n");
  devinfo = SetupDiGetClassDevs(&guid, NULL, NULL,
                                DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
  printf("SetupDiGetClassDevs: 0x%p\n", devinfo);

  if (devinfo == INVALID_HANDLE_VALUE) {
    hresult = HRESULT_FROM_WIN32(GetLastError());
    (void)hresult;
    return 1;
  }

  printf("SetupDiEnumDeviceInterfaces\n");
  ret = SetupDiEnumDeviceInterfaces(devinfo, NULL, &guid, 0, &interface_data);
  printf("SetupDiEnumDeviceInterfaces: %d\n", ret);

  if (ret == FALSE) {
    hresult = HRESULT_FROM_WIN32(GetLastError());
    (void)hresult;
    SetupDiDestroyDeviceInfoList(devinfo);
    return 2;
  }

  // ...

  return 0;
}

int main(void)
{
  init();
  return 0;
}
