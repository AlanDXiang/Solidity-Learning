# Building a User-Friendly Frontend for Your GameCharacter NFT

Excellent work deploying your contract to Sepolia! Now let's build an interactive frontend that brings your dynamic NFTs to life. I'll guide you through creating a modern, user-friendly web application.

## 📋 **Frontend Architecture Overview**

Your frontend will need to:
1. **Connect to MetaMask** (wallet connection)
2. **Mint NFTs** (call the `mint()` function)
3. **Display owned characters** (show user's NFTs with their dynamic images)
4. **Train characters** (call the `train()` function)
5. **Show real-time stat updates** (display level, strength, health, XP)

---

## 🛠️ **Step 1: Project Setup**

### Create a new React project with Vite (faster than Create React App):

```bash
npm create vite@latest gamecharacter-frontend -- --template react
cd gamecharacter-frontend
npm install
```

### Install necessary dependencies:

```bash
npm install ethers@5.7.2  # For blockchain interaction
npm install @rainbow-me/rainbowkit wagmi viem@1  # Modern wallet connection
```

---

## 📁 **Step 2: Project Structure**

Create this folder structure:

```
gamecharacter-frontend/
├── src/
│   ├── components/
│   │   ├── ConnectWallet.jsx
│   │   ├── MintCharacter.jsx
│   │   ├── CharacterCard.jsx
│   │   └── CharacterList.jsx
│   ├── contracts/
│   │   └── GameCharacter.json  # Your contract ABI
│   ├── App.jsx
│   ├── App.css
│   └── main.jsx
```

---

## 🔧 **Step 3: Get Your Contract ABI**

You need the ABI (Application Binary Interface) to interact with your contract.

**If you used Hardhat:**
```bash
# Find it in: artifacts/contracts/GameCharacter.sol/GameCharacter.json
# Copy the entire JSON file to src/contracts/GameCharacter.json
```

**If you used Remix:**
1. Go to the "Compile" tab
2. Click "ABI" button
3. Copy the JSON
4. Create `src/contracts/GameCharacter.json` and paste it

---

## 💻 **Step 4: Core Components**

### **4.1 - App.jsx (Main Application)**

```jsx
// src/App.jsx
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';
import ConnectWallet from './components/ConnectWallet';
import MintCharacter from './components/MintCharacter';
import CharacterList from './components/CharacterList';
import GameCharacterABI from './contracts/GameCharacter.json';

// 🔥 REPLACE THIS WITH YOUR DEPLOYED CONTRACT ADDRESS
const CONTRACT_ADDRESS = "0xYourContractAddressHere";

function App() {
  const [account, setAccount] = useState(null);
  const [contract, setContract] = useState(null);
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  // Initialize connection when component mounts
  useEffect(() => {
    checkIfWalletIsConnected();
  }, []);

  // Check if wallet is already connected
  const checkIfWalletIsConnected = async () => {
    try {
      if (!window.ethereum) {
        alert("Please install MetaMask!");
        return;
      }

      const accounts = await window.ethereum.request({ 
        method: 'eth_accounts' 
      });

      if (accounts.length > 0) {
        connectWallet();
      }
    } catch (error) {
      console.error("Error checking wallet connection:", error);
    }
  };

  // Connect to MetaMask
  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        alert("Please install MetaMask!");
        return;
      }

      // Request account access
      const accounts = await window.ethereum.request({ 
        method: 'eth_requestAccounts' 
      });

      // Setup provider and signer
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
    
      // Create contract instance
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        GameCharacterABI.abi, // If your JSON is {abi: [...]}
        signer
      );

      setAccount(accounts[0]);
      setProvider(provider);
      setSigner(signer);
      setContract(contract);
      setIsConnected(true);

      console.log("Connected to:", accounts[0]);
    } catch (error) {
      console.error("Error connecting wallet:", error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🎮 GameCharacter NFT</h1>
        <p>Dynamic On-Chain Characters</p>
      </header>

      <main className="App-main">
        {!isConnected ? (
          <ConnectWallet onConnect={connectWallet} />
        ) : (
          <>
            <div className="account-info">
              <p>Connected: {account?.slice(0, 6)}...{account?.slice(-4)}</p>
            </div>

            <MintCharacter contract={contract} account={account} />
          
            <CharacterList 
              contract={contract} 
              account={account} 
              provider={provider}
            />
          </>
        )}
      </main>
    </div>
  );
}

export default App;
```

---

### **4.2 - ConnectWallet.jsx**

```jsx
// src/components/ConnectWallet.jsx
import React from 'react';

function ConnectWallet({ onConnect }) {
  return (
    <div className="connect-wallet">
      <div className="wallet-card">
        <h2>Welcome to GameCharacter</h2>
        <p>Connect your wallet to mint and train your character!</p>
        <button className="btn-primary" onClick={onConnect}>
          Connect MetaMask
        </button>
      </div>
    </div>
  );
}

export default ConnectWallet;
```

---

### **4.3 - MintCharacter.jsx**

```jsx
// src/components/MintCharacter.jsx
import { useState } from 'react';

function MintCharacter({ contract, account }) {
  const [isMinting, setIsMinting] = useState(false);
  const [mintStatus, setMintStatus] = useState('');

  const handleMint = async () => {
    if (!contract) return;

    try {
      setIsMinting(true);
      setMintStatus('Minting your character...');

      // Call the mint function
      const tx = await contract.mint(account);
    
      setMintStatus('Transaction submitted! Waiting for confirmation...');
    
      // Wait for transaction to be mined
      const receipt = await tx.wait();
    
      setMintStatus('✅ Character minted successfully!');
    
      // Refresh page after 2 seconds
      setTimeout(() => {
        window.location.reload();
      }, 2000);

    } catch (error) {
      console.error("Minting error:", error);
      setMintStatus('❌ Error minting character. Check console.');
    } finally {
      setIsMinting(false);
    }
  };

  return (
    <div className="mint-section">
      <h2>Mint Your Character</h2>
      <button 
        className="btn-primary" 
        onClick={handleMint}
        disabled={isMinting}
      >
        {isMinting ? 'Minting...' : 'Mint Character (Free!)'}
      </button>
      {mintStatus && <p className="status-message">{mintStatus}</p>}
    </div>
  );
}

export default MintCharacter;
```

---

### **4.4 - CharacterCard.jsx**

```jsx
// src/components/CharacterCard.jsx
import { useState } from 'react';

function CharacterCard({ tokenId, attributes, contract, onTrain }) {
  const [isTraining, setIsTraining] = useState(false);

  const handleTrain = async () => {
    if (!contract) return;

    try {
      setIsTraining(true);
      const tx = await contract.train(tokenId);
      await tx.wait();
    
      // Call parent component to refresh
      onTrain();
    } catch (error) {
      console.error("Training error:", error);
      alert("Error training character");
    } finally {
      setIsTraining(false);
    }
  };

  return (
    <div className="character-card">
      <div className="character-header">
        <h3>Character #{tokenId}</h3>
        <span className="level-badge">Level {attributes.level.toString()}</span>
      </div>

      <div className="character-image">
        {/* The SVG is generated on-chain, so we'll fetch it */}
        <img 
          src={`data:image/svg+xml;utf8,${encodeURIComponent(attributes.svg)}`}
          alt={`Character ${tokenId}`}
        />
      </div>

      <div className="character-stats">
        <div className="stat">
          <span className="stat-label">💪 Strength:</span>
          <span className="stat-value">{attributes.strength.toString()}</span>
        </div>
        <div className="stat">
          <span className="stat-label">❤️ Health:</span>
          <span className="stat-value">{attributes.health.toString()}</span>
        </div>
        <div className="stat">
          <span className="stat-label">⭐ XP:</span>
          <span className="stat-value">{attributes.experience.toString()}</span>
        </div>
      </div>

      <button 
        className="btn-secondary" 
        onClick={handleTrain}
        disabled={isTraining}
      >
        {isTraining ? 'Training...' : '🏋️ Train Character'}
      </button>
    </div>
  );
}

export default CharacterCard;
```

---

### **4.5 - CharacterList.jsx**

```jsx
// src/components/CharacterList.jsx
import { useState, useEffect } from 'react';
import CharacterCard from './CharacterCard';
import { ethers } from 'ethers';

function CharacterList({ contract, account, provider }) {
  const [characters, setCharacters] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (contract && account) {
      loadCharacters();
    }
  }, [contract, account]);

  const loadCharacters = async () => {
    try {
      setLoading(true);

      // Get total supply
      const totalMinted = await contract.totalMinted();
      const userCharacters = [];

      // Check each token to see if user owns it
      for (let i = 1; i <= totalMinted.toNumber(); i++) {
        try {
          const owner = await contract.ownerOf(i);
        
          if (owner.toLowerCase() === account.toLowerCase()) {
            // Get character attributes
            const attrs = await contract.getCharacterAttributes(i);
          
            // Generate the SVG image
            const svg = await contract.generateCharacterImage(i);

            userCharacters.push({
              tokenId: i,
              attributes: {
                level: attrs.level,
                strength: attrs.strength,
                health: attrs.health,
                experience: attrs.experience,
                svg: svg
              }
            });
          }
        } catch (err) {
          // Token doesn't exist or other error
          continue;
        }
      }

      setCharacters(userCharacters);
    } catch (error) {
      console.error("Error loading characters:", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading your characters...</div>;
  }

  if (characters.length === 0) {
    return (
      <div className="no-characters">
        <p>You don't own any characters yet. Mint one above!</p>
      </div>
    );
  }

  return (
    <div className="character-list">
      <h2>Your Characters</h2>
      <div className="characters-grid">
        {characters.map((char) => (
          <CharacterCard
            key={char.tokenId}
            tokenId={char.tokenId}
            attributes={char.attributes}
            contract={contract}
            onTrain={loadCharacters} // Refresh after training
          />
        ))}
      </div>
    </div>
  );
}

export default CharacterList;
```

---

## 🎨 **Step 5: Basic Styling (App.css)**

```css
/* src/App.css */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
}

.App {
  min-height: 100vh;
  color: white;
}

.App-header {
  text-align: center;
  padding: 2rem;
  background: rgba(0, 0, 0, 0.3);
}

.App-header h1 {
  font-size: 3rem;
  margin-bottom: 0.5rem;
}

.App-main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

/* Wallet Connection */
.connect-wallet {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 60vh;
}

.wallet-card {
  background: white;
  color: #333;
  padding: 3rem;
  border-radius: 20px;
  text-align: center;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
}

/* Buttons */
.btn-primary, .btn-secondary {
  padding: 1rem 2rem;
  font-size: 1.1rem;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: bold;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover {
  background: #5568d3;
  transform: translateY(-2px);
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-secondary {
  background: #48bb78;
  color: white;
  width: 100%;
}

/* Character Cards */
.characters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
  margin-top: 2rem;
}

.character-card {
  background: white;
  color: #333;
  border-radius: 15px;
  padding: 1.5rem;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
}

.character-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.level-badge {
  background: #e94560;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  