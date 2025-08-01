import { Constants } from 'asset_base';
import { AssetManageUtil } from '../utils/AssetManageUtil';
import { emitter } from '@kit.BasicServicesKit';
import { ASSET_CREATE_EVENT_ID } from '../commons/Constants';

@ComponentV2
export struct AddAssetButton {
  @Event
  handleSuccess: () => void;

  aboutToAppear(): void {
    emitter.on({ eventId: ASSET_CREATE_EVENT_ID }, () => {
      this.handleSuccess?.();
    });
  }

  aboutToDisappear(): void {
    emitter.off(ASSET_CREATE_EVENT_ID);
  }

  build() {
    Button() {
      Row() {
        Image($r('app.media.ic_add'))
          .height(16)
          .margin({ right: 8 });
        Text('添加资产')
          .fontColor(Constants.FONT_COLOR_LEVEL1)
          .fontWeight(FontWeight.Medium);
      };
    }
    .width('100%')
    .backgroundColor(Constants.BUTTON_BACKGROUND_COLOR_GREY)
    .padding(12)
    .onClick(() => {
      AssetManageUtil.openAddAssetSheet();
    });
  }
}