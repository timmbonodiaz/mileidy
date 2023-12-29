const CONTRACT = "0xB381567590EA051380E32CA618e5eb8A4A3cC983";
const RPC_URL = "https://eth.llamarpc.com";

const ABI = [
    "function MINT_PRICE() public view returns (uint256)",
    "function mint(address,uint8) public payable",
    "function mintlady(address) public payable",
    "function totalSupply() public view returns (uint256)"
]

let provider = null;
let contract = null;
let address = null;

function init() {
    fetchSupply();
}

function hide(id) {
    document.getElementById(id).style.display = 'none';
}

function show(id, display = 'block') {
    document.getElementById(id).style.display = display;
}

async function fetchSupply() {
    const rpc = new ethers.providers.JsonRpcProvider(RPC_URL);
    const read = new ethers.Contract(CONTRACT, ABI, rpc);
    const supply = await read.totalSupply();
    updateSupply(parseInt(supply));
}

function updateSupply(supply) {
    const el = document.getElementById('supply');
    el.innerText = `${supply} / 10000 minted`;
}

async function connect() {
    if(window.ethereum == null) {
        alert('‧˚₊•┈┈┈୨ Please use an injected web3 wallet ୧┈┈┈•‧₊˚⊹');
        return;
    }

    provider = new ethers.providers.Web3Provider(window.ethereum);
    contract = new ethers.Contract(CONTRACT, ABI, provider);

    provider.provider.on('accountsChanged', function (accounts) {
        address = accounts[0];
        onConnect(true, address);
    });

    const accounts = await provider.send('eth_requestAccounts', []);
    if(accounts.length > 0) {
        address = accounts[0];
        onConnect(true, address);
    } else {
        address = null;
        onConnect(false, null);
    }
}

async function onConnect(status, address) {
    if(status) {
        //show('mintladyTable', 'table');
        //show('mintTable', 'table');
        hide('connectTable');
        const shortAddress = address.substr(0, 6) + '...' + address.substr(-4);
        document.getElementById('address').innerText = `connected as: ${shortAddress}`;
    } else {
        //hide('mintladyTable');
        //hide('mintTable');
        show('connectTable', 'table');
        document.getElementById('address').innerText = `not connected`;
    }
}

async function mintlady() {
    if(address == null) {
        alert('‧˚₊•┈┈┈┈୨ Please connect your wallet Milady ୧┈┈┈┈•‧₊˚⊹');
        return;
    }

    try {
        const contractWithSigner = contract.connect(provider.getSigner(address));
        const tx = await contractWithSigner.mintlady(address);
        await tx.wait();
    } catch(err) {
        alert(err.message);
    }
}

async function mint(num) {
    if(address == null) {
        alert('‧˚₊•┈┈┈┈୨ Please connect your wallet dood ୧┈┈┈┈•‧₊˚⊹');
        return;
    }

    let n = Number(num);
    if(isNaN(n) || n < 1 || n > 255) {
        return console.error('invalid mint number:', num);
    }

    try {
        const price = (await contract.MINT_PRICE()).mul(n);
        const contractWithSigner = contract.connect(provider.getSigner(address));
        const tx = await contractWithSigner.mint(address, n, { value: price });
        await tx.wait();
    } catch(err) {
        alert(err.message);
    }

    await fetchSupply();
}