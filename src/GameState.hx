import Result;
import Player;
import BoardMap;

class GameState
{
   public static var book:BoardMap<BoardValue>;
   public var result:Result;
   public var white:Player;
   public var black:Player;
   public var isWhiteTurn:Bool;
   public var board:BoardState;
   public var moveNumber:Int;
   public var history:Array<String>;
   public var boardStack:Array<BoardState>;
   public var repeatStack:Array<BoardState>;
   public var current:String;
   public var aiWhite:Ai;
   public var aiBlack:Ai;

   public function new(inBook:BoardMap<BoardValue>)
   {
      book = inBook;
      reset();
   }

   public function setPlayers(inWhite:Player, inBlack:Player)
   {
      aiWhite = aiForPlayer(white=inWhite,true);
      aiBlack = aiForPlayer(black=inBlack,false);
   }

   public function reset()
   {
      Ai.stop();
      board = BoardState.start();
      isWhiteTurn = true;
      result = ResPlaying;
      white = PlayHuman;
      black = PlayHuman;
      moveNumber = 1;
      history = [];
      current = " 1: ";
      boardStack = [];
      repeatStack = [];
      aiWhite = aiBlack = null;
      //trace("reset done");
   }

   function aiForPlayer(player:Player, isWhite:Bool) : Ai
   {
      return switch(player)
      {
         case PlayHuman: null;
         case PlayNme(level,brute): new Ai(repeatStack,book,level,brute,isWhite);
      }
   }

   public function getStatus():String
   {
      return switch(result)
      {
         case ResPlaying:
            (isWhiteTurn ?  "White " : "Black " ) +
                     ((isWhiteTurn ? white : black) == PlayHuman ? "To Play" : "Computing");
         case ResWhiteWin: "White Wins!";
         case ResBlackWin: "Black Wins!";
         case ResStalemate: "Stalemate";
         case ResDraw: "Draw";
      }
   }

   public function gameOver() return result!=ResPlaying;


   public function isCpuMove()
   {
      return !isHumanTurn() && result==ResPlaying;
   }

   public function getAiText()
   {
      var ai = isWhiteTurn ? aiWhite : aiBlack;
      var count = ai.evals;
      return (isWhiteTurn ? "White" : "Black") + " computing:" + count;
   }


   public function startCpuMove(onMove)
   {
      var ai = isWhiteTurn ? aiWhite : aiBlack;
      ai.findBestMove(isWhiteTurn,board, onMove );
   }

   public function thinkALittle()
   {
      var ai = isWhiteTurn ? aiWhite : aiBlack;
      if (ai!=null)
         ai.thinkALittle();
   }

   public function isHumanTurn()
   {
      return result==ResPlaying && ( (isWhiteTurn ? white : black) == PlayHuman);
   }

   public function makeMove(move:Move)
   {
      if (move==null)
      {
         // No more moves...
         if (board.isKingInCheck(isWhiteTurn))
            result = isWhiteTurn ? ResBlackWin : ResWhiteWin;
         else
         {
            result = ResStalemate;
            for(r in repeatStack)
               if (r.eq(board))
               {
                  //trace(repeatStack);
                  result = ResDraw;
               }
         }
      }
      else
      {
         var newRow = false;
         if (isWhiteTurn)
         {
            var t = move.getText();
            current += t;
            for(i in t.length ... 6)
               current += " ";
         }
         else
         {
            current += "...  " + move.getText();
            history.push(current);
            current = "";
            newRow = true;
         }

         board = move.newBoard;
         for(b in boardStack)
            if (b.eq(board))
            {
               //trace("Matches prev " + b + "=" +  board );
               for(r in repeatStack)
                  if (r.eq(board))
                  {
                     trace("Repeat match");
                     result = ResDraw;
                  }
               repeatStack.push(board);
            }
         boardStack.push(board);
         //trace("Moves " + boardStack.length + " " + repeatStack.length );
         isWhiteTurn = !isWhiteTurn;

         checkGameOver();
         if (newRow && result==ResPlaying)
         {
            moveNumber++;
            current = (moveNumber<10 ? " " : "") + moveNumber + ": ";
            //trace(moveNumber + " " + result);
         }
      }
      if (result!=ResPlaying)
         addResult();
   }

   function addResult()
   {
      if (current!="")
      {
         history.push(current);
         current = "";
      }
      if (result==ResBlackWin || result==ResWhiteWin)
      {
         var h = history.length;
         if (h>0)
            history[h-1] += "#";
         history.push(result==ResWhiteWin ? "1-0" : "0-1");
      }
      else
         history.push( "1/2 - 1/2" );
   }

   function checkGameOver()
   {
      var allMoves = new Array<Move>();
      for(p in 0...64)
      {
         var piece = board.getColouredPiece(p,isWhiteTurn);
         if (piece!=null)
            piece.getMoves(BPos.fromIndex(p), board, allMoves);
      }
      if (allMoves.length==0)
      {
         // No more moves...
         if (board.isKingInCheck(isWhiteTurn))
            result = isWhiteTurn ? ResBlackWin : ResWhiteWin;
         else
            result = ResStalemate;
      }
   }

   public function getHistory()
   {
      if (history.length==0)
         return current;
      return history.join("\n") + "\n" + current;
   }
}


