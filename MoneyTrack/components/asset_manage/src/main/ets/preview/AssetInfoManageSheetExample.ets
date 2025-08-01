import { AssetDisplayTypeItem } from 'asset_base';
import { AssetInfoManageSheet, assetInfoManageSheetBuilder } from '../components/AssetInfoManageSheet';
import { promptAction } from '@kit.ArkUI';

const MOCK_ASSET_ITEM: AssetDisplayTypeItem = {
  name: '现金',
  type: 1,
  subType: 101,
  category: 1,
  icon: $r('app.media.ic_asset_1'),
};

@Entry
@ComponentV2
struct AssetInfoManageSheetExample1 {
  @Local showManageSheet: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('使用方式1：直接使用组件嵌入页面');
      AssetInfoManageSheet({
        assetTypeItem: MOCK_ASSET_ITEM,
        handleConfirm: () => {
          promptAction.showToast({ message: '保存成功~' });
        },
      }).height(300);
      Text('使用方式2：使用bindSheet拉起半模态弹框');
      Button('打开')
        .onClick(() => {
          this.showManageSheet = !this.showManageSheet;
        })
        .bindSheet($$this.showManageSheet,
          assetInfoManageSheetBuilder({}), {
            title: { title: '编辑资产' },
            detents: [SheetSize.MEDIUM],
            onWillDismiss:(action)=> {
              if (action.reason !== DismissReason.TOUCH_OUTSIDE) {
                action.dismiss();
              }
            },
          });
    }
    .backgroundColor('#eee')
    .padding(16);
  }
}