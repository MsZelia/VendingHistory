package
{
   import Shared.AS3.BSScrollingListEntry;
   import Shared.GlobalFunc;
   import flash.display.MovieClip;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol86")]
   public class VendingFullEntry extends BSScrollingListEntry
   {
      
      private static const ICON_PADDING:Number = 10;
      
      public var RaritySymbol_mc:MovieClip;
      
      public var ItemName_mc:MovieClip;
      
      public var BuyerName_mc:MovieClip;
      
      public var PurchaseAmount_mc:MovieClip;
      
      public var PurchaseDate_mc:MovieClip;
      
      public var LegendaryStars_mc:MovieClip;
      
      public var CapsIcon_mc:MovieClip;
      
      public var Warning_tf:TextField;
      
      public function VendingFullEntry()
      {
         addFrameScript(0,this.frame1,1,this.frame2);
         super();
         _HasDynamicHeight = false;
      }
      
      override public function SetEntryText(param1:Object, param2:String) : *
      {
         var _loc3_:String = selected ? "Select" : "On";
         gotoAndStop(_loc3_);
         var _loc4_:String = VendingEntryShared.SetEntryText(this,param1);
         this.LegendaryStars_mc.x = this.ItemName_mc.x + this.ItemName_mc.text_tf.textWidth + ICON_PADDING;
         var _loc5_:String = "";
         if(param1.sBuyerName)
         {
            _loc5_ = GlobalFunc.GeneratePlayerNameAndTitle(param1.sBuyerName);
         }
         else
         {
            _loc5_ = GlobalFunc.LocalizeFormattedString("$Unknown");
         }
         this.BuyerName_mc.gotoAndStop(_loc4_);
         GlobalFunc.SetText(this.BuyerName_mc.text_tf,_loc5_);
         GlobalFunc.TruncateSingleLineText(this.BuyerName_mc.text_tf);
         this.BuyerName_mc.visible = !param1.fakeItem;
      }
      
      internal function frame1() : *
      {
         stop();
      }
      
      internal function frame2() : *
      {
         stop();
      }
   }
}

