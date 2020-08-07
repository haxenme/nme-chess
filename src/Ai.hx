import BoardState;
#if sys
import sys.thread.Thread;
#end

import BoardMap;

class BoardInfo
{
   public var hash:Int;
   public var board:BoardState;
   public var upperBound:Int;
   public var lowerBound:Int;
   public var debugMoves:Array<Move>;

   public function new(inBoard:BoardState,inHash:Int)
   {
      hash = inHash;
      board = inBoard;
      lowerBound = -1000000;
      upperBound = 1000000;
   }
   public function dump(o:haxe.io.Output) { }
   public function toString() return '($debugMoves: $lowerBound ... $upperBound)';
}

typedef BoardMem = BoardMap<BoardInfo>;

class BoundState
{
   public var next:BoundState;
   public var moves:Array<Move>;
   public var movePos:Int;
   public var isRoot(get,null):Bool;
   public var info:BoardInfo;
   public var best:Int;

   public function new()
   {
      movePos = 0;
      best = -Ai.CHECKMATE-500;
   }
   inline function get_isRoot() return info==null;
   public function makeNext(inInfo:BoardInfo, inMoves:Array<Move>)
   {
      next = new BoundState();
      next.info = inInfo;
      next.moves = inMoves;
      return next;
   }
   public function pop()
   {
      next = null;
   }
}


class Ai
{
   public static inline var CHECKMATE = 1000000;
   public static inline var STALEMATE = 0;
   public static inline var asyncProcess = false;

   static var whiteValue = [
      0, 0, -929, -479, -320, -280, -100, 0,
      0, 0,  929,  479,  320,  280,  100, 0
   ];


   // Taken from sunfish
   static var whitePawnPos  = [
             0,   0,   0,   0,   0,   0,   0,   0,
            78,  83,  86,  73, 102,  82,  85,  90,
             7,  29,  21,  44,  40,  31,  44,   7,
           -17,  16,  -2,  15,  14,   0,  15, -13,
           -26,   3,  10,   9,   6,   1,   0, -23,
           -22,   9,   5, -11, -10,  -2,   3, -19,
           -31,   8,  -7, -37, -36, -14,   3, -31,
             0,   0,   0,   0,   0,   0,   0,   0 ];

    static var whiteKnightPos =  [
            -66, -53, -75, -75, -10, -55, -58, -70,
            -3,  -6, 100, -36,   4,  62,  -4, -14,
            10,  67,   1,  74,  73,  27,  62,  -2,
            24,  24,  45,  37,  33,  41,  25,  17,
            -1,   5,  31,  21,  22,  35,   2,   0,
           -18,  10,  13,  22,  18,  15,  11, -14,
           -23, -15,   2,   0,   2,   0, -23, -20,
           -74, -23, -26, -24, -19, -35, -22, -69 ];

    static var whiteBishopPos = [
           -59, -78, -82, -76, -23,-107, -37, -50,
           -11,  20,  35, -42, -39,  31,   2, -22,
            -9,  39, -32,  41,  52, -10,  28, -14,
            25,  17,  20,  34,  26,  25,  15,  10,
            13,  10,  17,  23,  17,  16,   0,   7,
            14,  25,  24,  15,   8,  25,  20,  15,
            19,  20,  11,   6,   7,   6,  20,  16,
            -7,   2, -15, -12, -14, -15, -10, -10 ];

    static var whiteRookPos = [
            35,  29,  33,   4,  37,  33,  56,  50,
            55,  29,  56,  67,  55,  62,  34,  60,
            19,  35,  28,  33,  45,  27,  25,  15,
             0,   5,  16,  13,  18,  -4,  -9,  -6,
           -28, -35, -16, -21, -13, -29, -46, -30,
           -42, -28, -42, -25, -25, -35, -26, -46,
           -53, -38, -31, -26, -29, -43, -44, -53,
           -30, -24, -18,   5,  -2, -18, -31, -32 ];

