// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/** MSOS 2.0 Descriptors for vendor Endpoint 0 handling
*/

#include "ep0_msos_descriptors.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "msos_descriptors.h"
#include "xud_device.h"

USB_Descriptor_BOS_t desc_bos =
{
    .usb_desc_bos_standard = {
        .bLength = sizeof(USB_Descriptor_BOS_standard_t),
        .bDescriptorType = USB_DESCTYPE_BOS,
        .wTotalLength = sizeof(USB_Descriptor_BOS_standard_t) + sizeof(USB_Descriptor_BOS_platform_t),
        .bNumDeviceCaps = 1
    },
    .usb_desc_bos_platform = {
        .bLength = sizeof(USB_Descriptor_BOS_platform_t),
        .bDescriptorType = USB_DESCTYPE_DEVICE_CAPABILITY,
        .bDevCapabilityType = DEVICE_CAPABILITY_PLATFORM,
        .bReserved = 0,
        .PlatformCapabilityUUID = {USB_BOS_MS_OS_20_UUID},
        .CapabilityData = {U32_TO_U8S_LE(0x06030000), U16_TO_U8S_LE(sizeof(MSOS_desc_simple_t)), REQUEST_GET_MS_DESCRIPTOR, 0}
    }
};

MSOS_desc_simple_t desc_ms_os_20_simple =
{
    .msos_desc_header =
    {
        .wLength = sizeof(MSOS_desc_header_t),
        .wDescriptorType = MS_OS_20_SET_HEADER_DESCRIPTOR,
        .dwWindowsVersion = 0x06030000,
        .wTotalLength = sizeof(MSOS_desc_simple_t)
    },
    .msos_desc_compat_id =
    {
        .wLength = sizeof(MSOS_desc_compat_id_t),
        .wDescriptorType = MS_OS_20_FEATURE_COMPATIBLE_ID,
        .CompatibleID = {'W', 'I', 'N', 'U', 'S', 'B', 0x00, 0x00},
        .SubCompatibleID = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    },
    .msos_desc_registry_property =
    {
        .wLength = sizeof(MSOS_desc_registry_property_t),
        .wDescriptorType = MS_OS_20_FEATURE_REG_PROPERTY,
        .wPropertyDataType = 0x0007,
        .wPropertyNameLength = MSOS_PROPERTY_NAME_LEN,
        .PropertyName = {'D', 0x00, 'e', 0x00, 'v', 0x00, 'i', 0x00, 'c', 0x00, 'e', 0x00, 'I', 0x00, 'n', 0x00, 't', 0x00, 'e', 0x00,
                          'r', 0x00, 'f', 0x00, 'a', 0x00, 'c', 0x00, 'e', 0x00, 'G', 0x00, 'U', 0x00, 'I', 0x00, 'D', 0x00, 's', 0x00, 0x00, 0x00}, //"DeviceInterfaceGUIDs\0" in UTF-16
        .wPropertyDataLength = MSOS_INTERFACE_GUID_LEN,
        .PropertyData = {
                          '{', 0x00, 'a', 0x00, '0', 0x00, '0', 0x00, '8', 0x00, '3', 0x00, '8', 0x00, '2', 0x00, 'b', 0x00, '-', 0x00,
                          '5', 0x00, 'a', 0x00, 'd', 0x00, 'c', 0x00, '-', 0x00, '4', 0x00, '6', 0x00, '4', 0x00, 'f', 0x00, '-', 0x00,
                          'a', 0x00, '8', 0x00, '4', 0x00, '9', 0x00, '-', 0x00, '1', 0x00, '7', 0x00, '5', 0x00, '0', 0x00, '0', 0x00,
                          'f', 0x00, '0', 0x00, '9', 0x00, '0', 0x00, '7', 0x00, '4', 0x00, 'c', 0x00, '}', 0x00, 0x00, 0x00, 0x00, 0x00
                        }, //generated from https://guidgenerator.com/ and stored as Unicode
    }
};

XUD_Result_t Msos_Get_Bos_Descriptor(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp)
{
    XUD_Result_t result = XUD_RES_ERR;

    if ((sp->wValue & 0xff00) == (USB_DESCTYPE_BOS << 8)) {
        result = XUD_DoGetRequest(ep0_out, ep0_in, (unsigned char*)&desc_bos, sizeof(desc_bos), sp->wLength);
    }
    // printf("Bos: rqst: %d, idx: %d, val: %d, r: %d\n", sp->bRequest, sp->wIndex, sp->wValue, result);
    return result;
}

XUD_Result_t Msos_Get_Msos_Descriptor(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp)
{
    XUD_Result_t result = XUD_RES_ERR;

    if(sp->wIndex == MS_OS_20_DESCRIPTOR_INDEX) {
        result = XUD_DoGetRequest(ep0_out, ep0_in, (unsigned char*)&desc_ms_os_20_simple, sizeof(MSOS_desc_simple_t), sp->wLength);
    }
    // printf("Msos: rqst: %d, idx: %d, val: %d, r: %d\n", sp->bRequest, sp->wIndex, sp->wValue, result);

    return result;
}
