#import "DceRpcBind.h"
#import "DceRpcEnumAll.h"
#import "DceRpcOpenPrinterEx.h"
#import "DceRpcGetPrinter.h"
#import "DceRpcStartDocPrinter.h"
#import "DceRpcWritePrinter.h"
#import "DceRpcEndDocPrinter.h"
#import "DceRpcClosePrinter.h"
#import "DceRpcPrinterInfo2.h"

#define SPOOLSS_PATH   @"\\spoolss"
#define SPOOLSS_SYNTAX @"12345678-1234-abcd-ef00-0123456789ab:1.0"

#define SRVSVC_PATH    @"\\srvsvc"
#define SRVSVC_SYNTAX  @"4b324fc8-1670-01d3-1278-5a47bf6ee188:3.0"

#define STYPE_DISKTREE 0x00000000
#define STYPE_PRINTQ   0x00000001
#define STYPE_DEVICE   0x00000002
#define STYPE_IPC      0x00000003