    static var whiteQueenPos = [
            6,   1,  -8,-104,  69,  24,  88,  26,
            14,  32,  60, -10,  20,  76,  57,  24,
            -2,  43,  32,  60,  72,  63,  43,   2,
             1, -16,  22,  17,  25,  20, -13,  -6,
           -14, -15,  -2,  -5,  -1, -10, -20, -22,
           -30,  -6, -13, -11, -16, -11, -16, -27,
           -36, -18,   0, -19, -15, -15, -21, -38,
           -39, -30, -31, -13, -31, -36, -34, -42 ];

    static var whiteKingPos = [
           4,  54,  47, -99, -99,  60,  83, -62,
           -32,  10,  55,  56,  56,  55,  10,   3,
           -62,  12, -57,  44, -67,  28,  37, -31,
           -55,  50,  11,  -4, -19,  13,   0, -49,
           -55, -43, -52, -28, -51, -47,  -8, -50,
           -47, -42, -43, -79, -64, -32, -29, -32,
            -4,   3, -14, -50, -57, -18,  13,   4,
            17,  30,  -3, -14,   6,  -1,  40,  18 ];

   static var blackPawnPos = [ for( i in 0...64) -whitePawnPos[ ((7-(i>>3))<<3) | (i&7)] ];
   static var blackKnightPos = [ for( i in 0...64) -whiteKnightPos[ ((7-(i>>3))<<3) | (i&7)] ];
   static var blackBishopPos = [ for( i in 0...64) -whiteBishopPos[ ((7-(i>>3))<<3) | (i&7)] ];
   static var blackRookPos = [ for( i in 0...64) -whiteRookPos[ ((7-(i>>3))<<3) | (i&7)] ];
   static var blackQueenPos = [ for( i in 0...64) -whiteQueenPos[ ((7-(i>>3))<<3) | (i&7)] ];
   static var blackKingPos = [ for( i in 0...64) -whiteKingPos[ ((7-(i>>3))<<3) | (i&7)] ];

   static var sSquareValue = [
      [ for(i in 0...64) 0],
      blackKingPos,
      [ for(v in blackQueenPos) v + whiteValue[2] ],
      [ for(v in blackRookPos) v + whiteValue[3] ],
      [ for(v in blackBishopPos) v + whiteValue[4] ],
      [ for(v in blackKnightPos) v + whiteValue[5] ],
      [ for(v in blackPawnPos) v + whiteValue[6] ],
      null,
      [ for(i in 0...64) 0],
      whiteKingPos,
      [ for(v in whiteQueenPos) v + whiteValue[10] ],
      [ for(v in whiteRookPos) v + whiteValue[11] ],
      [ for(v in whiteBishopPos) v + whiteValue[12] ],
      [ for(v in whiteKnightPos) v + whiteValue[13] ],
      [ for(v in whitePawnPos) v + whiteValue[14] ],
      null,

   ];

   static var blackValue = [ for(w in whiteValue) -w ];
   static var startHash:Int = BoardState.start().hashCode();

   static var alive:Bool;
   static var stopping = false;
   #if sys
   static var aiThread:Thread;
   static var mainThread:Thread;
   #end
   static var thinking = false;
   static var grinding = false;

   public var evals:Int;
   public var nextStop:Int;
   var repeatStack:Array<BoardState>;
   var book:BoardMap<BoardValue>;
   var bookDepth:Int;
   var maxDepth0:Int;
   var maxDepth:Int;
   var moveCount:Int;
   var boardMem:BoardMem;
   var stackSize:Int;
   var aiIsWhite:Bool;
   var bestMove:Move;
   var lastGamma:Int;
   var brute:Bool;
   var squareValue:Array<Array<Int>>;
   var debug:Bool;
   var debugStack:Array<Move>;
   var indent:Array<String>;
   var onBestMove:Move->Void;

   var upperBound:Int;
   var lowerBound:Int;
   var gamma:Int;
   var state:BoundState;
   var board:BoardState;

