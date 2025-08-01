import { MainEntryVM } from '../viewmodels/MainEntryVM';
import { TAB_LIST } from '../common/Constants';
import { HomeView } from 'home';
import { StatisticsView } from 'statistics';
import { AssetsView } from 'assets';
import { TabIndexMap } from 'commonlib';


@Entry
@ComponentV2
struct MainEntry {
  vm: MainEntryVM = MainEntryVM.instance;

  build() {
    Navigation(this.vm.navStack) {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.vm.curIndex, controller: this.vm.tabController }) {
          TabContent() {
            HomeView()
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
          }
          .tabBar(this.tabBarBuilder(TabIndexMap.HOME))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
          .clip(false);

          TabContent() {
            StatisticsView()
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
          }
          .tabBar(this.tabBarBuilder(TabIndexMap.STATISTICS))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
          .clip(false);

          TabContent() {
            AssetsView()
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
          }
          .tabBar(this.tabBarBuilder(TabIndexMap.ASSETS))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
          .clip(false);
        }
        .scrollable(false)
        .layoutWeight(1)
        .animationDuration(0)
        .divider({ strokeWidth: 1, color: $r('app.color.system_color_grey') })
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.vm.curIndex = index;
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
      }
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .clip(false)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP]);
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    .hideToolBar(true)
    .hideBackButton(true)
    .titleMode(NavigationTitleMode.Full)
    .mode(NavigationMode.Stack);
  }

  async aboutToAppear() {
    await this.vm.initData();
  }

  aboutToDisappear(): void {
    this.vm.cleanListener();
  }

  @Builder
  tabBarBuilder(index: number) {
    Column() {
      Image(this.vm.curIndex === index ? TAB_LIST[index].iconChecked : TAB_LIST[index].icon)
        .width(24)
        .height(24);
      Text(TAB_LIST[index].label)
        .fontColor(this.vm.curIndex === index ? $r('app.color.system_theme_color') :
        $r('app.color.icon_color_level3'))
        .fontWeight(FontWeight.Medium)
        .fontSize($r('app.string.font_size_10'))
        .margin({ top: $r('app.string.space_xs') });
    }
    .width('100%');
  }
}