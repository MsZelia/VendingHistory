package
{
   import Shared.AS3.BCGridList;
   import Shared.AS3.BSButtonHintData;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.Data.UIDataFromClient;
   import Shared.AS3.Events.CustomEvent;
   import Shared.AS3.IMenu;
   import Shared.GlobalFunc;
   import com.adobe.serialization.json.*;
   import flash.display.MovieClip;
   import flash.events.*;
   import flash.net.*;
   import flash.text.*;
   import flash.ui.Keyboard;
   import flash.utils.*;
   
   public class VendingHistoryMenu extends IMenu
   {
      
      public static var DEBUG:Boolean = false;
      
      public static const MOD_VERSION:String = "1.0.6";
      
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
      
      private var vendorDataDelims:Array;
      
      private var salesHistoryAtInit:int = -1;
      
      private var lastMonth:int = -1;
      
      private var yearOffset:int = 0;
      
      private var findLocalized:String;
      
      private var itemLocalized:String;
      
      private var searchPhrase:String = "";
      
      private var _isSearching:Boolean = false;
      
      private var ctrlDown:Boolean = false;
      
      private var previousFocus:* = null;
      
      private var search_tf:TextField;
      
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
      
      private function get isSearching() : Boolean
      {
         return this._isSearching;
      }
      
      private function set isSearching(value:Boolean) : void
      {
         if(value == this._isSearching)
         {
            return;
         }
         this._isSearching = value;
         if(value)
         {
            this.previousFocus = stage.focus;
            if(this.search_tf)
            {
               stage.focus = this.search_tf;
               BSUIDataManager.dispatchEvent(new CustomEvent("ControlMap::StartEditText",{"tag":"FriendSearch"}));
            }
         }
         else
         {
            stage.focus = this.previousFocus;
            BSUIDataManager.dispatchEvent(new CustomEvent("ControlMap::EndEditText",{"tag":"FriendSearch"}));
         }
         this.refreshList();
      }
      
      private function toString(param1:Object) : String
      {
         return new JSONEncoder(param1).getString();
      }
      
      private function reverse(param1:String) : String
      {
         var inputA:* = param1.split("");
         inputA.reverse();
         return inputA.join("");
      }
      
      private function initSearchTextfield() : void
      {
         var font:TextFormat;
         this.search_tf = new TextField();
         this.search_tf.x = -1;
         this.search_tf.y = -100;
         this.search_tf.width = 1;
         this.search_tf.height = 1;
         this.search_tf.text = "";
         this.search_tf.mouseWheelEnabled = false;
         this.search_tf.mouseEnabled = false;
         this.search_tf.selectable = false;
         this.search_tf.visible = true;
         this.search_tf.type = TextFieldType.INPUT;
         font = new TextFormat("$MAIN_Font",18,16777215);
         this.search_tf.defaultTextFormat = font;
         this.search_tf.setTextFormat(font);
         this.search_tf.addEventListener(KeyboardEvent.KEY_UP,this.onSearchKey);
         this.search_tf.addEventListener(Event.CHANGE,function(e:*):void
         {
            searchPhrase = search_tf.text.toLowerCase().substr(0,64).replace("\n","").replace("\r","");
            refreshList();
         });
         addChild(this.search_tf);
      }
      
      private function initVendorLogData() : void
      {
         this.vendorLogHistory = [];
         this.lastSalesHistory = [];
         this.vendorDataDelims = [];
         this.itemLocalized = this.VendorHistoryFullScreen_mc.NameSort_tf.text;
         var dummy:TextField = new TextField();
         GlobalFunc.SetText(dummy,"$FIND");
         this.findLocalized = dummy.text;
         GlobalFunc.SetText(dummy,"$PlayerVendingSuccess");
         var tempDelims:Array = dummy.text.split("{1}");
         for each(d in tempDelims)
         {
            this.vendorDataDelims = this.vendorDataDelims.concat(d.split("{2}"));
         }
         this.vendorDataMatch = new RegExp(dummy.text.replace("{1}",".+").replace("{2}",".+"),"i");
         this.initSearchTextfield();
         this.loadVendorLogData();
         addEventListener(KeyboardEvent.KEY_UP,this.keyUpHandler);
         addEventListener(KeyboardEvent.KEY_DOWN,this.keyDownHandler);
      }
      
      private function onSearchKey(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.BACKSPACE)
         {
            if(this.searchPhrase.length > 0)
            {
               if(this.ctrlDown)
               {
                  this.search_tf.text = "";
               }
            }
         }
         else if(param1.keyCode == Keyboard.TAB || param1.keyCode == Keyboard.ESCAPE)
         {
            this.isSearching = false;
         }
      }
      
      private function keyDownHandler(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.CONTROL)
         {
            this.ctrlDown = true;
         }
         else if(param1.keyCode == Keyboard.F5)
         {
            this.isSearching = true;
         }
      }
      
      private function keyUpHandler(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.CONTROL)
         {
            this.ctrlDown = false;
         }
         else if(param1.keyCode == Keyboard.F9)
         {
            DEBUG = !DEBUG;
         }
      }
      
      private function refreshList(str:String) : void
      {
         this.onUpdateVendorData(new FromClientDataEvent(new UIDataFromClient({
            "salesA":[],
            "bUseSmallWindow":this.m_UseSmallView
         })));
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
               var year:int;
               var month:int;
               var day:int;
               var hour:int;
               var minute:int;
               var second:int;
               var record:*;
               var vendorRecords:Array;
               var dateParts:Array = [];
               var timeParts:Array = [];
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
                        if(parts.length == 2)
                        {
                           parts = [""].concat(parts);
                        }
                        if(parts.length == 3)
                        {
                           timeDateString = parts[1];
                           if(vendorDataMatch.test(parts[2]))
                           {
                              if(record.sBuyerName != null)
                              {
                                 record.uTotalValue = 0;
                                 vendorRecords.push(record);
                                 record = {};
                              }
                              parts = parts[2].substring(vendorDataDelims[0].length,parts[2].length - vendorDataDelims[2].length - 1).split(vendorDataDelims[1]);
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
                              dateParts = timeDateString.split(" ");
                              if(dateParts.length > 3)
                              {
                                 timeParts = dateParts[3].split(":");
                                 if(timeParts.length == 2)
                                 {
                                    hour = !isNaN(timeParts[0]) ? int(timeParts[0]) : 0;
                                    minute = !isNaN(timeParts[1]) ? int(timeParts[1]) : 0;
                                    second = 0;
                                 }
                                 else if(timeParts.length == 3)
                                 {
                                    hour = !isNaN(timeParts[0]) ? int(timeParts[0]) : 0;
                                    minute = !isNaN(timeParts[1]) ? int(timeParts[1]) : 0;
                                    second = !isNaN(timeParts[2]) ? int(timeParts[2]) : 0;
                                 }
                                 else
                                 {
                                    hour = 0;
                                    minute = 0;
                                    second = 0;
                                 }
                                 day = !isNaN(dateParts[2]) ? int(dateParts[2]) : 0;
                                 month = int(months[dateParts[1]] != null ? months[dateParts[1]] : 0);
                                 if(lastMonth != -1)
                                 {
                                    if(month > lastMonth)
                                    {
                                       ++yearOffset;
                                    }
                                    lastMonth = month;
                                 }
                                 else
                                 {
                                    lastMonth = month;
                                 }
                                 if(dateParts.length == 5)
                                 {
                                    if(dateParts[4].indexOf("GMT") == -1 && !isNaN(dateParts[4]))
                                    {
                                       year = int(dateParts[4]);
                                    }
                                    else
                                    {
                                       year = m_TodaysDate.fullYear - yearOffset;
                                    }
                                 }
                                 else if(dateParts.length == 6 && !isNaN(dateParts[5]))
                                 {
                                    year = int(dateParts[5]);
                                 }
                                 else
                                 {
                                    year = m_TodaysDate.fullYear - yearOffset;
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
                        }
                        if(vendorRecords.length > 4096)
                        {
                           break;
                        }
                     }
                     i--;
                  }
                  vendorLogHistory = vendorRecords;
                  setTimeout(refreshList,1000);
               }
               catch(e:*)
               {
                  GlobalFunc.ShowHUDMessage("Error parsing vendorlog data" + (i > 0 && vendorLogData != null && vendorLogData.length > 0 ? " (line " + (i + 1) + "): " : ": ") + e);
               }
            };
            url = new URLRequest("../vendorlog.txt");
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete);
         }
         catch(e:Error)
         {
            GlobalFunc.ShowHUDMessage("Error loading vendorlog data: " + e.getStackTrace());
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
            if(this.salesHistoryAtInit == -1)
            {
               this.salesHistoryAtInit = _loc2_.salesA.length;
            }
            if(_loc2_.salesA.length > 0 && this.vendorLogHistory.length != _loc2_.salesA.length)
            {
               this.lastSalesHistory = _loc2_.salesA.concat();
            }
            if(this.vendorLogHistory.length > 0)
            {
               _loc2_.salesA = this.lastSalesHistory.concat(this.vendorLogHistory.slice(this.salesHistoryAtInit));
            }
            if(this.searchPhrase.length > 0)
            {
               _loc2_.salesA = _loc2_.salesA.filter(function(element:*):Boolean
               {
                  return element.sBuyerName.toLowerCase().indexOf(searchPhrase) != -1 || element.sItemName.toLowerCase().indexOf(searchPhrase) != -1 || element.uTotalValue.toString().indexOf(searchPhrase) != -1;
               });
            }
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
            this.m_CurrentMenu.NameSort_tf.text = this.itemLocalized + "[" + _loc2_.salesA.length + "] : " + this.searchPhrase + (this.isSearching ? "" : (this.searchPhrase.length > 0 ? " (F5)" : " (" + this.findLocalized + ":F5)"));
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
                  if(!this.isSearching)
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
            }
         }
         return _loc3_;
      }
   }
}

