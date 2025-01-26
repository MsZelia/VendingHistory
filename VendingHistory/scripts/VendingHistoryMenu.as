package
{
   import Shared.AS3.BCGridList;
   import Shared.AS3.BSButtonHintData;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.Data.UIDataFromClient;
   import Shared.AS3.Events.PlatformChangeEvent;
   import Shared.AS3.IMenu;
   import Shared.GlobalFunc;
   import com.adobe.serialization.json.*;
   import flash.display.MovieClip;
   import flash.events.*;
   import flash.net.*;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import flash.utils.*;
   
   public class VendingHistoryMenu extends IMenu
   {
      
      public static var DEBUG:Boolean = false;
      
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
      
      private var m_Ascending:Boolean = false;
      
      private var m_CurrentMenu:MovieClip;
      
      private var m_UseSmallView:Boolean = false;
      
      private var m_ViewSet:Boolean = false;
      
      private var m_EmptyList:Boolean = false;
      
      private var m_SortStyle:uint = 0;
      
      private var m_HistoryList:BCGridList;
      
      private var m_SalesData:Array;
      
      private var vendorLogData:Array;
      
      private var vendorLogHistory:Array;
      
      private var lastSalesHistory:Array;
      
      private var vendorDataMatch:RegExp;
      
      private var vendorDataDelim:String;
      
      private var salesHistoryAtInit:int = -1;
      
      private var titleItem:String = "";
      
      private var searchPhrase:String = "";
      
      private var matchChar:*;
      
      private var isSearching:Boolean = false;
      
      private var ctrlDown:Boolean = false;
      
      private const months:* = {
         "Jan":0,
         "Feb":1,
         "Mar":2,
         "Apr":3,
         "May":4,
         "Jun":5,
         "Jul":6,
         "Aug":7,
         "Sep":8,
         "Oct":9,
         "Nov":10,
         "Dec":11
      };
      
      public function VendingHistoryMenu()
      {
         this.lastSalesHistory = [];
         this.CancelButton = new BSButtonHintData("$CANCEL","TAB","PSN_B","Xenon_B",1,this.onCancel);
         this.SortButton = new BSButtonHintData("$SORT_DATE","R","PSN_X","Xenon_X",1,this.onSortPress);
         super();
         this.m_SalesData = [];
         this.initVendorLogData();
      }
      
      public static function getDate() : Date
      {
         return m_TodaysDate;
      }
      
      private function toString(param1:Object) : String
      {
         return new JSONEncoder(param1).getString();
      }
      
      private function initVendorLogData() : void
      {
         this.matchChar = /([a-z0-9.]|\-| )+/;
         var dummy:TextField = new TextField();
         GlobalFunc.SetText(dummy,"$PlayerVendingSuccess");
         this.vendorDataDelim = dummy.text.replace("{1}","").replace("{2}","");
         this.vendorDataMatch = new RegExp(dummy.text.replace("{1}",".+").replace("{2}",".+"),"i");
         this.loadVendorLogData();
      }
      
      private function loadVendorLogData() : void
      {
         var loaderComplete:Function;
         var url:URLRequest = null;
         var loader:URLLoader = null;
         try
         {
            loaderComplete = function(param1:Event):void
            {
               var i:int;
               var parts:Array;
               var timeDateString:String;
               var timeParts:Array;
               var year:int;
               var month:int;
               var day:int;
               var hour:int;
               var minute:int;
               var second:int;
               var record:*;
               var vendorRecords:Array;
               try
               {
                  vendorLogData = loader.data.split("\n");
                  i = vendorLogData.length - 1;
                  record = {};
                  vendorRecords = [];
                  while(i >= 0)
                  {
                     if(vendorLogData[i] != "")
                     {
                        parts = vendorLogData[i].split("\t");
                        if(parts.length == 3)
                        {
                           timeDateString = parts[1];
                           if(vendorDataMatch.test(parts[2]))
                           {
                              parts = parts[2].split(vendorDataDelim);
                              if(parts.length == 2)
                              {
                                 record.sBuyerName = parts[0];
                                 record.sItemName = parts[1].replace("\r","");
                                 record.uQuantity = 1;
                                 record.uLegendaryStars = 0;
                                 record.itemRarityTierIndex = 0;
                                 record.itemRarityTierCount = 0;
                                 record.uLegendaryStars = 0;
                              }
                              parts = timeDateString.split(" ");
                              if(parts.length == 6)
                              {
                                 timeParts = parts[3].split(":");
                                 year = !!isNaN(parts[5]) ? 0 : int(parts[5]);
                                 month = int(months[parts[1]] != null ? months[parts[1]] : 0);
                                 day = !!isNaN(parts[2]) ? 0 : int(parts[2]);
                                 hour = 0;
                                 minute = 0;
                                 second = 0;
                                 if(timeParts.length == 3)
                                 {
                                    hour = !!isNaN(timeParts[0]) ? 0 : int(timeParts[0]);
                                    minute = !!isNaN(timeParts[1]) ? 0 : int(timeParts[1]);
                                    second = !!isNaN(timeParts[2]) ? 0 : int(timeParts[2]);
                                 }
                                 record.uPurchaseDate = uint(new Date(year,month,day,hour,minute,second).time / 1000);
                              }
                              else
                              {
                                 record.uPurchaseDate = uint(m_TodaysDate.time / 1000) - 86401 - (vendorLogData.length - i) * 60;
                              }
                           }
                           else
                           {
                              parts = parts[2].split(" ");
                              if(parts.length > 0 && !isNaN(parts[0]))
                              {
                                 record.uTotalValue = uint(parts[0]);
                              }
                           }
                        }
                        if(record.uTotalValue != null && record.sBuyerName != null)
                        {
                           vendorRecords.push(record);
                           record = {};
                           if(vendorRecords.length > 4096)
                           {
                              break;
                           }
                        }
                     }
                     i--;
                  }
                  vendorLogHistory = vendorRecords;
                  setTimeout(refreshList,500);
               }
               catch(e:Error)
               {
                  GlobalFunc.ShowHUDMessage("Error parsing vendorlog data: " + e.getStackTrace() + (i > 0 && vendorLogData != null && vendorLogData.length > 0 ? " (line " + (vendorLogData.length - i + 1) + ")" : ""));
               }
            };
            url = new URLRequest("../vendorlog.txt");
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete);
            addEventListener(KeyboardEvent.KEY_UP,this.keyUpHandler);
            addEventListener(KeyboardEvent.KEY_DOWN,this.keyDownHandler);
         }
         catch(e:Error)
         {
            GlobalFunc.ShowHUDMessage("Error loading vendorlog data: " + e.getStackTrace());
         }
      }
      
      private function keyDownHandler(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.CONTROL)
         {
            this.ctrlDown = true;
         }
         else if(this.isSearching)
         {
            if(param1.keyCode == Keyboard.BACKSPACE)
            {
               if(this.searchPhrase.length > 0)
               {
                  if(this.ctrlDown)
                  {
                     this.searchPhrase = "";
                  }
                  else
                  {
                     this.searchPhrase = this.searchPhrase.substr(0,this.searchPhrase.length - 1);
                  }
                  this.refreshList();
               }
            }
            else if(param1.keyCode == 173 && param1.shiftKey)
            {
               this.searchPhrase += "_";
               this.refreshList();
            }
            else if(matchChar.test(String.fromCharCode(param1.charCode)))
            {
               this.searchPhrase += String.fromCharCode(param1.charCode);
               this.refreshList();
            }
            else if(param1.keyCode == Keyboard.LEFT)
            {
               if(CancelButton.uiKeyboard == PlatformChangeEvent.PLATFORM_PC_KB_BE || CancelButton.uiKeyboard == PlatformChangeEvent.PLATFORM_PC_KB_FR)
               {
                  this.searchPhrase += "q";
               }
               else
               {
                  this.searchPhrase += "a";
               }
               this.refreshList();
            }
            else if(param1.keyCode == Keyboard.UP)
            {
               if(CancelButton.uiKeyboard == PlatformChangeEvent.PLATFORM_PC_KB_BE || CancelButton.uiKeyboard == PlatformChangeEvent.PLATFORM_PC_KB_FR)
               {
                  this.searchPhrase += "z";
               }
               else
               {
                  this.searchPhrase += "w";
               }
               this.refreshList();
            }
            else if(param1.keyCode == Keyboard.RIGHT)
            {
               this.searchPhrase += "d";
               this.refreshList();
            }
            else if(param1.keyCode == Keyboard.DOWN)
            {
               this.searchPhrase += "s";
               this.refreshList();
            }
            else if(param1.keyCode == 0 || param1.keyCode == 171 || param1.keyCode == Keyboard.NUMPAD_ADD || param1.keyCode == Keyboard.ENTER)
            {
               this.searchPhrase += ".";
               this.refreshList();
            }
            else if(DEBUG)
            {
               this.searchPhrase += param1.keyCode;
               this.refreshList();
            }
         }
      }
      
      private function refreshList(str:String) : void
      {
         this.onUpdateVendorData(new FromClientDataEvent(new UIDataFromClient({
            "salesA":[],
            "bUseSmallWindow":this.m_UseSmallView
         })));
      }
      
      private function keyUpHandler(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.CONTROL)
         {
            this.ctrlDown = false;
         }
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
         var searchRegEx:*;
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
            if(salesHistoryAtInit == -1)
            {
               this.salesHistoryAtInit = _loc2_.salesA.length;
            }
            if(_loc2_.salesA.length > 0)
            {
               this.lastSalesHistory = _loc2_.salesA;
            }
            if(this.vendorLogHistory)
            {
               _loc2_.salesA = this.lastSalesHistory.concat(this.vendorLogHistory.slice(this.salesHistoryAtInit));
            }
            if(this.searchPhrase.length > 0)
            {
               searchRegEx = new RegExp(this.searchPhrase,"i");
               _loc2_.salesA = _loc2_.salesA.filter(function(element:*):Boolean
               {
                  return searchRegEx.test(element.sBuyerName) || searchRegEx.test(element.sItemName);
               });
            }
            if(this.titleItem == "")
            {
               this.titleItem = this.m_CurrentMenu.NameSort_tf.text;
            }
            this.m_CurrentMenu.NameSort_tf.text = this.titleItem + "[" + _loc2_.salesA.length + "] : " + this.searchPhrase + (this.isSearching ? "" : " (search:CTRL+F)");
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
         this.setSort(this.m_SortStyle + (this.m_Ascending ? 0 : 1));
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
                  if(this.isSearching)
                  {
                     this.isSearching = false;
                     this.refreshList();
                  }
                  else
                  {
                     this.onCancel();
                  }
                  _loc3_ = true;
                  break;
               case "XButton":
                  if(!this.isSearching)
                  {
                     this.onSortPress();
                  }
                  _loc3_ = true;
                  break;
               case "LTrigger":
                  this.isSearching = true;
                  this.refreshList();
                  _loc3_ = true;
            }
         }
         return _loc3_;
      }
   }
}
