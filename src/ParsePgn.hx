import sys.io.File;
import sys.io.FileInput;
import haxe.io.BytesInput;
import BoardMap;

class ParsePgn
{
   var file:FileInput;
   var board0:BoardState;
   var book:BoardMap<BoardValue>;

   public function new(filename:String,inBook:BoardMap<BoardValue>)
   {
      board0 = BoardState.start();
      book = inBook;
      file = File.read(filename,false);
   }

   public function run()
   {
      var count = 0;
      var whiteWins = 0;
      var blackWins = 0;
      var draws = 0;
      var headerState = true;
      var gameCount = 0;
      var result = 0;
      var move = 1;
      var board = board0.clone();
      var lineId = 0;
      var boardsTotal = 0;

      try
      {
        while(true)
        {
           var line = file.readLine();
           lineId++;
           if (line=="")
           {
              headerState = !headerState;
              if (headerState)
              {
                 if ( (gameCount%1000)== 0)
                    trace('lines:$lineId  g=$gameCount boards=$boardsTotal, uniq=' + book.count);
                 gameCount++;
                 result = 0;
                 move = 1;
                 board = board0.clone();
              }
           }
           else if (headerState)
           {
              if (line=='[Result "1/2-1/2"]')
              {
                 result = 2;
                 draws++;
              }
              else if (line=='[Result "1-0"]')
              {
                 result = 1;
                 whiteWins++;
              }
              else if (line=='[Result "0-1"]')
              {
                 result = 3;
                 blackWins++;
              }
           }
           else
           {
              var parts = line.split(" ");
              var moves = Std.int( parts.length/3 );
              for(m in 0...moves)
              {
                 //trace("Move " + parts[m*3]);
                 //var moveId = Std.parseInt(parts[m*3]);
                 //if (moveId!=move)
                 //   trace('Bad move : ${parts[m*3]} / $moveId / $move');
                 board.moveString(true, parts[m*3+1]);
                 if (move<=8)
                 {
                    boardsTotal++;
                    var code = board.hashCode();
                    var value = book.findBoard(null,board.hashCode() );
                    if (result==1)
                       value.whiteWins++;
                    else if (result==3)
                       value.blackWins++;
                    else
                       value.draws++;
                 }

                 board.moveString(false, parts[m*3+2]);
                 if (move<=8)
                 {
                    boardsTotal++;
                    var value = book.findBoard(null,board.hashCode() );
                    if (result==1)
                       value.whiteWins++;
                    else if (result==3)
                       value.blackWins++;
                    else
                       value.draws++;
                 }

                 move++;
              }
           }
        }
      }
      catch(e:Dynamic)
      {
         trace("At game:" + gameCount);
         trace("At line:" + lineId);
         trace("Done:" + e);
      }
   }

   public static function main()
   {
      var filenames = ["c:/Share/data/chess/gm2016.pgn"];
      var args = Sys.args();
      if (args.length>0)
         filenames = args;

      //var bytes = sys.io.File.getBytes("opening.book");
      //var book = BoardMap.load(new BytesInput(bytes));
      var book = new BoardMap<BoardValue>();

      for(filename in filenames)
      {
         trace("======== " + filename);
         var parser = new ParsePgn(filename,book);
         parser.run();
      }
      book.dump("opening.book", (v)->v.size>5);
   }
}
