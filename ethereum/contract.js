import web3 from './web3';
import Contract from './build/Contract.json';

export default new web3.eth.Contract
(
    Contract["abi"],
    '0xD3711852A1A59869D665791bcAaEC7143ab45f9c'
);