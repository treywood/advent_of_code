{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Main where

import Data.Function ((&))
import Data.List (sortOn)
import Data.Map (Map, elems)
import Data.Map qualified as M
import Data.Maybe (fromMaybe)
import Data.Void
import Text.Megaparsec (Parsec, oneOf, runParser, sepBy, some)
import Text.Megaparsec.Char (alphaNumChar, digitChar, space, string)
import Text.Megaparsec.Error (errorBundlePretty)
import Utils

type Monkeys = Map Int Monkey

data Monkey = Monkey
    { index :: Int
    , items :: [Int]
    , operation :: Expr
    , divisor :: Int
    , nexts :: (Int, Int)
    , activity :: Int
    }
    deriving (Show)

data Expr = Old | Num Int | Bin Expr Char Expr
    deriving (Show)

runExpr :: Expr -> Int -> Int
runExpr Old x = x
runExpr (Num y) _ = y
runExpr (Bin e1 op e2) x = case op of
    '*' -> ev1 * ev2
    '+' -> ev1 + ev2
    '-' -> ev1 + ev2
    _ -> undefined
  where
    ev1 = (runExpr e1) x
    ev2 = (runExpr e2) x

main :: IO ()
main = do
    input <- getInput
    case runParser (sepBy parseMonkey space) "" input of
        Right monkeys -> putStrLn $ show (monkeyBusiness monkeys)
        Left err -> putStrLn $ errorBundlePretty err
  where
    monkeyBusiness monkeys = product $ (take 2) $ (sortOn negate) $ (map activity monkeys')
      where
        monkeys' = elems $ runRounds 10_000 (M.fromList (zip [0 ..] monkeys))

    parseMonkey :: Parsec Void String Monkey
    parseMonkey = do
        _ <- string "Monkey "
        index <- fmap read (some digitChar)
        string ":" >> space
        items <- parseItems
        operation <- parseExpr
        divisor <- parseDivisor
        nexts <- parseNexts
        return $ Monkey index items operation divisor nexts 0
      where
        parseItems :: Parsec Void String [Int]
        parseItems = do
            _ <- space >> string "Starting items:" >> space
            items <- sepBy (fmap read (some digitChar)) (string "," >> space)
            return items

        parseExpr :: Parsec Void String Expr
        parseExpr = do
            _ <- space >> string "Operation: new =" >> space
            w1 <- fmap wordToExpr (some alphaNumChar)
            space
            op <- oneOf ['*', '+', '-']
            space
            w2 <- fmap wordToExpr (some alphaNumChar)
            return $ Bin w1 op w2
          where
            wordToExpr "old" = Old
            wordToExpr x = Num (read x)

        parseDivisor :: Parsec Void String Int
        parseDivisor = do
            _ <- space >> string "Test: divisible by" >> space
            den <- fmap read (some digitChar)
            return den

        parseNexts :: Parsec Void String (Int, Int)
        parseNexts = do
            _ <- space >> string "If true: throw to monkey" >> space
            ifTrue <- fmap read (some digitChar)
            _ <- space >> string "If false: throw to monkey" >> space
            ifFalse <- fmap read (some digitChar)
            return (ifTrue, ifFalse)

    runRounds :: Int -> Monkeys -> Monkeys
    runRounds n monkeys = (iterate runRound monkeys) !! n

    divisors :: Monkeys -> [Int]
    divisors = (map divisor) . elems

    fixNum monkeys x = x `mod` (product (divisors monkeys))

    runRound :: Monkeys -> Monkeys
    runRound ms = foldl runMonkey ms (M.keys ms)
      where
        runMonkey :: Monkeys -> Int -> Monkeys
        runMonkey monkeys i =
            fromMaybe monkeys (fmap update $ M.lookup i monkeys)
          where
            update m =
                (foldl (processItem m) monkeys m.items)
                    & (M.insert m.index updatedMonkey)
              where
                updatedMonkey = m{items = [], activity = m.activity + (length m.items)}

        processItem :: Monkey -> Monkeys -> Int -> Monkeys
        processItem monkey monkeys item = M.update updateTarget tnum monkeys
          where
            newItem = fixNum monkeys (runExpr monkey.operation item)
            tnum =
                if newItem `mod` monkey.divisor == 0
                    then fst monkey.nexts
                    else snd monkey.nexts

            updateTarget :: Monkey -> Maybe Monkey
            updateTarget m = Just $ m{items = m.items ++ [newItem]}