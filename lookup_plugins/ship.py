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
                yaml_data['v6networks'] = list(netaddr.IPNetwork(
                    '{0}/{1}'.format(yaml_data['ipv6']['net'], yaml_data['ipv6']['mask'])).subnet(64))
                return yaml_data
            except yaml.YAMLError as exc:
                print(exc)


prepared_data = None
try:
    prepared_data = ConfigLoader().load()
except Exception as e:
    raise AnsibleError("Error load data: %s " % e)
# print(prepared_data)

display.v("Preparing done")


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        display.v("Ship terms: %s" % terms)
        try:
            if terms[0] == 'ip':
                return [self.ip(int(terms[1]))]
            raise AnsibleParserError("Непонятно что делать")
        except Exception as e:
            raise AnsibleError(
                "Error in ship: %s (%s)" % (terms, e))

    def ip(self, num):
        return {
            'ipv4': self.v4_subnet()[num],
            # 'ipv6': self.v6_subnet()[num]
            'ipv6': prepared_data['v6networks'][num][1]
        }

    def v4_subnet(self):
        return self.main_subnet('ipv4')

    def v6_subnet(self):
        return self.main_subnet('ipv6')

    def main_subnet(self, ip_ver):
        return netaddr.IPNetwork(self._to_net(prepared_data[ip_ver]['net'], prepared_data[ip_ver]['mask']))

    def _to_net(self, addr, net):
        return '{0}/{1}'.format(addr, net)
