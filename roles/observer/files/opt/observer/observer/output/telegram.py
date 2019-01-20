import requests
from observer.output.base import OutputPlugin


class OutputTelegram(OutputPlugin):
    def __init__(self, options, proxy, debug):
        super(OutputTelegram, self).__init__(options, debug, 'telegram')
        self._token = options['token']
        self._proxies = {}
        if proxy['enabled']:
            if 'user' in proxy:
                self._proxies = {
                    proxy['type']: 'socks5://{0}:{1}@{2}:{3}'.format(
                        proxy['user'],
                        proxy['pass'],
                        proxy['host'],
                        proxy['port'])
                    }
            else:
                self._proxies = {
                    proxy['type']: 'socks5://{0}:{1}'.format(
                        proxy['host'],
                        proxy['port'])
                        }

    def _botq(self, method, params=None):
        url = 'https://api.telegram.org/bot{0}/{1}'.format(self._token, method)
        try:
            if self._debug:
                print('Sending', params)
            r = requests.post(url, data=params, proxies=self._proxies)
            if r.status_code == 200:
                if self._debug:
                    print('Api return:', r.json())
            else:
                print('API returned status {0}: {1}'.format(r.status_code, r.content()))
        except Exception as e:
            print('Exception {0}'.format(e))

    def send_message(self, msg, target_name):
        for target in self._options['targets']:
            if target['name'] == target_name:
                for room in target['destination']['rooms']:
                    self._botq('sendMessage', {
                                'chat_id': room,
                                'text': msg,
                                'disable_web_page_preview': True,
                                'parse_mode': 'HTML'})
                return
