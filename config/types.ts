export interface ChainConfig {
  chainId?: number;
  chainSelector: string;
  router: string;
  rmnProxy: string;
  tokenAdminRegistry: string;
  registryModuleOwnerCustom: string;
  link: string;
  confirmations: number;
  nativeCurrencySymbol: string;
}

export enum Chains {
  avalancheFuji = "avalancheFuji",
  arbitrumSepolia = "arbitrumSepolia",
  sepolia = "sepolia",
  baseSepolia = "baseSepolia",
  ethereum = "ethereum",
  base = "base",
}

export type Configs = {
  [key in Chains]: ChainConfig;
};

export interface NetworkConfig extends ChainConfig {
  url: string;
  gasPrice?: number;
  nonce?: number;
  accounts: string[];
}

export type Networks = Partial<{
  [key in Chains]: NetworkConfig;
}>;

type ApiKeyConfig = Partial<{
  [key in Chains]: string;
}>;

interface Urls {
  apiURL: string;
  browserURL: string;
}

interface CustomChain {
  network: string;
  chainId: number;
  urls: Urls;
}

export interface EtherscanConfig {
  apiKey: ApiKeyConfig;
  customChains: CustomChain[];
}

export enum TokenContractName {
  BurnMintERC677 = "BurnMintERC677",
  BurnMintERC677WithCCIPAdmin = "BurnMintERC677WithCCIPAdmin",
  BurnMintERC20 = "BurnMintERC20",
}

export enum TokenPoolContractName {
  BurnMintTokenPool = "BurnMintTokenPool",
  USDOBurnMintTokenPool = "USDOBurnMintTokenPool",
  USDOBurnMintTokenPoolWithApproval = "USDOBurnMintTokenPoolWithApproval",
  LockReleaseTokenPool = "LockReleaseTokenPool",
}

export enum PoolType {
  burnMint = "burnMint",
  lockRelease = "lockRelease",
}
