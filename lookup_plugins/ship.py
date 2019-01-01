#!/usr/bin/python
from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase
import netaddr
import yaml


try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

display.v("Preparing ip data...")


class ConfigLoader:
    def load(self):
        with open("vars/network.yaml", 'r') as stream:
            try:
                yaml_data = yaml.load(stream)['raw_home_networks']
                return yaml_data
            except yaml.YAMLError as exc:
                print(exc)

class ClassIP:
    def __init__(self, ipv4, ipv6):
        self.ipv4 = ipv4
        self.ipv6 = ipv6
    def ipv4(self):
        return self.ipv4

prepared_data = None
try:
    prepared_data = ConfigLoader().load()
except Exception as e:
    raise AnsibleError("Error load data: %s " % e)
# print(prepared_data['home']['ipv6'])

display.v("Preparing done")


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        display.v("Ship terms: %s" % terms)
        try:
            if terms[0] == 'ip':  # 1 == номер
                return self._return(self.ip(int(terms[1])))
            if terms[0] == 'net':  # 1 == версия ip
                return self._return(self.net(terms[1]))
            if terms[0] == 'kis_ip':  # 1 == номер
                return self._return(self.prov_ip('ipv4', 'kis', int(terms[1])))
            if terms[0] == 'kis_net':
                return self._return(self.prov_net('ipv4', 'kis'))
            if terms[0] == 'henet_ip':  # 1 == номер
                return self._return(self.prov_ip('ipv6', 'henet', int(terms[1])))
            if terms[0] == 'henet_net':
                return self._return(self.prov_net('ipv6', 'henet'))
            if terms[0] == 'delegated_v6_net':
                return self._return(self._format_net(self._delegated_net()))
            raise AnsibleParserError("Непонятно что делать")
        except Exception as e:
            raise AnsibleError("Error in ship: %s (%s)" % (terms, e))

    def ip(self, num):
        return {
            'ipv4': self._format_ip(self.v4_subnet(), num),
            'ipv6': self._format_ip(self.v6_subnet(), num)
        }

    def net(self, ip_ver):
        if ip_ver == 'ipv4':
            return self._format_net(self.v4_subnet())
        return self._format_net(self.v6_subnet())

    def prov_net(self, ip_ver, name):
        return self._format_net(self._prov_net(ip_ver, name))

    def prov_ip(self, ip_ver, name, num):
        return self._format_ip(self._prov_net(ip_ver, name), num)

    def v4_subnet(self):
        return self.main_subnet('ipv4')

    def v6_subnet(self):
        return self.main_subnet('ipv6')

    def main_subnet(self, ip_ver):
        return netaddr.IPNetwork(self._to_net(prepared_data['home'][ip_ver]['net'],
                                              prepared_data['home'][ip_ver]['mask']))

    def _prov_net(self, ip_ver, name):
        return netaddr.IPNetwork(self._to_net(prepared_data[name][ip_ver]['net'],
                                              prepared_data[name][ip_ver]['mask']))

    def _delegated_net(self):
        return netaddr.IPNetwork(self._to_net(prepared_data['home']['ipv6']['delegated_net'],
                                              prepared_data['home']['ipv6']['delegated_mask']))

    def _to_net(self, addr, net):
        return '{0}/{1}'.format(addr, net)

    def _return(self, what):
        return what

    def _format_ip(self, network, num):
        ip = network[num]
        return {
            'ip': ip.format(),
            'prefixed': '{0}/{1}'.format(ip.format(), network.prefixlen),
            'network': self._format_net(network),
            'reverse': ip.reverse_dns
        }

    def _format_net(self, network):
        return {
            'net': network.ip.format(),
            'mask': {
                'long': network.netmask.format(),
                'short': network.prefixlen,
                'host': network.hostmask.format()
            },
            'size': network.size,
            'broadcast': network.broadcast.format() if network.broadcast else '',
            'full': '{0}/{1}'.format(network.ip.format(), network.prefixlen),
            'reverse': network[0].reverse_dns
        }
