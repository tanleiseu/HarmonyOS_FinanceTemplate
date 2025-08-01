import { AssetCategory, AssetType } from './Enums';

export interface AssetRecordItem {
  assetId: number;
  name: string;
  icon: ResourceStr;
  type: AssetType;
  subType: number;
  category: AssetCategory;
  amount: number;
  note?: string;
  isCustom?: boolean;
}

export interface AssetSummary {
  totalAsset: number;
  totalLiability: number;
}

export interface AssetReportRsp extends AssetSummary {
  assets: AssetRecordItem[];
}

export interface AssetGroup {
  fund: AssetRecordItem[];
  credit: AssetRecordItem[];
}

export interface AssetTypeItem {
  name: string;
  type: AssetType;
  subType: number;
  category: AssetCategory;
  isCustom?: boolean;
}

export interface AssetDisplayTypeItem extends AssetTypeItem {
  icon: ResourceStr;
}
