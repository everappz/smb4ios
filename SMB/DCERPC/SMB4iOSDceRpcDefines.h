#import <Foundation/Foundation.h>

#define PFC_FIRST_FRAG           0x01 // First fragment
#define PFC_LAST_FRAG            0x02 // Last fragment
#define PFC_PENDING_CANCEL       0x04 // Cancel was pending at sender
#define PFC_RESERVED_1           0x08  
#define PFC_CONC_MPX             0x10 // Concurrent multiplexing
#define PFC_DID_NOT_EXECUTE      0x20 // On "fault" packet: guaranteed call did not execute
#define PFC_MAYBE                0x40 // "Maybe" call semantics requested
#define PFC_OBJECT_UUID          0x80 // Non-nil object UUID was specified in the handle

#define PTYPE_REQUEST  0
#define PTYPE_RESPONSE 2
#define PTYPE_FAULT    3
#define PTYPE_BIND    11

#define RPC_GETPRINTER       8
#define RPC_ENUMALL         15
#define RPC_STARTDOCPRINTER 17
#define RPC_WRITEPRINTER    19
#define RPC_ENDDOCPRINTER   23
#define RPC_CLOSEPRINTER    29
#define RPC_OPENPRINTEREX   69

#define RPC_NET_SERVER_ENUM2 0x68

#define MAX_XMIT 4280