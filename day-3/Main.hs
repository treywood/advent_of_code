module Main where

import Data.List (elemIndex, intersect)
import Data.List.Split (chunksOf)
import Text.Megaparsec
import Text.Megaparsec.Char
import Utils (Config (..), run)

priorities :: [Char]
priorities = ['a' .. 'z'] ++ ['A' .. 'Z']

main :: IO ()
main =
    run $
        Config
            { parser = sepEndBy (some alphaNumChar) newline
            , run1 = part1
            , run2 = part2
            }

part1 :: [String] -> Int
part1 = sum . (map grade)
  where
    grade :: String -> Int
    grade pack = ((maybe 0 (+ 1)) . (`elemIndex` priorities)) $ head (intersect h1 h2)
      where
        mid = (length pack) `div` 2
        (h1, h2) = (take mid pack, drop mid pack)

part2 :: [String] -> Int
part2 = sum . (map grade) . (chunksOf 3)
  where
    grade :: [String] -> Int
    grade (g1 : gs) = (maybe 0 (+ 1) . (`elemIndex` priorities)) badge
      where
        badge = (last . map head) $ scanl intersect g1 gs
    grade _ = 0

-- main :: IO ()
-- main = run $ do
--     input <- getInput
--     let groups = chunksOf 3 (lines input)
--     return $ sum (map prioritize groups)
--   where
--     prioritize :: [String] -> Int
--     prioritize [g1, g2, g3] = score badge
--       where
--         badge = head $ intersect (intersect g1 g2) g3
--         score :: Char -> Int
--         score c = maybe 0 (+ 1) (c `elemIndex` priorities)
--     prioritize _ = 0
