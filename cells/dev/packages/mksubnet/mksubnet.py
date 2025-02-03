# mksubnet fd12:ed4e:366d::/48 108
import sys
import ipaddress
import random


def mk_subnet(old_net, new_prefix: int):
    old_bits = int.from_bytes(old_net.network_address.packed)
    remaining_prefix = old_net.max_prefixlen - new_prefix
    new_bits = random.getrandbits(new_prefix - old_net.prefixlen) << remaining_prefix
    return ipaddress.ip_network(old_bits + new_bits).supernet(new_prefix=new_prefix)


print(mk_subnet(ipaddress.ip_network(sys.argv[1]), int(sys.argv[2].lstrip("/"))))
