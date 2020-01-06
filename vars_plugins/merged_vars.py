# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)
import os
import pprint
import copy
from ansible import constants as C
from ansible.errors import AnsibleParserError
from ansible.module_utils._text import to_bytes, to_native, to_text
from ansible.plugins.vars import BaseVarsPlugin
from ansible.inventory.host import Host
from ansible.inventory.group import Group
from ansible.utils.vars import combine_vars


pp = pprint.PrettyPrinter()
__metaclass__ = type
FOUND = {}
VARIABLE_NAME = 'merged_vars'
DATA = {'group': {}, 'host': {}, 'roles': None}


class VarsModule(BaseVarsPlugin):

    def get_vars(self, loader, path, entities):
        super(VarsModule, self).get_vars(loader, path, entities)
        for entity in entities:
            self._check_entity(entity)
            self._display.vvv('Incoming entity to merge: %s (%s)' % (entity.get_name(), self._get_entity_type_name(entity)))
        data = {}
        if len(entities) == 1 and isinstance(entities[0], Host):
            entity = entities[0]
            data = self._get_roles_vars(loader)
            data = self._combine_dicts(self._get_entity_variables(entity, loader), data)
            for group in entity.get_groups():
                self._display.vvvv('Host %s in group %s' % (entity.get_name(), group.get_name()))
                data = self._combine_dicts(data, self._get_entity_variables(group, loader))
        else:
            for entity in entities:
                data[entity.get_name()] = self._get_entity_variables(entity, loader)
        # self._display.vvvv('Prepared data: %s' % (data, ))
        self._display.vvvv('Group all data: %s' % (DATA['group']['all'] if 'all' in DATA['group'] else {}, ))
        return {VARIABLE_NAME: data}

    def _check_entity(self, entity):
        if isinstance(entity, (Host, Group)):
            return
        raise AnsibleParserError("Supplied entity must be Host or Group, got %s instead" % (type(entity)))

    def _get_entity_type_name(self, entity):
        if isinstance(entity, Host):
            return 'host'
        return 'group'

    def _get_entity_subdir(self, entity):
        return '%s_vars' % self._get_entity_type_name(entity)

    def _get_roles_vars(self, loader):
        if not DATA['roles']:
            DATA['roles'] = {}
            roles_path = os.path.realpath(os.path.join(self._basedir, 'roles'))
            for roles_entry in os.listdir(roles_path):
                if os.path.isdir(os.path.join(roles_path, roles_entry)):
                    defaults_path = os.path.join(roles_path, roles_entry, 'defaults/main.yaml')
                    if os.path.isfile(defaults_path):
                        self._display.vvvv('Loading role defaults: %s' % defaults_path)
                        role_variables = loader.load_from_file(defaults_path, cache=True, unsafe=True)
                        if role_variables:
                            variables_dict = dict(role_variables)
                            DATA['roles'] = self._combine_dicts(variables_dict, DATA['roles'])
        return copy.deepcopy(DATA['roles'])

    def _find_files(self, entity, loader):
        found_files = []
        opath = os.path.realpath(os.path.join(self._basedir, self._get_entity_subdir(entity)))
        key = '%s.%s' % (entity.name, opath)
        if key in FOUND:
            found_files = FOUND[key]
        else:
            b_opath = to_bytes(opath)
            # no need to do much if path does not exist for basedir
            if os.path.exists(b_opath):
                if os.path.isdir(b_opath):
                    self._display.vvv("\tprocessing dir %s" % opath)
                    found_files = loader.find_vars_files(opath, entity.name)
                    self._display.vvv("\tfound files: %s" % found_files)
                    FOUND[key] = found_files
                else:
                    self._display.warning(
                        "Found %s that is not a directory, skipping: %s" % (subdir, opath))
        return found_files

    def _get_entity_variables(self, entity, loader):
        entity_type_name = self._get_entity_type_name(entity)
        if entity.get_name() not in DATA[entity_type_name]:
            DATA[entity_type_name][entity.get_name()] = {}
            self._display.vvv('Mining variables of %s (%s)' % (entity.get_name(), entity_type_name))
            if not entity.name.startswith(os.path.sep):  # avoid 'chroot' type inventory hostnames /path/to/chroot
                for found in self._find_files(entity, loader):
                    DATA[entity_type_name][entity.get_name()] = self._process_variables(entity, entity_type_name, loader.load_from_file(found, cache=True, unsafe=True))
            self._display.vvvv('Mined data: %s' % (DATA[entity_type_name][entity.get_name()], ))
        return copy.deepcopy(DATA[entity_type_name][entity.get_name()])

    def _process_variables(self, entity, entity_type_name, variables):
        if variables:  # ignore empty files
            variables_dict = dict(variables)
            return self._combine_dicts(variables_dict, DATA[entity_type_name][entity.get_name()])
        return {}

    def _combine_dicts(self, left, right):
        if not left and not right:
            return {}
        if not left:
            return right
        if not right:
            return left
        for key in right:
            if key in left:
                value = right[key]
                # self._display.vvv('\t\td[%s] %s' % (key, type(value)))
                if isinstance(value, dict):
                    left[key] = self._combine_dicts(left[key], right[key])
                elif isinstance(value, list):
                    left[key] = self._combine_lists(left[key], right[key])
                # else: Левый должен побеждать
                #     left[key] = right[key]
            else:
                left[key] = right[key]
        return left

    def _combine_lists(self, left, right):
        for i, value in enumerate(right):
            if value in left:
                # self._display.vvv('\t\tl[%s] %s' % (i, type(value)))
                if isinstance(value, dict):
                    left[i] = self._combine_dicts(left[i], value)
                elif isinstance(value, list):
                    left[i] = self._combine_lists(left[i], value)
                # else: Левый должен побеждать
                #     left[i] = value
            else:
                left.append(value)
        return left
