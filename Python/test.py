# Web3撸毛脚本 🧵 演示代码

from web3 import Web3
# get w3 endpoint by network name
def get_w3_by_network(network='mainnet'):
    infura_url = f'https://mainnet.infura.io/v3/2f03af4a4b8c47c4af6cdf23a85f4890' # 接入 Infura
    w3 = Web3(Web3.HTTPProvider(infura_url))
    return w3

w3.eth.get_block('latest')