   public function new(inStack:Array<BoardState>,inBook:BoardMap<BoardValue>,inLevel:Int,inBrute:Bool,inIsWhite:Bool)
   {
      book = inBook;
      evals = 0;
      nextStop = 0;
      repeatStack = inStack;
      maxDepth0 = inLevel;
      maxDepth = maxDepth0;
      bookDepth = inLevel<5 ? 5+inLevel : 100;
      moveCount = 0;

      thinking = false;
      stopping = false;
      #if sys
      if (asyncProcess)
      {
         if (aiThread==null)
         {
            mainThread = Thread.current();
            aiThread = Thread.create( threadLoop );
         }
      }
      #end
      boardMem = new BoardMem();
      stackSize = repeatStack.length;
      aiIsWhite = inIsWhite;
      lastGamma = 0;
      brute = inBrute;
      squareValue = [ for(v in sSquareValue) v==null ? null : [ for(i in v) i + Std.random(25) ] ];
      debug = false;
      indent = [];
      for(i in 0...maxDepth+1)
      {
         var dent = "";
         for(d in i...maxDepth+1)
            dent += "-";
         indent.push(dent+">");
      }
      //trace(this);
   }

   public static function stop()
   {
      stopping = true;
      grinding = false;
      //trace("stop..");
      #if sys
      if (asyncProcess)
      {
         while(thinking)
         {
            trace("thinking...");
            Sys.sleep(0.1);
         }
      }
      #end
      //trace("stopped");
   }

   public function toString() return 'Ai(' + (aiIsWhite?"white":"black") + ":" + (brute?"brute":"mtdf") + ':$maxDepth)';

   public function calcScore(forWhite:Bool,move:Move):Int
   {
      evals++;
      // draw-by-repetition?
      var board = move.newBoard;
      for(r in repeatStack)
         if (r.eq(board))
         {
            move.value = 0;
            move.stalemate = true;
            return 0;
         }

      var value = 0;
      for(p in 0...64)
         value += squareValue[ board[p] ][p];
      return forWhite ? value : -value;

      /*
      var valueOf = forWhite ? whiteValue : blackValue;
      for(p in 0...64)
         value += valueOf[ board[p] ];
      }

      return value;
      */
   }

   public function findBestMove(forWhite:Bool, board:BoardState, onResult:Move->Void) : Void
   {
      evals = 0;
      moveCount++;
      grinding = false;
      if (moveCount<bookDepth)
      {
         var hash = board.hashCode();
         if (hash==startHash || book.findBoard(null,hash,false)!=null)
         {
            var allMoves = new Array<Move>();
            for(p in 0...64)
            {
               var piece = board.getColouredPiece(p,forWhite);
               if (piece!=null)
                  piece.getMoves(BPos.fromIndex(p), board, allMoves);
            }
            if (allMoves.length==0)
            {
               onResult(null);
               return;
            }

            var bookOptions = new Array<Move>();
            for(move in allMoves)
            {
               var val = book.findBoard(null,move.newBoard.hashCode(),false);
               if (val!=null)
               {
                  var s = forWhite ? val.whiteWins : val.blackWins;
                  if (s>0)
                  {
                     move.value = s;
                     bookOptions.push(move);
                  }
               }
            }
            //if (bookOptions.length>0)
            //   trace("==== BOOK MOVE");
            if (bookOptions.length==1)
            {
               onResult(bookOptions[0]);
               return;
            }
            else if (bookOptions.length>0)
            {
               var total = 0.0;
               for(move in bookOptions)
                  total += move.value;
               var play = Math.random()*total;
               total=0;
               for(move in bookOptions)
               {
                  total += move.value;
                  if (total>=play)
                  {
                     onResult(move);
                     return;
                  }
               }
            }
         }
      }

      #if sys
      thinking = true;
      stopping = false;

      if (asyncProcess)
      {
         aiThread.sendMessage( () -> {
           if (brute)
           {
              var move = runBrute(forWhite,board);
              if (!stopping)
                 onResult(move);
           }
           else
           {
              onBestMove = onResult;
              mtdfSetup(board);
              while(grinding)
                 thinkALittle();
           }
           thinking = false;
         });
         return;
      }
      #end


      if (brute)
      {
         onResult(runBrute(forWhite,board));
      }
      else
      {
         onBestMove = onResult;
         mtdfSetup(board);
      }
   }

   function runBrute(forWhite:Bool,board:BoardState)
   {
      var t0 = haxe.Timer.stamp();
      var move = findBestMoveRec(forWhite, board, maxDepth, CHECKMATE+500);
      var best = move==null ? 0 : move.value;
      var t1 = haxe.Timer.stamp();
      trace(this + " " + best + " in " + Std.int((t1-t0)*1000) + "ms @ " + move);
      return move;
   }

