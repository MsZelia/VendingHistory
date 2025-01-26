package
{
   import Shared.AS3.BSScrollingListEntry;
   import Shared.GlobalFunc;
   import flash.display.MovieClip;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol58")]
   public class VendingSmallEntry extends BSScrollingListEntry
   {
       
      
      public var RaritySymbol_mc:MovieClip;
      
      public var ItemName_mc:MovieClip;
      
      public var MultiBuyerName_mc:MovieClip;
      
      public var BuyerName_mc:MovieClip;
      
      public var PurchaseAmount_mc:MovieClip;
      
      public var PurchaseDate_mc:MovieClip;
      
      public var LegendaryStars_mc:MovieClip;
      
      public var CapsIcon_mc:MovieClip;
      
      public var Warning_tf:TextField;
      
      public function VendingSmallEntry()
      {
         addFrameScript(0,this.frame1,1,this.frame2,2,this.frame3,3,this.frame4);
         super();
         _HasDynamicHeight = false;
      }
      
      override public function SetEntryText(param1:Object, param2:String) : *
      {
         var _loc3_:String = param1.uLegendaryStars > 0 ? "Legendary" : "";
         _loc3_ += selected ? "Select" : "On";
         gotoAndStop(_loc3_);
         var _loc4_:String = VendingEntryShared.SetEntryText(this,param1);
         var _loc5_:String = "";
         var _loc6_:Boolean = false;
         if(param1.sBuyerName)
         {
            if(GlobalFunc.HasPlayerTitle(param1.sBuyerName))
            {
               _loc5_ = GlobalFunc.GeneratePlayerNameAndTitle(param1.sBuyerName);
               _loc6_ = true;
            }
            else
            {
               _loc5_ = param1.sBuyerName;
            }
         }
         else
         {
            _loc5_ = GlobalFunc.LocalizeFormattedString("$Unknown");
         }
         if(_loc6_)
         {
            this.MultiBuyerName_mc.gotoAndStop(_loc4_);
            GlobalFunc.SetTruncatedMultilineText(this.MultiBuyerName_mc.text_tf,_loc5_);
            this.MultiBuyerName_mc.visible = !param1.fakeItem;
            this.BuyerName_mc.visible = false;
         }
         else
         {
            this.BuyerName_mc.gotoAndStop(_loc4_);
            GlobalFunc.SetText(this.BuyerName_mc.text_tf,_loc5_);
            this.BuyerName_mc.visible = !param1.fakeItem;
            this.MultiBuyerName_mc.visible = false;
         }
      }
      
      internal function frame1() : *
      {
         stop();
      }
      
      internal function frame2() : *
      {
         stop();
      }
      
      internal function frame3() : *
      {
         stop();
      }
      
      internal function frame4() : *
      {
         stop();
      }
   }
}
