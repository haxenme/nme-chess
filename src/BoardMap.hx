#if cpp
using cpp.NativeArray;
import sys.io.File;
#end
import haxe.io.Output;
import haxe.io.Input;


class BoardValue
{
   public var hash:Int;
   public var board:BoardState;
   public var whiteWins:Int;
   public var draws:Int;
   public var blackWins:Int;
   public var size(get,null):Int;

   public function new(inBoard:BoardState,inHash:Int)
   {
      board = inBoard;
      hash = inHash;
      whiteWins = 0;
      draws = 0;
      blackWins = 0;
   }
   public function dump(file:Output)
   {
      file.writeInt32(hash);
      file.writeInt32(whiteWins);
      file.writeInt32(draws);
      file.writeInt32(blackWins);
   }
   public function load(file:Input)
   {
      whiteWins = file.readInt32();
      draws = file.readInt32();
      blackWins = file.readInt32();
   }
   public function get_size() return whiteWins + draws + blackWins;


   public static function loadMap(input:Input) : BoardMap<BoardValue>
   {
      var header = input.readString(4);
      if (header!="BOOK")
         throw "Bad magic";
      var n = input.readInt32();
      var map = new BoardMap<BoardValue>(n);
      for(i in 0...n)
      {
         var hash = input.readInt32();
         var value = map.findBoard(null,hash);
         value.load(input);
      }
      return map;
   }

}



//class BoardMap< Value: { hash:Int; function new(hash:Int):Value } >

@:generic
class BoardMap< Value: {
      public var hash:Int;
      public var board:BoardState;
      public function dump(o:Output):Void;
   } &  haxe.Constraints.Constructible<BoardState->Int->Void> >
{
   var values:Array<Array<Value>>;
   public var count(default,null):Int;
   var mask:Int;

   public function new(origSize=2047)
   {
      origSize>>3;
      mask = 2;
      while(origSize>0)
      {
         origSize>>=1;
         mask<<=1;
      }
      mask -= 1;
      count = 0;
      values = [];
      #if cpp
      values.setSize(mask+1);
      #else
      values[mask]=null;
      #end
   }

   function rehash()
   {
      var old = mask+1;
      mask = old*2-1;
      #if cpp
      values.setSize(mask+1);
      #else
      values[mask]=null;
      #end
      for(i in 0...old)
      {
         var valueArray = values[i];
         if (valueArray!=null)
         {
            var nextValue:Array<Value> = null;
            var destIdx = 0;
            #if cpp
            var destSize = valueArray.length;
            while(destIdx<destSize)
            {
               var elem = valueArray[destIdx];
               var slot = elem.hash & mask;
               if (slot==i)
                  destIdx++;
               else
               {
                  if (nextValue==null)
                  {
                     nextValue = [elem];
                     values[slot] = nextValue;
                  }
                  else
                     nextValue.push(elem);
                  destSize--;
                  valueArray[destIdx] = valueArray[destSize];
               }
               valueArray.setSize(destSize);
            }
            #else
            var replaceValue:Array<Value> = null;
            for(elem in valueArray)
            {
               var slot = elem.hash & mask;
               if (slot==i)
               {
                  if (replaceValue==null)
                     replaceValue = [elem];
                  else
                     replaceValue.push(elem);
               }
               else
               {
                  if (nextValue==null)
                  {
                     nextValue = [elem];
                     values[slot] = nextValue;
                  }
                  else
                     nextValue.push(elem);
               }
            }
            values[i] = replaceValue;
            #end
         }
      }
      //verify();
   }
   public function verify()
   {
      for(bin in 0...mask+1)
      {
         var a = values[bin];
         if (a!=null)
            for(v in a)
               if ( (v.hash&mask)!=bin)
                  throw "bad hash";
      }
   }

   public function findBoard(board:BoardState,hash:Int,orCreate=true)
   {
      var bin = hash&mask;
      var valueArray = values[bin];
      if (valueArray==null)
      {
         if (!orCreate)
            return null;
         count++;
         var value = new Value(board,hash);
         values[bin] = [value];
         return value;
      }
      for(v in valueArray)
         if (v.hash==hash)
         {
            if (board==null || board.eq(v.board))
               return v;
         }
      if (!orCreate)
          return null;
      count++;
      var value = new Value(board,hash);
      valueArray.push(value);
      if (count>mask*8)
         rehash();
      return value;
   }


   #if cpp
   // Filter = (v) -> v.size>minElements
   public function dump(filename:String, filter:Value->Bool)
   {
      var valid = 0;
      for(a in values)
         if (a!=null)
            for(v in a)
               if (filter(v))
                  valid++;
      //trace("Valid " + minElements + ":" + valid + "/" + count);
      var file = File.write(filename);
      file.writeString("BOOK");
      file.writeInt32(valid);
      for(a in values)
         if (a!=null)
            for(v in a)
               if (filter(v))
                  v.dump(file);
      file.close();
   }
   #end
}