   // We hypothesise the score of this node is gamma.
   // If any value is bigger than gamma, we return it as a counter example
   // If all then values are less than gamma, we return the biggest
   function bound(board:BoardState, gamma:Int, depth:Int, parentState:BoundState)
   {
      evals++;
      var state = parentState.next;
      if (state==null)
      {
         var info:BoardState = null;
         var hash = board.hashCode() | depth;
         var info = boardMem.findBoard(board,hash,false);
         // Check for stalemate first time...
         //if (info==null && !root)
         //{
         //   for(r in repeatStack)
         //      if (r.matches(board))
         //      {
         //         info = boardMem.findBoard(hash,true);
         //         info.lowerBound = info.upperBound = 0;
         //      }
         //}

         if (info!=null)
         {
            // We know at least some values is greater than gamma already
            if (info.lowerBound >= gamma)
            {
               if (debug)
                  println( debugStack.join(" ") + " " + info + ">" + gamma);
               if (!parentState.isRoot)// || bestMove!=null)
                  return info.lowerBound;
            }
            // We know at none of the values can be greater than gamma
            if (info.upperBound<gamma)
            {
               if (debug)
                  println( debugStack.join(" ") + " " + info + "<" + gamma);
               if (!parentState.isRoot)// || bestMove!=null)
                  return info.upperBound;
            }
         }
         else
         {
            info = boardMem.findBoard(board,hash,true);
            if (debug)
               info.debugMoves = debugStack.copy();
         }

         var whitesTurn = board.isWhitesTurn();

         var allMoves = new Array<Move>();
         for(p in 0...64)
         {
            var piece = board.getColouredPiece(p,whitesTurn);
            if (piece!=null)
               piece.getMoves(BPos.fromIndex(p), board, allMoves);
         }

         if (allMoves.length==0)
         {
            if (board.isKingInCheck(whitesTurn))
            {
               info.lowerBound = info.upperBound = -CHECKMATE + (maxDepth-depth);
            }
            else
            {
               if (parentState.isRoot)
                  trace("stalemate");
               info.lowerBound = info.upperBound = 0;
            }

            return info.upperBound;
         }
         for(move in allMoves)
            move.value = calcScore(whitesTurn,move);


         if (depth==0)
         {
            var best = allMoves[0].value;
            var bestMove = null;
            for(move in allMoves)
            {
               if (move.value>best)
               {
                  best = move.value;
                  bestMove = move;
               }
            }
            info.upperBound = info.lowerBound = best;
            if (debug)
            {
               info.debugMoves.push(bestMove);
               println( debugStack.join(" ") + " " + bestMove + " = " + best );
            }

            return best;
         }
         else
         {
            allMoves.sort( (a,b)-> a.value>b.value ? -1 : 1 );
            state = parentState.makeNext(info, allMoves);
         }
      }
      if (evals>nextStop)
          stopping = true;
      if (stopping)
         return 0;

      // Run through the moves, shortcutting when possible
      while(state.movePos<state.moves.length)
      {
         var move = state.moves[ state.movePos];
         if (debug)
            debugStack.push(move);
         var score = move.stalemate ? 0 : -bound(move.newBoard, 1-gamma, depth-1, state);
         if (stopping)
            return 0;
         state.movePos++;
         if (score>state.best)
         {
            state.best = score;
            if (parentState.isRoot)
               bestMove = move;
         }
         if (state.best >= gamma)
         {
            if (debug)
            {
               println(debugStack.join(" ") + ' ${state.best} >= $gamma done.');
               debugStack.pop();
            }
            break;
         }
         if (debug)
            debugStack.pop();
      }

      parentState.pop();
      if (state.best >= gamma)
         state.info.lowerBound = state.best;
      else
         state.info.upperBound = state.best;

      return state.best;
   }

