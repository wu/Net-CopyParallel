# Net-CopyParallel

Copy one or more files to multiple servers in parallel.  Supports scp
and rsync.

Once a server has successfully received the file(s), that server may
optionally be used as a source server to send to remaining servers.
This allows increasing the copying at an exponential rate, rapidly
pushing files to very large numbers of servers.
