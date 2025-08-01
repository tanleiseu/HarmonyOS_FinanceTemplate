import { promptAction } from '@kit.ArkUI';
import relationalStore from '@ohos.data.relationalStore';
import { AssetSummary } from 'asset_base';
import { AccountID } from 'bill_base';
import { BaseDB } from '../basedb/BaseDB';
import { DBOperator } from '../basedb/Constants';
import {
  TableOrderByParams,
  TablePredicateParams,
  TableQueryWithPaginationRsp,
  TableSchema,
} from '../basedb/Types';
import { Logger } from '../Logger';
import { AccountingDBConstants } from './Constants';
import {
  AccountTableFields,
  TransactionTableFields,
  AssetTableFields,
} from './Enums';
import {
  Account,
  AccountTableBasis,
  AmountSummary,
  AssetReport,
  AssetTableBasis,
  TransactionReportRsp,
  TransactionTableBasis,
  UserAsset,
  UserTablePredicateParams,
  UserTransaction,
} from './Types';

const TAG = '[AccountingDB]';

class AccountingDB extends BaseDB {
  protected dbConfig: relationalStore.StoreConfig =
    AccountingDBConstants.DB_CONFIG;
  protected tableSchemas: TableSchema[] = [
    {
      tableName: AccountingDBConstants.ACCOUNT_TABLE_NAME,
      createSQL: AccountingDBConstants.ACCOUNT_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.ACCOUNT_TABLE_INDEXES_CREATE,
    },
    {
      tableName: AccountingDBConstants.TRANSACTION_TABLE_NAME,
      createSQL: AccountingDBConstants.TRANSACTION_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.TRANSACTION_TABLE_INDEXES_CREATE,
    },
    {
      tableName: AccountingDBConstants.ASSET_TABLE_NAME,
      createSQL: AccountingDBConstants.ASSET_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.ASSET_TABLE_INDEXES_CREATE,
    },
  ];

  public async initialize(context: Context) {
    await super.initialize(context);
    await this._initDefaultAccounts();
  }

  // 初始化账本
  private async _initDefaultAccounts() {
    const accountTable: AccountTableBasis = {
      accountId: AccountID.DEFAULT,
      name: '默认账本',
      type: 'default',
    };
    const existing = await this.query<Account>(
      AccountingDBConstants.ACCOUNT_TABLE_NAME,
      [
        {
          field: AccountTableFields.NAME,
          operator: DBOperator.EQUAL,
          value: accountTable.name,
        },
        {
          field: AccountTableFields.TYPE,
          operator: DBOperator.EQUAL,
          value: accountTable.type,
        },
      ],
    );

    if (existing.length === 0) {
      await this.insert(AccountingDBConstants.ACCOUNT_TABLE_NAME, accountTable);
      Logger.info(TAG, 'create account table success');
    }
  }

  // 新增交易记录
  public async addTransaction(userTx: UserTransaction): Promise<void> {
    const tx: TransactionTableBasis = {
      transactionId: new Date().getTime(),
      accountId: userTx.accountId,
      type: userTx.type,
      resource: userTx.resource,
      amount: userTx.amount,
      date: userTx.date,
      note: userTx.note,
      excluded: userTx.excluded,
      assetId: userTx.assetId,
    };
    return this.transaction(async () => {
      try {
        await this.insert(AccountingDBConstants.TRANSACTION_TABLE_NAME, tx);
        promptAction.showToast({ message: '交易记录新增成功~' });
        await this.updateAssetAccountFromTransaction(userTx);
        Logger.info(TAG, 'insert transaction success.');
      } catch (err) {
        promptAction.showToast({ message: '交易记录新增失败，请稍后重试~' });
        Logger.error(
          TAG,
          'insert transaction failed. error:' + JSON.stringify(err),
        );
      }
    });
  }

