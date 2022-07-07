import web3 from './web3';
import Contract from './build/Contract.json';

export default new web3.eth.Contract
(
    Contract["abi"],
    '0x26122402774585976eCf76eb80419e94DbE22d12'
);