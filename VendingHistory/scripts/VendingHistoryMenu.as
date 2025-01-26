package
{
   import Shared.AS3.BCGridList;
   import Shared.AS3.BSButtonHintData;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.IMenu;
   import Shared.GlobalFunc;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.text.TextField;
   
   public class VendingHistoryMenu extends IMenu
   {
      
      public static const VENDING_SORT_DATE:uint = 0;
      
      public static const VENDING_SORT_ITEM_ALPHA:uint = 1;
      
      public static const VENDING_SORT_USER_ALPHA:uint = 2;
      
      public static const VENDING_SORT_CAPS:uint = 3;
      
      public static const VENDING_SORT_COUNT:uint = 4;
      
      public static const EVENT_CLOSE:String = "VendingHistoryMenu::Close";
      
      public static const EVENT_DEACTIVATE:String = "VendingHistoryMenu::Deactivate";
      
      public static const ARROW_OFFSET:uint = 12;
      
      public static var m_TodaysDate:Date = new Date();
       
      
      public var VendorHistoryFullScreen_mc:MovieClip;
      
      public var VendorHistorySmall_mc:MovieClip;
      
      public var ButtonHintBar_mc:MovieClip;
      
      private var CancelButton:BSButtonHintData;
      
      private var SortButton:BSButtonHintData;
      
      private var m_Ascending:Boolean = true;
      
      private var m_CurrentMenu:MovieClip;
      
      private var m_UseSmallView:Boolean = false;
      
      private var m_ViewSet:Boolean = false;
      
      private var m_EmptyList:Boolean = false;
      
      private var m_SortStyle:uint = 0;
      
      private var m_HistoryList:BCGridList;
      
      private var m_SalesData:Array;
      
      public function VendingHistoryMenu()
      {
         this.CancelButton = new BSButtonHintData("$CANCEL","TAB","PSN_B","Xenon_B",1,this.onCancel);
         this.SortButton = new BSButtonHintData("$SORT_DATE","R","PSN_X","Xenon_X",1,this.onSortPress);
         super();
         this.m_SalesData = [];
      }
      
      public static function getDate() : Date
      {
         return m_TodaysDate;
      }
      
      override public function onAddedToStage() : void
      {
         super.onAddedToStage();
         stage.focus = this;
         this.onShow();
         BSUIDataManager.Subscribe("VendingHistoryInfoData",this.onUpdateVendorData);
      }
      
      private function onCancel() : void
      {
         BSUIDataManager.dispatchEvent(new Event(EVENT_CLOSE));
      }
      
      private function onDeactivate() : void
      {
         BSUIDataManager.dispatchEvent(new Event(EVENT_DEACTIVATE));
      }
      
      private function onShow() : void
      {
         this.VendorHistorySmall_mc.visible = this.m_UseSmallView;
         this.VendorHistoryFullScreen_mc.visible = !this.m_UseSmallView;
      }
      
      private function updateList() : void
      {
         this.m_CurrentMenu = this.m_UseSmallView ? this.VendorHistorySmall_mc : this.VendorHistoryFullScreen_mc;
         if(this.m_HistoryList != this.m_CurrentMenu.HistoryList_mc)
         {
            this.m_HistoryList = this.m_CurrentMenu.HistoryList_mc;
            this.m_HistoryList.listItemClassName = this.m_UseSmallView ? "VendingSmallEntry" : "VendingFullEntry";
            this.m_HistoryList.maxCols = 1;
            this.m_HistoryList.maxRows = this.m_UseSmallView ? 10 : 16;
            this.m_HistoryList.disableInput = false;
         }
         if(this.m_CurrentMenu.Header_tf)
         {
            this.m_CurrentMenu.Header_tf.text = GlobalFunc.LocalizeFormattedString("$CAMP_SLOTS_VENDING_HISTORY");
         }
         this.PopulateButtonBar();
      }
      
      protected function PopulateButtonBar() : void
      {
         this.ButtonHintBar_mc.visible = true;
         var _loc1_:Vector.<BSButtonHintData> = new Vector.<BSButtonHintData>();
         _loc1_.push(this.CancelButton);
         _loc1_.push(this.SortButton);
         this.ButtonHintBar_mc.SetButtonHintData(_loc1_);
      }
      
      public function ProcessRightThumbstickInput(param1:uint) : Boolean
      {
         var _loc2_:Boolean = false;
         switch(param1)
         {
            case 1:
               if(this.m_HistoryList.selectedIndex > 0 && !this.m_EmptyList)
               {
                  --this.m_HistoryList.selectedIndex;
               }
               _loc2_ = true;
               break;
            case 3:
               if(!this.m_EmptyList)
               {
                  ++this.m_HistoryList.selectedIndex;
               }
               _loc2_ = true;
         }
         return true;
      }
      
      private function onUpdateVendorData(param1:FromClientDataEvent) : void
      {
         var _loc2_:* = param1.data;
         if(_loc2_)
         {
            if(!this.m_ViewSet)
            {
               this.m_UseSmallView = _loc2_.bUseSmallWindow;
               this.onShow();
               this.m_ViewSet = true;
            }
            this.updateList();
            if(_loc2_.salesA.length > 0)
            {
               if(this.m_EmptyList)
               {
                  this.m_SalesData.length = 0;
                  this.m_EmptyList = false;
               }
               this.m_SalesData = _loc2_.salesA;
            }
            if(this.m_SalesData.length == 0)
            {
               this.m_SalesData.push({
                  "fakeItem":true,
                  "sWarning":GlobalFunc.LocalizeFormattedString("$CAMP_SLOTS_VENDING_HISTORY_EMPTY")
               });
               this.m_EmptyList = true;
            }
            this.m_HistoryList.disableInput = this.m_EmptyList;
            this.sortEntries();
            this.m_HistoryList.selectedIndex = this.m_EmptyList ? -1 : 0;
         }
      }
      
      public function getSort() : uint
      {
         return this.m_SortStyle;
      }
      
      public function setSort(param1:uint) : uint
      {
         var _loc2_:String = null;
         if(this.m_SortStyle != param1)
         {
            this.m_SortStyle = param1;
            if(this.m_SortStyle >= VENDING_SORT_COUNT)
            {
               this.m_SortStyle = VENDING_SORT_DATE;
            }
            _loc2_ = "";
            switch(param1)
            {
               case VENDING_SORT_ITEM_ALPHA:
                  _loc2_ = "$SORT_ITEM";
                  break;
               case VENDING_SORT_USER_ALPHA:
                  _loc2_ = "$SORT_BUYER";
                  break;
               case VENDING_SORT_CAPS:
                  _loc2_ = "$SORT_CAPS";
                  break;
               case VENDING_SORT_DATE:
               default:
                  _loc2_ = "$SORT_DATE";
            }
            this.SortButton.ButtonText = GlobalFunc.LocalizeFormattedString(_loc2_);
         }
         return this.m_SortStyle;
      }
      
      public function sortEntries() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:TextField = null;
         var _loc1_:uint = 0;
         if(!this.m_Ascending)
         {
            _loc1_ = Array.DESCENDING;
         }
         this.m_CurrentMenu.NameSort_mc.visible = this.m_SortStyle == VENDING_SORT_ITEM_ALPHA;
         this.m_CurrentMenu.BuyerSort_mc.visible = this.m_SortStyle == VENDING_SORT_USER_ALPHA;
         if(this.m_UseSmallView)
         {
            this.m_CurrentMenu.InfoSort_mc.visible = this.m_SortStyle == VENDING_SORT_CAPS || this.m_SortStyle == VENDING_SORT_DATE;
         }
         else
         {
            this.m_CurrentMenu.AmountSort_mc.visible = this.m_SortStyle == VENDING_SORT_CAPS;
            this.m_CurrentMenu.DateSort_mc.visible = this.m_SortStyle == VENDING_SORT_DATE;
         }
         switch(this.m_SortStyle)
         {
            case VENDING_SORT_ITEM_ALPHA:
               this.m_HistoryList.entryData = this.m_SalesData.sortOn(["sItemName","uPurchaseDate","sBuyerName","uTotalValue"],[_loc1_,_loc1_ | Array.NUMERIC,_loc1_,_loc1_ | Array.NUMERIC]);
               _loc2_ = this.m_CurrentMenu.NameSort_mc;
               _loc3_ = this.m_CurrentMenu.NameSort_tf;
               break;
            case VENDING_SORT_USER_ALPHA:
               this.m_HistoryList.entryData = this.m_SalesData.sortOn(["sBuyerName","uPurchaseDate","sItemName","uTotalValue"],[_loc1_,_loc1_ | Array.NUMERIC,_loc1_,_loc1_ | Array.NUMERIC]);
               _loc2_ = this.m_CurrentMenu.BuyerSort_mc;
               _loc3_ = this.m_CurrentMenu.BuyerSort_tf;
               break;
            case VENDING_SORT_CAPS:
               this.m_HistoryList.entryData = this.m_SalesData.sortOn(["uTotalValue","uPurchaseDate","sItemName","sBuyerName"],[_loc1_ | Array.NUMERIC,_loc1_ | Array.NUMERIC,_loc1_,_loc1_]);
               if(this.m_UseSmallView)
               {
                  _loc2_ = this.m_CurrentMenu.InfoSort_mc;
                  _loc3_ = null;
               }
               else
               {
                  _loc2_ = this.m_CurrentMenu.AmountSort_mc;
                  _loc3_ = this.m_CurrentMenu.AmountSort_tf;
               }
               break;
            case VENDING_SORT_DATE:
            default:
               this.m_HistoryList.entryData = this.m_SalesData.sortOn(["uPurchaseDate","sItemName","sBuyerName","uTotalValue"],[_loc1_ | Array.NUMERIC,_loc1_,_loc1_,_loc1_ | Array.NUMERIC]);
               if(this.m_UseSmallView)
               {
                  _loc2_ = this.m_CurrentMenu.InfoSort_mc;
                  _loc3_ = null;
               }
               else
               {
                  _loc2_ = this.m_CurrentMenu.DateSort_mc;
                  _loc3_ = this.m_CurrentMenu.DateSort_tf;
               }
         }
         _loc2_.gotoAndStop(this.m_Ascending ? "Ascending" : "Descending");
         if(_loc3_)
         {
            _loc2_.x = _loc3_.x + Math.min(_loc3_.width,_loc3_.textWidth) + ARROW_OFFSET;
         }
      }
      
      public function onSortPress() : uint
      {
         this.m_Ascending = !this.m_Ascending;
         this.setSort(this.m_SortStyle + (this.m_Ascending ? 1 : 0));
         this.sortEntries();
         return this.m_SortStyle;
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         var _loc3_:Boolean = false;
         if(!param2)
         {
            switch(param1)
            {
               case "Up":
                  if(this.m_HistoryList.selectedIndex > 0 && !this.m_EmptyList)
                  {
                     --this.m_HistoryList.selectedIndex;
                  }
                  _loc3_ = true;
                  break;
               case "Down":
                  if(!this.m_EmptyList)
                  {
                     ++this.m_HistoryList.selectedIndex;
                  }
                  _loc3_ = true;
                  break;
               case "Accept":
                  _loc3_ = true;
                  break;
               case "ToggleMap":
                  _loc3_ = true;
                  break;
               case "Cancel":
               case "ForceClose":
                  this.onCancel();
                  _loc3_ = true;
                  break;
               case "XButton":
                  this.onSortPress();
                  _loc3_ = true;
            }
         }
         return _loc3_;
      }
   }
}
