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
                'negative': re.compile(rule['match']['negative']) if 'negative' in rule['match'] and rule['match']['negative'] else None
            }
            rules.append(rule)
        return rules

    def match(self, text):
        for rule in self._rules:
            if ((rule['pattern']['negative'] and not rule['pattern']['negative'].match(text)) or not rule['pattern']['negative']):
                match_result = rule['pattern']['positive'].match(text)
                if match_result:
                    data = match_result.groupdict()
                    data['rule_name'] = rule['name']
                    return {
                        'rule': rule,
                        'data': data
                    }
        return None
