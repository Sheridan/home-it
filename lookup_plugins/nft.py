# -*- coding: utf-8 -*-
from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase
# import netaddr


try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        display.v("Netfilter terms: %s" % terms)
        try:
            if terms[0] == 'as_iif':  # 1 == interface
                return self.as_if('i', terms[1])
            if terms[0] == 'as_oif':  # 1 == interface
                return self.as_if('o', terms[1])
            if terms[0] == 'list_or_single':  # 1 == list
                return self.as_list_or_single(terms[1])
            if terms[0] == 'ip_or_ip6':  # 1 == ipv4,ipv6
                return self.as_ip_or_ip6(terms[1])
            raise AnsibleParserError("Непонятно что делать")
        except Exception as e:
            raise AnsibleError("Error in nft: %s (%s)" % (terms, e))

    def as_if(self, direction, interface):
        return '{0}if {1}'.format(direction, interface['ifname']) if interface['type'] in ['static', 'virtual'] else '{0}ifname "{1}"'.format(direction, interface['ifname'])

    def as_list_or_single(self, items):
        if isinstance(items, list):
            if len(items) > 1:
                return '{ %s }' % ', '.join(str(x) for x in items)
            return items[0]
        return items

    def as_ip_or_ip6(self, ip_version):
        return 'ip' if ip_version == 'ipv4' else 'ip6'
