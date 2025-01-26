package
{
   import Shared.GlobalFunc;
   import flash.display.MovieClip;
   
   public class VendingEntryShared
   {
      
      public static const MAX_STARS:uint = 5;
      
      public static const ONE_DAY:Number = 86400000;
       
      
      public function VendingEntryShared()
      {
         super();
      }
      
      public static function SetEntryText(param1:MovieClip, param2:Object) : String
      {
         var _loc5_:uint = 0;
         var _loc3_:String = "";
         if(param2.itemRarityTierIndex != null)
         {
            _loc3_ = RarityShared.ItemRarityTierIndexToFrameLabel(param2.itemRarityTierIndex);
         }
         if(_loc3_ != "")
         {
            param1.RaritySymbol_mc.gotoAndStop(_loc3_);
            param1.ItemName_mc.gotoAndStop(_loc3_);
            param1.BuyerName_mc.gotoAndStop(_loc3_);
            param1.PurchaseAmount_mc.gotoAndStop(_loc3_);
            param1.PurchaseDate_mc.gotoAndStop(_loc3_);
            param1.CapsIcon_mc.gotoAndStop(_loc3_);
         }
         param1.ItemName_mc.text_tf.text = !!param2.sItemName ? param2.sItemName : GlobalFunc.LocalizeFormattedString("$Unknown");
         if(param2.uQuantity > 1)
         {
            param1.ItemName_mc.text_tf.appendText(" (" + param2.uQuantity + ")");
         }
         param1.PurchaseAmount_mc.text_tf.text = !!param2.uTotalValue ? param2.uTotalValue : "0";
         param1.PurchaseDate_mc.text_tf.text = calculateTimeStamp(param2.uPurchaseDate);
         var _loc4_:uint;
         if((_loc4_ = uint(param2.uLegendaryStars)) > 0)
         {
            param1.LegendaryStars_mc.visible = true;
            param1.LegendaryStars_mc.gotoAndStop(_loc4_);
            if(_loc3_ != "")
            {
               _loc5_ = 1;
               while(_loc5_ <= _loc4_ && _loc5_ <= MAX_STARS)
               {
                  param1.LegendaryStars_mc["Star" + _loc5_ + "_mc"].gotoAndStop(!!param1.selected ? "selected" : _loc3_);
                  _loc5_++;
               }
            }
         }
         else
         {
            param1.LegendaryStars_mc.visible = false;
         }
         param1.ItemName_mc.visible = !param2.fakeItem;
         param1.CapsIcon_mc.visible = !param2.fakeItem;
         param1.PurchaseAmount_mc.visible = !param2.fakeItem;
         param1.PurchaseDate_mc.visible = !param2.fakeItem;
         param1.Warning_tf.text = !!param2.fakeItem ? param2.sWarning : "";
         return _loc3_;
      }
      
      private static function calculateTimeStamp(param1:Number) : String
      {
         var _loc3_:Date = null;
         var _loc2_:String = "11/14/2018";
         if(param1 > 0)
         {
            _loc3_ = new Date();
            _loc3_.setTime(param1 * 1000);
            if(_loc3_.getTime() - VendingHistoryMenu.getDate().getTime() > ONE_DAY)
            {
               _loc2_ = _loc3_.getMonth() + 1 + "/" + _loc3_.getDate() + "/" + _loc3_.getFullYear();
            }
            else
            {
               _loc2_ = getUSClockTime(_loc3_.getHours(),_loc3_.getMinutes());
            }
         }
         return _loc2_;
      }
      
      private static function getUSClockTime(param1:uint, param2:uint) : String
      {
         var _loc3_:String = "PM";
         var _loc4_:String = doubleDigitFormat(param2);
         if(param1 > 12)
         {
            param1 -= 12;
         }
         else if(param1 == 0)
         {
            _loc3_ = "AM";
            param1 = 12;
         }
         else if(param1 < 12)
         {
            _loc3_ = "AM";
         }
         return doubleDigitFormat(param1) + ":" + _loc4_ + " " + _loc3_;
      }
      
      private static function doubleDigitFormat(param1:uint) : String
      {
         if(param1 < 10)
         {
            return "0" + String(param1);
         }
         return String(param1);
      }
   }
}