   function mtdfSetup(inBoard:BoardState)
   {
      bestMove = null;
      if (!inBoard.canWin())
      {
         onBestMove(null);
         grinding = false;
         return;
      }
      boardMem = new BoardMem();
      lowerBound = -CHECKMATE-1000;
      upperBound = CHECKMATE+1000;

      gamma = lastGamma;
      state = new BoundState();
      grinding = true;
      evals = 0;
      board = inBoard;
      maxDepth = maxDepth0;
      var n = board.getPieceCount();
      if (n<=4)
         maxDepth = maxDepth + (maxDepth<5 ? 5 : maxDepth);
      else if (n<=6)
         maxDepth+=4;
      else if (n<=8)
         maxDepth+=2;
   }


   public function thinkALittle()
   {
      if (!grinding)
         return;

      stopping = false;
      nextStop = evals + 100000;
      var score = bound(board, gamma, maxDepth, state);
      if (stopping)
         return;

      if (score >= gamma)
         lowerBound = score;
      if (score<gamma)
         upperBound = score;

      gamma = (lowerBound+upperBound+1)>>1;

      // How close is enough?
      var e = 0;
      grinding = (lowerBound<upperBound + e);
      if (!grinding)
      {
         lastGamma = lowerBound;
         var b = onBestMove;
         onBestMove = null;
         b(bestMove);
      }
   }



   #if cpp
   static function threadLoop()
   {
      while(true)
      {
         var func = Thread.readMessage(true);
         if (func==null)
            break;
         func();
      }
   }
   #end

   // Value of board = calc(board) for terminal node,
   // Otherwise, value of the best move.
   // The value of a move is negative of the opponents value of the board after the move has been made
   // Since the maximization is over moves, once the oponents board value gets too high, we can discard the move
   // That is, if the current best move is B, then if the
   //   "negative of the opponents value of the board" < B  -> move is not optimal
   //  -> opponents value of the board > -B  -> move is not optimal
   public function findBestMoveRec(forWhite:Bool, board:BoardState, depth:Int, earlyStop:Int) : Move
   {
      var allMoves = new Array<Move>();
      for(p in 0...64)
      {
         var piece = board.getColouredPiece(p,forWhite);
         if (piece!=null)
            piece.getMoves(BPos.fromIndex(p), board, allMoves);
      }
      if (allMoves.length==0)
         return null;

      // Score each move...
      for(m in allMoves)
         m.value = calcScore(forWhite,m);

      var best:Move = null;
      if (depth==0)
      {
         var best = allMoves[0];
         for(m in allMoves)
         {
            if (m.value>best.value)
               best = m;
         }
         if (debug)
            println( debugStack.join(" ") + " " + best + " = " + best.value );
         return best;
      }
      else
      {
         // Sort based on best initial move...
         //allMoves.sort( (a,b) -> a.value>b.value ? -1 : 1 );


         // Judge the move by the negative of the opponents response
         var bestReply:Int = -CHECKMATE-1000;
         for(m in allMoves)
         {
            // If stalemate and no more moves can be made
            if (!m.stalemate)
            {
               if (debug)
                  debugStack.push(m);
               var reply = findBestMoveRec(!forWhite,m.newBoard,depth-1,-bestReply);
               // Stalemate or Win
               if (reply==null)
               {
                  // We always win - look no furthur
                  if (m.newBoard.isKingInCheck(!forWhite))
                  {
                     m.value = CHECKMATE-depth;
                     if (debug)
                     {
                        println(debugStack.join(" ") + " " + m.value + (m.value>=earlyStop ? " done":"") );
                        debugStack.pop();
                     }
                     return m;
                  }
                  // Stalemate
                  m.value = STALEMATE;
               }
               else
               {
                  // Value from our point of view is the opposite of thier point of view
                  m.value = -reply.value;
               }
               if (debug)
               {
                  println(debugStack.join(" ") + " " + m.value + (m.value>=earlyStop ? " done":"") );
                  debugStack.pop();
               }
            }


            if (best==null || m.value>best.value)
            {
               best = m;
               bestReply = m.value;
               // The opponents moves can only get better from here, and it is already bad enough for us
               if (m.value>=earlyStop)
                  return m;
            }
         }
      }
      return best;
   }

   function println(s)
   {
      #if sys
      Sys.println(s);
      #else
      trace(s);
      #end
   }
}
