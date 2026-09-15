#import <Foundation/Foundation.h>

#define SMB_COM_NEGOTIATE              0x72
#define SMB_COM_SESSION_SETUP_ANDX     0x73
#define SMB_COM_LOGOFF_ANDX            0x74
#define SMB_COM_TREE_DISCONNECT        0x71
#define SMB_COM_TREE_CONNECT_ANDX      0x75
#define SMB_COM_TRANSACTION            0x25
#define SMB_COM_TRANSACTION2           0x32
#define SMB_COM_TRANSACTION2_SECONDARY 0x33
#define SMB_COM_NT_CREATE_ANDX         0xA2
#define SMB_COM_OPEN_ANDX              0x2D
#define SMB_COM_CLOSE                  0x04
#define SMB_COM_READ_ANDX              0x2E
#define SMB_COM_WRITE_ANDX             0x2F
#define SMB_COM_ECHO                   0x2B
#define SMB_COM_NONE                   0xFF

#define SMB_HEADER_PROTOCOL_INT  0
#define SMB_HEADER_COMMAND_BYTE	 4
#define SMB_HEADER_STATUS_INT    5
#define SMB_HEADER_FLAGS_BYTE    9
#define SMB_HEADER_FLAGS2_SHORT  10
#define SMB_HEADER_EXTRA_12BYTE  12
#define SMB_HEADER_TID_SHORT     24
#define SMB_HEADER_PID_SHORT     26
#define SMB_HEADER_UID_SHORT     28
#define SMB_HEADER_MID_SHORT     30
#define SMB_HEADER_LENGTH        32

#define CAP_EXTENDED_SECURITY     0x80000000
#define CAP_COMPRESSED_DATA       0x40000000
#define CAP_BULK_TRANSFER         0x20000000
#define CAP_UNIX                  0x00800000
#define CAP_LARGE_WRITEX          0x00008000
#define CAP_LARGE_READX           0x00004000
#define CAP_INFOLEVEL_PASSTHROUGH	0x00002000
#define CAP_DFS                   0x00001000
#define CAP_NT_FIND               0x00000200
#define CAP_LOCK_AND_READ         0x00000100
#define CAP_LEVEL_II_OPLOCKS      0x00000080
#define CAP_STATUS32              0x00000040
#define CAP_RPC_REMOTE_APIS       0x00000020
#define CAP_NT_SMBS               0x00000010
#define CAP_LARGE_FILES           0x00000008
#define CAP_UNICODE               0x00000004
#define CAP_MPX_MODE              0x00000002
#define CAP_RAW_MODE              0x00000001

#define NT_STATUS_SUCCESS	0x00
#define NT_STATUS_INFORMATION 0x01
#define NT_STATUS_WARNING 0x02
#define NT_STATUS_ERROR	0x03

#define NT_STATUS_BAD_NETWORK_NAME       (0xC0000000 | 0x00cc)
#define NT_STATUS_ACCESS_DENIED          (0xC0000000 | 0x0022)
#define NT_STATUS_INVALID_PARAMETER      (0xC0000000 | 0x000d)
#define NT_STATUS_LOGON_FAILURE          (0xC0000000 | 0x006d)
#define NT_STATUS_LOGON_TYPE_NOT_GRANTED (0xC0000000 | 0x015b)
#define NT_STATUS_BUFFER_OVERFLOW        (0x80000000 | 0x0005)
