smb4ios is a basic SMB implementation in native Objective C. It is by no means complete or stable, and no particular effort is made to make it a reusable library. However, it contains enough know-how to provide you with a start for understanding SMB and implementing your own tasks.

Now, a very generic description of SMB and some notes on implementation. I'm going to make it simple, since I myself am sick of pages and pages of indecipherable RFCs and whatnot.

Let's start with TCP. TCP is a low-level network protocol. When you want to send some data to network and other computers, you create a TCP socket, connect it to an address, and jam the data there. The socket takes care of packaging and delivery. 

SMB is a transport protocol, kinda like HTTP. You should know that HTTP is basically when we send some extra information over TCP to describe what kind of content will be exchanged. SMB is the same, but over NetBIOS. 

NetBIOS is basically a really old version of TCP. OSX and iOS do not have an implementation for it. Fortunately, it's simple and can be implemented over TCP. So, this code is SMB over NetBIOS over TCP (aka NBT).

SMB was also called CIFS on some point, they are the same thing. There's also SMB 2, which doesn't work on Windows XP, so is irrelevant to me.

Now, first thing we need is to find the SMB servers in our network. That's done by NetBIOS name queries. Basically it sends an UDP broadcast to a broadcast address (such as 255.255.255.255) and asks "who has this name?". Then someone in the network may answer with his IP. There's a main guy in NetBIOS network with a pre-defined name "master browser", we ask for his IP first. Then we can ask him who else he knows, and that's how we get domains and groups and server IPs.

Now that we have an IP, we can connect a TCP socket to it and run SMB messages. 

First thing the server will want is for us to login under some user. You do the login by sending NTLM packets within SMB Session messages. 

NTLM is when you use extremely complicated cryptography to encode and decode username, password etc. I used a 3rd-party library for that (see link below).

After login, you have basically opened a remote session with a Windows machine, and can run Windows API functions just like you normally would, if you were a Windows C++ application. You do that by sending RPC commands within SMB Transaction messages. 

In short: RPC is a Windows API function code plus parameter buffer, which you wrap in SMB message. You can call functions like EnumAll, OpenPrinter, etc.

More details: Normally, to call a function with certain parameters, you need to push these parameters to stack. Which logically means all the neat C structures and variables you, the human, work with, are packed into a memory buffer and then that buffer is unpacked into the same pattern of structures and stuff inside the function (not what really happens). In RPC, you just provide the function code and the buffer. Which for some people means you should replicate the C structures and then pack them the same way. But in my opinion, nothing stops you from just dumping your data straight into bytes, as long as the end binary result is the same.

And that's how it works: you find IP with NetBIOS, connect via SMB, send NTLM authentication, then run RPC commands. Use Wireshark, it's a huge help, and I would be nowhere without it.

References:

SMB: [MS-SMB] at http://msdn.microsoft.com/en-us/library/cc246231.aspx
RAP: [MS-RAP] at http://msdn.microsoft.com/en-us/library/cc240190.aspx
DCE-RPC: http://pubs.opengroup.org/onlinepubs/9629399/chap12.htm
NetBIOS: RFC 1001 and 1002 (I dare you to actually read it and not go insane), http://www.ubiqx.org/cifs/NetBIOS.html
NTLM: http://www.nongnu.org/libntlm (the library)

This code is provided under "I don't care" license, which means you can use it however you want. Libntlm is GNU LGPL.
