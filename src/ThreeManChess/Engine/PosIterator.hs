-- {-# LANGUAGE RecursiveDo #-}

module ThreeManChess.Engine.PosIterator where

import ThreeManChess.Engine.Pos
import ThreeManChess.Engine.Color

allFilesBetweenRIncl :: File -> File -> [File]
allFilesBetweenRIncl x y = minus y : (if minus y == x then [] else allFilesBetweenRIncl x (minus y))
allFilesFrom :: File -> [File]
allFilesFrom x =  allFilesBetweenRIncl x x
-- allFilesFrom x =
--   mdo
--     xs <- [(minus x)]
--     xs <- if ((minus (head xs))==x) then xs else ((minus (head xs)):xs)
--     x:xs
allFilesFromZero :: [File]
allFilesFromZero = allFilesFrom (File White (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf))

allSegmentFiles :: Color -> [File]
allSegmentFiles c = filter ((c==).segmColor) allFilesFromZero

allRanks :: [Rank]
allRanks = ranks
allPos2D :: [[Pos]]
allPos2D = fmap (\r -> fmap
                       (\f -> (r,f))
                       (allFilesFrom $ fileFromInt 0)) allRanks
allPos :: [Pos]
allPos = concat allPos2D
