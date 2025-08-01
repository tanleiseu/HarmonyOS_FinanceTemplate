import { BalanceChangeType, BalanceResourceItem, BillConstants } from 'bill_base';
import { BillManageModel } from '../commons/Models';

import { AddBillVM } from '../viewmodels/AddBillVM';
import { CustomKeyboard } from './CustomKeyboard';
import { window } from '@kit.ArkUI';

export class BillManageSheetOptions {
  initBill?: BillManageModel;
  handleConfirm?: (data: BillManageModel) => void;
  handleResourceManage?: () => void;
}

@Builder
export function billManageSheetBuilder(options: BillManageSheetOptions) {
  BillManageSheet({
    initBill: options.initBill,
    handleConfirm: (data) => {
      options?.handleConfirm?.(data);
    },
    handleResourceManage: () => {
      options?.handleResourceManage?.();
    },
  });
}

@ComponentV2
export struct BillManageSheet {
  @Param
  initBill: BillManageModel | undefined = undefined;
  vm: AddBillVM = new AddBillVM();
  @Event
  handleConfirm: (data: BillManageModel) => void;
  @Event
  handleResourceManage: () => void;
  @Local
  windowClass: window.Window | undefined = undefined;
  @Local
  resourceGridH: number = 312;

  @Monitor('initBill')
  initData() {
    if (this.initBill) {
      this.vm.handleBillInitialization(this.initBill);
    }
  }

  async aboutToAppear() {
    this.initData();
    this.windowClass = await window.getLastWindow(getContext());
    if (this.windowClass) {
      const type = this.windowClass.getWindowStatus();
      this.getGridHeight(type);
      this.windowClass.on('windowStatusChange', (type) => {
        this.getGridHeight(type);
      });
    }
  }

  aboutToDisappear(): void {
    if (this.windowClass) {
      this.windowClass.off('windowStatusChange');
    }
  }


  getGridHeight(type: window.WindowStatusType) {
    if (type === window.WindowStatusType.FLOATING) {
      this.resourceGridH = 90;
    } else if (type === window.WindowStatusType.FULL_SCREEN) {
      this.resourceGridH = 312;
    }
  }

  build() {
    Column() {
      Column() {
        // 账单类型选择
        this.typeOptionBuilder();
        // 账单来源选择
        this.resourceGroupBuilder();
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .padding(16);

      // 金额和自定义信息输入
      CustomKeyboard({
        initBill: this.initBill,
        amountArr: [this.initBill ? this.initBill.amount.toString() : ''],
        handleConfirm: (amountArr: string[], note: string, date: Date) => {
          const res = this.vm.handleKeyboardChange(amountArr, note, date);
          if (res) {
            this.handleConfirm?.(this.vm.billData);
          }
        },
      });
    }
    .backgroundColor(BillConstants.BACKGROUND_COLOR_GREY)
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .height('100%');
  }

  @Builder
  typeOptionBuilder() {
    Row() {
      Text('支出')
        .typeOptionStyle(this.vm.billData.type === BalanceChangeType.EXPENSE, this.vm.billData.type)
        .onClick(() => {
          this.vm.handleTypeChange(BalanceChangeType.EXPENSE);
        });
      Text('收入')
        .typeOptionStyle(this.vm.billData.type === BalanceChangeType.INCOME, this.vm.billData.type)
        .onClick(() => {
          this.vm.handleTypeChange(BalanceChangeType.INCOME);
        });
    }
    .margin({ bottom: 24 });
  }

  @Builder
  resourceGroupBuilder() {
    Grid() {
      ForEach(this.vm.displayResourceList, (item: BalanceResourceItem) => {
        GridItem() {
          Column() {
            Image(this.vm.billData.resource === item.key ? item.icon : item.uncheckedIcon).width(40).height(40);
            Text(item.name)
              .fontSize(BillConstants.FONT_SIZE_12)
              .fontWeight(FontWeight.Regular)
              .margin({ top: 12 })
              .fontColor(this.vm.billData.resource === item.key ? BillConstants.FONT_COLOR_LEVEL1 :
              BillConstants.FONT_COLOR_LEVEL2);
          };
        }
        .onClick(() => {
          this.vm.handleResourceChange(item);
        });
      }, (item: BalanceResourceItem) => item.key + '__' + item.name);
      GridItem() {
        Column() {
          Image($r('app.media.ic_manage_resource')).width(40).height(40);
          Text('分类管理')
            .fontSize(BillConstants.FONT_SIZE_12)
            .fontWeight(FontWeight.Regular)
            .margin({ top: 12 })
            .fontColor(BillConstants.FONT_COLOR_LEVEL2);
        };
      }
      .onClick(() => {
        this.handleResourceManage?.();
      });
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
    .rowsGap(16)
    .height(this.resourceGridH)
    .edgeEffect(EdgeEffect.Spring);
  }
}

@Extend(Text)
function typeOptionStyle(isChecked: boolean, type: BalanceChangeType) {
  .fontSize(BillConstants.FONT_SIZE_14)
  .fontColor(isChecked ? BillConstants.FONT_COLOR_1_INVERT : BillConstants.FONT_COLOR_LEVEL1)
  .backgroundColor(isChecked ?
    type === BalanceChangeType.EXPENSE ? BillConstants.THEME_COLOR : BillConstants.THEME_COLOR_SECOND :
  BillConstants.BACKGROUND_COLOR_GREY_2)
  .padding({
    left: 24,
    right: 24,
    top: 8,
    bottom: 8,
  })
  .borderRadius(BillConstants.BORDER_RADIUS_CAPSULE)
  .margin({ right: 12 });
}