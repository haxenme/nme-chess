class BPos
{
   public static var rank = "87654321".split("");
   public static var file = "abcdefgh".split("");
   static var board = [ for(p in 0...64) new BPos(p&7,p>>3) ];

   public var x(default,null):Int;
   public var y(default,null):Int;
   public var index(default,null):Int;
   public var name(default,null):String;

   function new(inX:Int, inY:Int)
   {
      x = inX;
      y = inY;
      index = y*8+x;
      name = file[x] + rank[y];
   }

   inline public static function fromIndex(idx:Int)
   {
      return board[idx];
   }
   public static function create(inX:Int, inY:Int)
   {
      return board[inX+inY*8];
   }

   public function toString() return name;
}