  // 删除交易记录
  public async deleteTransactions(transactionId: number) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.TRANSACTION_ID,
      value: transactionId,
      operator: DBOperator.EQUAL,
    };
    try {
      await this.delete(AccountingDBConstants.TRANSACTION_TABLE_NAME, [
        condition,
      ]);
      promptAction.showToast({ message: '删除成功~' });
      Logger.info(TAG, 'delete transaction success.');
    } catch (err) {
      promptAction.showToast({ message: '交易记录删除失败，请稍后重试~' });
      Logger.error(
        TAG,
        'delete transaction failed. error:' + JSON.stringify(err),
      );
    }
  }

  // 删除相同类型的所有交易记录
  public async deleteTransactionsByResource(resource: number) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.RESOURCE,
      value: resource,
      operator: DBOperator.EQUAL,
    };
    try {
      const res = await this.delete(
        AccountingDBConstants.TRANSACTION_TABLE_NAME,
        [condition],
      );
      promptAction.showToast({ message: '删除成功~' });
      Logger.info(TAG, 'delete transaction success.');
      return res;
    } catch (err) {
      promptAction.showToast({ message: '交易记录删除失败，请稍后重试~' });
      Logger.error(
        TAG,
        'delete transaction failed. error:' + JSON.stringify(err),
      );
      return 0;
    }
  }

  // 更新交易记录
  public async updateTransactions(userTx: TransactionTableBasis) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.TRANSACTION_ID,
      value: userTx.transactionId,
      operator: DBOperator.EQUAL,
    };
    const tx: TransactionTableBasis = {
      transactionId: userTx.transactionId,
      accountId: userTx.accountId,
      type: userTx.type,
      resource: userTx.resource,
      amount: userTx.amount,
      date: userTx.date,
      note: userTx.note,
      excluded: userTx.excluded,
      assetId: userTx.assetId,
    };
    try {
      const res = await this.update<TransactionTableBasis>(
        AccountingDBConstants.TRANSACTION_TABLE_NAME,
        tx,
        [condition],
      );
      if (res === 1) {
        promptAction.showToast({ message: '交易记录更新成功~' });
        Logger.info(TAG, 'update transaction success.');
      } else {
        throw new Error(res.toString());
      }
    } catch (err) {
      promptAction.showToast({ message: '交易记录更新失败，请稍后重试~' });
      Logger.error(
        TAG,
        'update transaction failed. error:' + JSON.stringify(err),
      );
    }
  }

  // 获取交易记录
  public async getTransactionsWithPagination(
    conditions: UserTablePredicateParams[],
    page: number,
    pageSize: number,
  ): Promise<TableQueryWithPaginationRsp<TransactionTableBasis>> {
    return this.queryWithPagination<TransactionTableBasis>(
      AccountingDBConstants.TRANSACTION_TABLE_NAME,
      conditions,
      page,
      pageSize,
      { field: TransactionTableFields.TRANSACTION_ID, desc: true },
    );
  }

  // 按照指定条件获取交易报表
  public async getTransactions(
    conditions: UserTablePredicateParams[],
  ): Promise<TransactionReportRsp> {
    try {
      return this.transaction<TransactionReportRsp>(async () => {
        const orderBy: TableOrderByParams = {
          field: TransactionTableFields.TRANSACTION_ID,
          desc: true,
        };
        const transactions = await this.query<TransactionTableBasis>(
          AccountingDBConstants.TRANSACTION_TABLE_NAME,
          conditions,
          orderBy,
        );
        const dateCon = conditions.find(
          (item) => item.field === TransactionTableFields.DATE,
        );
        const resourceCon = conditions.find(
          (item) => item.field === TransactionTableFields.RESOURCE,
        );
        const sql = `
        SELECT
           SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as totalIncome,
           SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as totalExpense
        FROM transactions
           WHERE date like '${dateCon ? dateCon.value : ''}%'
           ${resourceCon ? 'AND resource = ' + resourceCon.value : ''}`;
        const summary = await this.querySql<AmountSummary>(sql);
        const res: TransactionReportRsp = {
          transactions,
          totalIncome: summary[0]?.totalIncome ?? 0,
          totalExpense: summary[0]?.totalExpense ?? 0,
        };
        return res;
      });
    } catch (err) {
      Logger.error(
        TAG,
        'get transactions failed. error:' + JSON.stringify(err),
      );
      const res: TransactionReportRsp = {
        transactions: [],
        totalIncome: 0,
        totalExpense: 0,
      };
      return res;
    }
  }

  // 新增资产账户
  public async addAssetAccount(userData: UserAsset) {
    const data: AssetTableBasis = {
      assetId: new Date().getTime(),
      name: userData.name,
      type: userData.type,
      subType: userData.subType,
      category: userData.category,
      amount: userData.amount,
      note: userData.note ?? '',
    };
    return this.transaction(async () => {
      try {
        const res = await this.insert(
          AccountingDBConstants.ASSET_TABLE_NAME,
          data,
        );
        if (res === 1) {
          promptAction.showToast({ message: '资产账户新增成功~' });
          Logger.info(TAG, 'insert asset account success.');
        }
      } catch (err) {
        promptAction.showToast({ message: '资产账户新增失败，请稍后重试~' });
        Logger.error(
          TAG,
          'insert asset account failed. error:' + JSON.stringify(err),
        );
      }
    });
  }

  // 删除资产账户
  public async deleteAssetAccount(assetId: number) {
    const condition: TablePredicateParams = {
      field: AssetTableFields.ASSET_ID,
      value: assetId,
      operator: DBOperator.EQUAL,
    };
    try {
      await this.delete(AccountingDBConstants.ASSET_TABLE_NAME, [condition]);
      promptAction.showToast({ message: '资产账户删除成功~' });
      Logger.info(TAG, 'delete asset account success.');
    } catch (err) {
      promptAction.showToast({ message: '资产账户删除失败，请稍后重试~' });
      Logger.error(
        TAG,
        'delete asset account failed. error:' + JSON.stringify(err),
      );
    }
  }

  // 编辑资产账户
  public async editAssetAccount(userData: AssetTableBasis) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.ASSET_ID,
      value: userData.assetId,
      operator: DBOperator.EQUAL,
    };
    const data: AssetTableBasis = {
      assetId: userData.assetId,
      name: userData.name,
      type: userData.type,
      subType: userData.subType,
      category: userData.category,
      amount: userData.amount,
      note: userData.note ?? '',
    };
    try {
      const res = await this.update<AssetTableBasis>(
        AccountingDBConstants.ASSET_TABLE_NAME,
        data,
        [condition],
      );
      if (res === 1) {
        promptAction.showToast({ message: '资产账户更新成功~' });
        Logger.info(TAG, 'update asset account success.');
      } else {
        throw new Error(res.toString());
      }
    } catch (err) {
      promptAction.showToast({ message: '资产账户更新失败，请稍后重试~' });
      Logger.error(
        TAG,
        'update asset account failed. error:' + JSON.stringify(err),
      );
    }
  }

  // 根据交易记录更新资产账户
  public async updateAssetAccountFromTransaction(
    tx: UserTransaction | TransactionTableBasis,
  ) {
    const assetId = tx.assetId;
    if (!assetId) {
      return;
    }
    const isExpense = tx.type === 'expense';
    const sql = `
    UPDATE assets
    SET amount = amount ${isExpense ? '-' : '+'} ${tx.amount}
    WHERE assetId = ${assetId}
    `;
    await this.executeSql(sql);
  }

  // 获取资产账户列表
  public async getAssetAccount(conditions: UserTablePredicateParams[]) {
    try {
      return this.transaction<AssetReport>(async () => {
        const assets = await this.query<AssetTableBasis>(
          AccountingDBConstants.ASSET_TABLE_NAME,
          conditions,
        );
        const assetIdCon = conditions[0];
        const sql = `
        SELECT
           SUM(CASE WHEN category = 1 THEN amount ELSE 0 END) as totalAsset,
           SUM(CASE WHEN category = 2 THEN amount ELSE 0 END) as totalLiability
        FROM assets
            ${assetIdCon ? 'WHERE assetId = ' + assetIdCon.value : ''}
        `;
        const summary = await this.querySql<AssetSummary>(sql);
        const res: AssetReport = {
          assets,
          totalAsset: summary[0]?.totalAsset ?? 0,
          totalLiability: summary[0]?.totalLiability ?? 0,
        };
        return res;
      });
    } catch (err) {
      Logger.error(TAG, 'get assets failed. error:' + JSON.stringify(err));
      const res: AssetReport = {
        assets: [],
        totalAsset: 0,
        totalLiability: 0,
      };
      return res;
    }
  }
}

const accountingDB = new AccountingDB();

export { accountingDB as AccountingDB };
