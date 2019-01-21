from observer import ObserverPlugin
import re


class InputPlugin(ObserverPlugin):
    def __init__(self, options, debug, plugin_name):
        super(InputPlugin, self).__init__(options, debug, plugin_name)
        self._rules = self.prepare_rules()

    def prepare_rules(self):
        rules = []
        for rule in self._options['rules']:
            rule['pattern'] = {
                'positive': re.compile(rule['match']['positive']),
                'negative': re.compile(rule['match']['negative']) if 'negative' in rule['match'] and isinstance(rule['match']['negative'], str) and rule['match']['negative'] != '' else None
            }
            rules.append(rule)
        return rules

    def match_negative(self, rule, text):
        return rule['pattern']['negative'] and rule['pattern']['negative'].search(text)

    def match(self, text):
        if self._debug:
            print('Match text --------------------=> ', text)
        for rule in self._rules:
            if self._debug:
                print('Rule --------------------=> positive: [{0}]:[{1}], negative: [{2}]:[{3}]'.format(rule['pattern']['positive'], rule['pattern']['positive'].match(text), rule['pattern']['negative'], self.match_negative(rule, text)))
            if not self.match_negative(rule, text):
                match_result = rule['pattern']['positive'].match(text)
                if match_result:
                    data = match_result.groupdict()
                    data['rule_name'] = rule['name']
                    return {
                        'rule': rule,
                        'data': data
                    }
        return None
