package
{
   public class RarityShared
   {
      
      public static const ITEM_RARITY_NONE:uint = 0;
      
      public function RarityShared()
      {
         super();
      }
      
      public static function ItemRarityTierIndexToFrameLabel(param1:uint = 0) : String
      {
         return "tier" + param1.toString();
      }
   }
}

