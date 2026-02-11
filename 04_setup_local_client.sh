#!/usr/bin/env bash
USER=your_user
CONTROL_PLANE=your_server 

scp $USER@$CONTROL_PLANE:/etc/kubernetes/admin.conf ~/.kube/config # (then chmod 600 ~/.kube/config).
# probably change this to use the one from USERS home directory instead of root's home directory, and then change the ownership of the file to the user. This is just a quick and dirty way to get kubectl working on the local machine, but it should work for testing purposes. For a more secure setup, you would want to set up proper authentication and authorization for your cluster.

# I wonder if I should change file to use server name instead of IP address, and then add an entry to /etc/hosts for the server name.