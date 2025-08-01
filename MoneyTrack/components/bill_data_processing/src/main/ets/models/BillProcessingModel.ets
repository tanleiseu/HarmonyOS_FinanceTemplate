import { BillCardItem, DailyBillGroup, ResourceUtil } from 'bill_base';
import dayjs from 'dayjs';
import { MOCK_BILL_RESP, MOCK_DAILY_BILL_LIST } from '../mocks/MockData';
import { AccountingDB } from '../utils/accountingdb/AccountingDB';
import { TransactionTableFields } from '../utils/accountingdb/Enums';
import {
  TransactionReportRsp,
  UserTablePredicateParams,
} from '../utils/accountingdb/Types';
import { DBOperator } from '../utils/basedb/Constants';
import { AssetProcessingModel } from './AssetProcessingModel';

@ObservedV2
export class BillProcessingModel {
  @Trace date: string = dayjs().format('YYYY-MM');
  @Trace bill: TransactionReportRsp | null = null;
  @Trace list: DailyBillGroup[] | null = null;
  @Trace assetProcessing: AssetProcessingModel = new AssetProcessingModel();

  @Computed
  public get dateLabel() {
    if (this.date) {
      return dayjs(new Date(this.date)).format('YYYY年MM月');
    }
    return dayjs().format('YYYY年MM月');
  }

  @Computed
  public get totalIncome() {
    return this.bill?.totalIncome?.toFixed(2) ?? '0.00';
  }

  @Computed
  public get totalExpense() {
    return this.bill?.totalExpense?.toFixed(2) ?? '0.00';
  }

  public previewMock() {
    this.bill = MOCK_BILL_RESP;
    this.list = MOCK_DAILY_BILL_LIST;
  }

  public changeMonth(date: string) {
    this.date = date;
  }

  public async getBillReport(checkedResource: number = -1, date: string = '') {
    if (date) {
      this.changeMonth(date);
    }

    let conditions: UserTablePredicateParams[] = [];
    const dateCondition: UserTablePredicateParams = {
      field: TransactionTableFields.DATE,
      value: this.date,
      operator: DBOperator.BEGIN_WITH,
    };
    conditions.push(dateCondition);
    if (checkedResource !== -1) {
      const resourceCondition: UserTablePredicateParams = {
        field: TransactionTableFields.RESOURCE,
        value: checkedResource,
        operator: DBOperator.EQUAL,
      };
      conditions.push(resourceCondition);
    }
    this.bill = await AccountingDB.getTransactions(conditions);
    await this._setBillGroup(this.bill);
  }

  public async getBillReportByAsset(assetId: number) {
    const condition: UserTablePredicateParams = {
      field: TransactionTableFields.ASSET_ID,
      value: assetId,
      operator: DBOperator.EQUAL,
    };
    this.bill = await AccountingDB.getTransactions([condition]);
    this._setBillGroup(this.bill);
  }

  private async _setBillGroup(res: TransactionReportRsp) {
    const map: Map<string, BillCardItem[]> = new Map();

    // 使用map创建Promise数组
    const promises = res.transactions.map(async (item) => {
      const resourceItem = ResourceUtil.getResourceItem(item.resource);
      const card: BillCardItem = {
        accountId: item.accountId,
        date: item.date,
        transactionId: item.transactionId,
        resource: item.resource,
        icon: resourceItem.icon,
        title: resourceItem.name,
        note: item.note,
        amount: item.amount,
        type: item.type,
      };
      if (item.assetId) {
        const condition: UserTablePredicateParams = {
          field: TransactionTableFields.ASSET_ID,
          value: item.assetId,
          operator: DBOperator.EQUAL,
        };
        const assetRes = await AccountingDB.getAssetAccount([condition]);
        if (assetRes.assets.length === 1) {
          const assetName = assetRes.assets[0].name;
          card.assetName = assetName;
        }
      }
      if (map.has(item.date)) {
        map.get(item.date)?.push(card);
      } else {
        map.set(item.date, [card]);
      }
    });

    await Promise.all(promises);

    this.list = Array.from(map).map((item) => {
      const date = item[0];
      const list = item[1];
      list.sort((a, b) => b.transactionId - a.transactionId);
      const group: DailyBillGroup = {
        dateStr: dayjs(new Date(date)).format('YYYY-MM-DD'),
        list,
      };
      return group;
    });
    this.list.sort(
      (a, b) => new Date(b.dateStr).getTime() - new Date(a.dateStr).getTime(),
    );
  }
}
