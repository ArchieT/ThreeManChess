{-# Language DuplicateRecordFields,GADTs,RankNTypes,ScopedTypeVariables,ExistentialQuantification,
             LiberalTypeSynonyms,NamedFieldPuns,RecordWildCards,TypeFamilies,PatternSynonyms,FunctionalDependencies,
             FlexibleInstances,InstanceSigs,TypeFamilyDependencies,DataKinds,PolyKinds,ConstraintKinds,KindSignatures,
             TypeApplications,ImplicitParams,ImpredicativeTypes,PartialTypeSignatures,NamedWildCards #-}
module ThreeManChess.Engine.Possibilities where

import Control.Exception
-- import Data.Data
import Data.Maybe
import ThreeManChess.Engine.Pos
import ThreeManChess.Engine.Color
-- import ThreeManChess.Engine.Figure
-- import ThreeManChess.Engine.FigType
import ThreeManChess.Engine.Moats
import ThreeManChess.Engine.Directions


class (Reversable a, Eq a-- , Ord a
      ) => LinearDirection a where
  tailRankInvol :: LinearVec a -> Maybe (Either (Rank -> LinearVec a) (LinearVec a))
  addOne :: a -> Pos -> Maybe Pos
instance LinearDirection RankwiseDirection where
  tailRankInvol (LinearVec _ Once) = Nothing
  tailRankInvol (LinearVec Inwards (OnceMore c)) = Just $ Left (\x -> LinearVec (case x of MostInner -> Outwards
                                                                                           _ -> Inwards) c)
  tailRankInvol (LinearVec Outwards (OnceMore c)) = Just $ Right (LinearVec Outwards c)
  addOne Inwards (MostInner, file) = Just (MostInner, opposite file)
  addOne Inwards (rank, file) = Just (inw rank, file)
  addOne Outwards (rank, file) =
    do { o <- out rank;
         return (o, file) }
instance LinearDirection FilewiseDirection where
  tailRankInvol (LinearVec _ Once) = Nothing
  tailRankInvol (LinearVec d (OnceMore c)) = Just $ Right (LinearVec d c)
  addOne w (rank, file) = Just (rank, filewiseInc w file)
instance LinearDirection DiagonalDirection where
  tailRankInvol (LinearVec _ Once) = Nothing
  tailRankInvol (LinearVec (DiagonalDirection Inwards f) (OnceMore c)) =
    Just $ Left (\x -> LinearVec (case x of MostInner -> DiagonalDirection Outwards (rever f)
                                            _ -> DiagonalDirection Inwards f) c)
  tailRankInvol (LinearVec d (OnceMore c)) = Just $ Right (LinearVec d c)
  addOne (DiagonalDirection Inwards p) (MostInner, File c (SegmentEight q r)) =
    Just
    (MostInner,
     case p of
       Pluswards ->
         case q of
           SegmentQuarter SecondHalf SecondHalf ->
             File{segmColor=prev c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter FirstHalf FirstHalf,quarterHalf=r}}
           SegmentQuarter SecondHalf FirstHalf ->
             File{segmColor=next c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter SecondHalf SecondHalf, quarterHalf=r}}
           SegmentQuarter FirstHalf SecondHalf ->
             File{segmColor=next c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter SecondHalf FirstHalf, quarterHalf=r}}
           SegmentQuarter FirstHalf FirstHalf ->
             File{segmColor=next c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter FirstHalf SecondHalf, quarterHalf=r}}
       Minuswards ->
         case q of
           SegmentQuarter FirstHalf FirstHalf ->
             File{segmColor=next c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter SecondHalf SecondHalf,quarterHalf=r}}
           SegmentQuarter SecondHalf SecondHalf ->
             File{segmColor=prev c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter SecondHalf FirstHalf, quarterHalf=r}}
           SegmentQuarter SecondHalf FirstHalf ->
             File{segmColor=prev c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter FirstHalf SecondHalf, quarterHalf=r}}
           SegmentQuarter FirstHalf SecondHalf ->
             File{segmColor=prev c,
                  colorSegmFile=SegmentEight{segmentQuarter=SegmentQuarter FirstHalf FirstHalf, quarterHalf=r}}
    )
  addOne (DiagonalDirection Inwards p) (rank, file) = Just (inw rank, filewiseInc p file)
  addOne (DiagonalDirection Outwards p) (rank, file) =
    do { o <- out rank; return (o, filewiseInc p file)}
class (LinearDirection a) => StraightDirection a where
  orientation :: a -> Orientation
instance StraightDirection RankwiseDirection where
  orientation _ = Rankwise
instance StraightDirection FilewiseDirection where
  orientation _ = Filewise

class (Eq a-- , Read a, Show a
      ) => Vec a where
  reverMaybe :: a -> Maybe a
  add :: Pos -> a -> Maybe Pos
  emptiesFrom :: Pos -> a -> Maybe [Pos]
--  moats :: Pos -> a -> [MoatLocalization]
class (Eq a, Show a -- , Read a
      ) => InterfaceVecEBC a where
  reverMaybeEBC :: a -> Maybe a
  addEBC :: Pos -> a -> Maybe Pos
  flipAddEBC :: a -> Pos -> Maybe Pos
  addEBC = flip flipAddEBC
  flipEmptiesFromEBC :: a -> Pos -> Maybe [Pos]
  emptiesFromEBC :: Pos -> a -> Maybe [Pos]
  emptiesFromEBC = flip flipEmptiesFromEBC
  moats :: Pos -> a -> [MoatLocalization]
--  moatsEBC :: Pos -> a -> [MoatLocalization]
--  flipMoatsEBC :: a -> Pos -> [MoatLocalization]
--  moatsEBC = flip flipMoatsEBC
-- data VecC = forall a . Vec a => MkVecC a
data VecC where
  MkVecC :: Vec a => a -> VecC
data VecCC where
  MkLinearVecCC :: LinearDirection a => LinearVec a -> VecCC
--  MkStraightVecCC :: StraightDirection a => LinearVec a -> VecCC
  MkKnightVecCC :: KnightVec -> VecCC
  MkCastlingVecCC :: Castling -> VecCC
  MkPawnJumpByTwoVecCC :: PawnJumpByTwo -> VecCC

-- unboxVecCCLinear :: (LinearDirection a) => ('MkLinearVecCC (LinearVec a)) -> Maybe (LinearVec a)
-- unboxVecCCLinear (MkLinearVecCC a) = Just a
data VecEBC where
  MkLinearVecEBC :: LinearVecEBC -> VecEBC
  MkKnightVecEBC :: KnightVec -> VecEBC
  MkCastlingVecEBC :: Castling -> VecEBC
  MkPawnJumpByTwoVecEBC :: PawnJumpByTwo -> VecEBC
instance Show VecEBC where
  show (MkLinearVecEBC x) = "an EBC-contained linear vec of " ++ show x
  show (MkKnightVecEBC x) = "an EBC-contained knight vec of " ++ show x
  show (MkCastlingVecEBC x) = "an EBC-contained castling vec of " ++ show x
  show (MkPawnJumpByTwoVecEBC x) = "an EBC-contained pawn jump vec of " ++ show x
data StraightVecEBC where
  MkRankwiseVecEBC :: LinearVec RankwiseDirection -> StraightVecEBC
  MkFilewiseVecEBC :: LinearVec FilewiseDirection -> StraightVecEBC
data LinearVecEBC where
  MkDiagonalVecEBC :: LinearVec DiagonalDirection -> LinearVecEBC
  MkStraightVecEBC :: StraightVecEBC -> LinearVecEBC
instance Show LinearVecEBC where
  show (MkDiagonalVecEBC x) = "an EBC-contained diagonal vec of " ++ show x
  show (MkStraightVecEBC x) = "an EBC-contained straight vec of " ++ show x
instance Show StraightVecEBC where
  show (MkFilewiseVecEBC x) = "an EBC-contained filewise vec of " ++ show x
  show (MkRankwiseVecEBC x) = "an EBC-contained rankwise vec of " ++ show x
instance (Show a) => Show (LinearVec a) where
  show (LinearVec b c) = "a LinearVec of count " ++ show c ++ " and direction " ++ show b
instance InterfaceVecEBC StraightVecEBC where
  reverMaybeEBC (MkRankwiseVecEBC x) = MkRankwiseVecEBC <$> reverMaybe x
  reverMaybeEBC (MkFilewiseVecEBC x) = MkFilewiseVecEBC <$> reverMaybe x
  flipAddEBC (MkRankwiseVecEBC x) = flip add x
  flipAddEBC (MkFilewiseVecEBC x) = flip add x
  flipEmptiesFromEBC (MkRankwiseVecEBC x) = flip emptiesFrom x
  flipEmptiesFromEBC (MkFilewiseVecEBC x) = flip emptiesFrom x
  moats _ (MkRankwiseVecEBC _) = []
  moats p (MkFilewiseVecEBC x) = moatsFilewise p x
--  flipMoatsEBC (MkRankwiseVecEBC x) = flip moats x
--  flipMoatsEBC (MkFilewiseVecEBC x) = flip moats x
instance InterfaceVecEBC LinearVecEBC where
  reverMaybeEBC (MkStraightVecEBC x) = MkStraightVecEBC <$> reverMaybeEBC x
  reverMaybeEBC (MkDiagonalVecEBC x) = MkDiagonalVecEBC <$> reverMaybe x
  flipAddEBC (MkStraightVecEBC x) = flipAddEBC x
  flipAddEBC (MkDiagonalVecEBC x) = flip add x
  flipEmptiesFromEBC (MkStraightVecEBC x) = flipEmptiesFromEBC x
  flipEmptiesFromEBC (MkDiagonalVecEBC x) = flip emptiesFrom x
--  flipMoatsEBC (MkStraightVecEBC x) = flip moats x
--  flipMoatsEBC (MkDiagonalVecEBC x) = flip moats x
  moats a (MkDiagonalVecEBC x) = moatsDiagonal a x
  moats a (MkStraightVecEBC x) = moats a x
instance InterfaceVecEBC VecEBC where
  reverMaybeEBC (MkLinearVecEBC x) = MkLinearVecEBC <$> reverMaybeEBC x
  reverMaybeEBC (MkKnightVecEBC x) = MkKnightVecEBC <$> reverMaybe x
  reverMaybeEBC (MkCastlingVecEBC x) = MkCastlingVecEBC <$> reverMaybe x
  reverMaybeEBC (MkPawnJumpByTwoVecEBC x) = MkPawnJumpByTwoVecEBC <$> reverMaybe x
  flipAddEBC (MkLinearVecEBC x) = flipAddEBC x
  flipAddEBC (MkKnightVecEBC x) = flip add x
  flipAddEBC (MkCastlingVecEBC x) = flip add x
  flipAddEBC (MkPawnJumpByTwoVecEBC x) = flip add x
  flipEmptiesFromEBC (MkLinearVecEBC x) = flipEmptiesFromEBC x
  flipEmptiesFromEBC (MkKnightVecEBC x) = flip emptiesFrom x
  flipEmptiesFromEBC (MkCastlingVecEBC x) = flip emptiesFrom x
  flipEmptiesFromEBC (MkPawnJumpByTwoVecEBC x) = flip emptiesFrom x
  moats _ (MkCastlingVecEBC _) = []
  moats _ (MkPawnJumpByTwoVecEBC _) = []
  moats p (MkLinearVecEBC x) = moats p x
  moats p (MkKnightVecEBC x) = moatsKnight p x
  -- flipMoatsEBC (MkLinearVecEBC x) = flip moats x
  -- flipMoatsEBC (MkKnightVecEBC x) = flip moats x
  -- flipMoatsEBC (MkCastlingVecEBC x) = flip moats x
  -- flipMoatsEBC (MkPawnJumpByTwoVecEBC x) = flip moats x
_xrqnmv :: SegmentEight -> SegmentEight -> Maybe (Rank, FilewiseDirection)
_xrqnmv (SegmentEight (SegmentQuarter SecondHalf SecondHalf) FirstHalf) (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf) =
  Just (SecondOuter, Pluswards)
_xrqnmv (SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf) (SegmentEight (SegmentQuarter FirstHalf FirstHalf) SecondHalf) =
  Just (SecondOuter, Pluswards)
_xrqnmv (SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf) (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf) =
  Just (MiddleOuter, Pluswards)
_xrqnmv (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf) (SegmentEight (SegmentQuarter SecondHalf SecondHalf) FirstHalf) =
  Just (SecondOuter, Minuswards)
_xrqnmv (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf) (SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf) =
  Just (MiddleOuter, Minuswards)
_xrqnmv (SegmentEight (SegmentQuarter FirstHalf FirstHalf) SecondHalf) (SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf) =
  Just (SecondOuter, Minuswards)
_xrqnmv _ _ = Nothing
_xoreq :: Pos -> Pos -> Maybe Bool
_xoreq (fr,File _ fs) (tr, File _ ts)
  | tr>MiddleOuter && fr>MiddleOuter = Nothing
  | otherwise =
      do (w,_) <- _xrqnmv fs ts;
         Just $ case fr of
                  MostOuter -> tr==w
                  _ -> fr==w && tr==MostOuter
moatKnight :: Pos -> KnightVec -> Maybe MoatLocalization
moatKnight f v = do
  to <- add f v;
  (_,wd) <- _xrqnmv (colorSegmFile (file f)) (colorSegmFile (file to));
  xo <- _xoreq f to;
  if xo then Just (onDirecLoc wd (segmColor (file f))) else Nothing
instance Eq StraightVecEBC where
  (MkRankwiseVecEBC x) == (MkRankwiseVecEBC y) = x==y
  (MkFilewiseVecEBC x) == (MkFilewiseVecEBC y) = x==y
  _ == _ = False
instance Eq LinearVecEBC where
  (MkDiagonalVecEBC x) == (MkDiagonalVecEBC y) = x==y
  (MkStraightVecEBC x) == (MkStraightVecEBC y) = x==y
  _ == _ = False
instance Eq VecEBC where
  (MkLinearVecEBC x) == (MkLinearVecEBC y) = x==y
  (MkKnightVecEBC x) == (MkKnightVecEBC y) = x==y
  (MkCastlingVecEBC x) == (MkCastlingVecEBC y) = x==y
  (MkPawnJumpByTwoVecEBC x) == (MkPawnJumpByTwoVecEBC y) = x==y
  _ == _ = False

class (Vec a, Reversable a) => ReversableVec a
-- instance (Reversable a) => Vec (ReversableVec a) where
--   reverMaybe x = Just $ rever x
passTimes :: (a -> a) -> Count -> a -> a
passTimes f Once a = f a
passTimes f (OnceMore c) a = passTimes f c (f a)
data Castling = QueensideCastling | KingsideCastling deriving Show -- deriving (Vec)
rookGoesInCastling :: Castling -> SegmentEight
rookGoesInCastling ca = fromJust $ (case ca of
                                      KingsideCastling -> plusEight
                                      QueensideCastling -> minusEight) kfm
rookTo :: Castling -> Color -> Pos
rookTo ca co = (MostOuter, File co $ rookGoesInCastling ca)
rookFrom :: Castling -> Color -> Pos
rookFrom QueensideCastling co = (MostOuter, File co zeroSegmentEight)
rookFrom KingsideCastling co = (MostOuter, File co sevenSegmentEight)
emptiesForCastling :: Castling -> [SegmentEight]
emptiesForCastling KingsideCastling = [fromJust $ plusEight kfm, passTimes (fromJust.plusEight) (OnceMore Once) kfm]
emptiesForCastling QueensideCastling = [fromJust $ minusEight kfm, passTimes (fromJust.minusEight) (OnceMore Once) kfm,
                                        passTimes (fromJust.minusEight) (OnceMore $ OnceMore Once) kfm]
instance Eq Castling where
  QueensideCastling == QueensideCastling = True
  QueensideCastling == KingsideCastling = False
  KingsideCastling == QueensideCastling = False
  KingsideCastling == KingsideCastling = True
instance Vec Castling where
  reverMaybe _ = Nothing
  add (MostOuter, File c (SegmentEight (SegmentQuarter SecondHalf FirstHalf) FirstHalf)) QueensideCastling =
    Just (MostOuter, File{segmColor=c,
                             colorSegmFile=SegmentEight{
                                segmentQuarter=SegmentQuarter {
                                    half=FirstHalf, halfQuarter=SecondHalf}, quarterHalf=FirstHalf}})
  add _ QueensideCastling = undefined
  add (MostOuter, File c (SegmentEight (SegmentQuarter SecondHalf FirstHalf) FirstHalf)) KingsideCastling =
    Just (MostOuter, File{segmColor=c,
                             colorSegmFile=SegmentEight{
                                segmentQuarter=SegmentQuarter {
                                    half=SecondHalf, halfQuarter=SecondHalf}, quarterHalf=FirstHalf}})
  add _ KingsideCastling = undefined
  emptiesFrom from v = Just $ assert ( colorSegmFile (file from) == kfm )
                       (assert ( rank from == MostOuter ) (fmap (\x -> (MostOuter,File (segmColor $ file from) x))
                                                            (emptiesForCastling v)))
data PawnJumpByTwo = PawnJumpByTwo deriving Show --deriving (Vec)
enPassantField :: File -> Pos
enPassantField f = (MiddleOuter, f)
enPassantFieldPos :: Pos -> Maybe Pos
enPassantFieldPos (SecondOuter,f) = Just $ enPassantField f
enPassantFieldPos _ = Nothing
instance Eq PawnJumpByTwo where
  PawnJumpByTwo == PawnJumpByTwo = True
instance Vec PawnJumpByTwo where
  reverMaybe PawnJumpByTwo = Nothing
  add (SecondOuter, f) PawnJumpByTwo = Just (MiddleInner, f)
  add _ PawnJumpByTwo = Nothing
  emptiesFrom from PawnJumpByTwo = do { e <- enPassantFieldPos from; t <- add from PawnJumpByTwo; Just [e, t] }
-- data (LinearDirection a) => LinearVec a = LinearVec a Count --deriving (Ord)
data LinearVec a where
  LinearVec :: LinearDirection a => a -> Count -> LinearVec a
data LinearVecC = forall a . LinearDirection a => MkLinearVecC (LinearVec a)
-- data LinearVecC where
--   MkLinearVecC :: LinearDirection a => a -> LinearVecC (LinearVec a)
data StraightVecC = forall a . StraightDirection a => MkStraightVecC (LinearVec a)
-- data StraightVecC where
--   MkStraightVecC :: StraightDirection a => a -> StraightVecC (LinearVec a)
direction :: (LinearDirection a) => LinearVec a -> a
direction (LinearVec d _) = d
count :: (LinearDirection a) => LinearVec a -> Count
count (LinearVec _ c) = c
-- instance (LinearDirection a) => Ord (LinearVec a)
instance (LinearDirection a) => ReversableVec (LinearVec a)
instance (LinearDirection a) => Reversable (LinearVec a) where
  rever (LinearVec d n) = LinearVec (rever d) n
instance (LinearDirection t) => Eq (LinearVec t) where
  (LinearVec a c) == (LinearVec b d) = (a == b) && (c == d)
instance (LinearDirection a) => Vec (LinearVec a) where
  reverMaybe x = Just $ rever x
  add p (LinearVec d Once) = addOne d p
  add p m = foldl _addMaybe (Just p) (unitsInvolRank m (rank p))
  emptiesFrom _ (LinearVec _ Once) = Just []
  emptiesFrom p (LinearVec d c) =  addOne d p >>= (\pp -> Just $ pp:_emptiesFromMust pp (LinearVec d c))

zeroSegmentEight :: SegmentEight
zeroSegmentEight = SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf
sevenSegmentEight :: SegmentEight
sevenSegmentEight = SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf
moatFilewise :: Pos -> FilewiseDirection -> Maybe MoatLocalization
moatFilewise (MostOuter, File col s) d
  | s==zeroSegmentEight && d==Minuswards = Just $ onDirecLoc Minuswards col
  | s==sevenSegmentEight && d==Pluswards = Just $ onDirecLoc Pluswards col
  | otherwise = Nothing
moatFilewise _ _ = Nothing
moatsFilewise :: Pos -> LinearVec FilewiseDirection -> [MoatLocalization]
moatsFilewise p (LinearVec d Once) = maybeToList $ moatFilewise p d
moatsFilewise p (LinearVec d (OnceMore c)) = maybeToList (moatFilewise p d) ++ moatsFilewise p (LinearVec d c)
moatsDiagonal :: Pos -> LinearVec DiagonalDirection -> [MoatLocalization]
moatsDiagonal p x = maybeToList $ moatDiagonal p x
moatsKnight :: Pos -> KnightVec -> [MoatLocalization]
moatsKnight p x = maybeToList $ moatKnight p x

moatDiagonal :: Pos -> LinearVec DiagonalDirection -> Maybe MoatLocalization
moatDiagonal (MostOuter, File col (SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf))
  (LinearVec (DiagonalDirection Inwards Pluswards) _) = Just $ onDirecLoc Pluswards col
moatDiagonal (MostOuter, File col (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf))
  (LinearVec (DiagonalDirection Inwards Minuswards) _) = Just $ onDirecLoc Minuswards col
moatDiagonal f (LinearVec (DiagonalDirection Outwards Pluswards) c) =
  do tove <- add f (LinearVec (DiagonalDirection Outwards Pluswards) c);
     if rank tove == MostOuter then
       case file tove of
         File col (SegmentEight (SegmentQuarter FirstHalf FirstHalf) FirstHalf) -> Just $ onDirecLoc Minuswards col
         _ -> Nothing
     else Nothing
moatDiagonal f (LinearVec (DiagonalDirection Outwards Minuswards) c) =
  do tove <- add f (LinearVec (DiagonalDirection Outwards Minuswards) c);
     if rank tove == MostOuter then
       case file tove of
         File col (SegmentEight (SegmentQuarter SecondHalf SecondHalf) SecondHalf) -> Just $ onDirecLoc Pluswards col
         _ -> Nothing
     else Nothing
moatDiagonal _ _ = Nothing
_emptiesFromMust :: (LinearDirection a) => Pos -> LinearVec a -> [Pos]
_emptiesFromMust _ (LinearVec _ Once) = []
_emptiesFromMust pp (LinearVec d c) = fromJust $ emptiesFrom pp (fromJust (tailInvolRank (LinearVec d c)) (rank pp))
_addMaybe :: (LinearDirection a) => Maybe Pos -> LinearVec a -> Maybe Pos
_addMaybe p m = do { jp <- p;
                     add jp m;}
data KnightVec = KnightVec RankwiseDirection FilewiseDirection Orientation deriving Show -- Orientation :: twice
-- instance Ord KnightVec
instance Eq KnightVec where
  (KnightVec r f o) == (KnightVec rr ff oo) = (r==rr)&&(f==ff)&&(o==oo)
instance ReversableVec KnightVec
instance Reversable KnightVec where
  rever (KnightVec r f orient) = KnightVec (rever r) (rever f) orient
instance Vec KnightVec where
  emptiesFrom _ _ = Just []
  reverMaybe x = Just $ rever x
-- add KnightMove {rankwise=r, filewise=f, twice=t} x =
--   do { fl <- add UnitStraightMove {direction=case t of Rankwise -> r; Filewise -> f} x;
--        return add UnitStraightMove {direction=case t of Filewise -> r; Rankwise -> f} fl }
  add x (KnightVec r f t) =
    do { x <- addOne r x;
         x <- addOne f x;
         x <- (case t of Rankwise -> addOne r; Filewise -> addOne f) x;
         return x;}

allPossibleKnightVecs :: [KnightVec]
allPossibleKnightVecs = [KnightVec Inwards Pluswards Rankwise, KnightVec Inwards Pluswards Filewise,
                         KnightVec Inwards Minuswards Rankwise, KnightVec Inwards Minuswards Filewise,
                         KnightVec Outwards Pluswards Rankwise, KnightVec Outwards Pluswards Filewise,
                         KnightVec Outwards Minuswards Rankwise, KnightVec Outwards Minuswards Filewise]
fromToKnight :: Pos -> Pos -> [KnightVec]
fromToKnight a b = filter (maybe False (b==) . add a) allPossibleKnightVecs
-- add LinearMove m p = foldl add p $ unitsInvolRank m
-- class StraightVec
-- class (StraightDirection a) => StraightVec a
-- instance (StraightDirection a) => StraightVec (LinearVec a)
-- type (StraightDirection a) => StraightVec a = LinearVec a

mkveccFromLinearvecc :: LinearVecC -> VecC
mkveccFromLinearvecc (MkLinearVecC a) = MkVecC a
-- linearVecUnboxingFromVecc :: (LinearDirection a) => VecC -> Maybe (LinearVec a)
-- linearVecUnboxingFromVecc (MkVecC (LinearVec a b)) = Just $ LinearVec a b
-- mklinearveccFromVecc :: (Linear)
-- mklinearveccFromVecc (MkVecC x) = MkLinearVecC x

-- type StraightMove = LinearMove { direction :: StraightDirection }
-- type DiagonalMove = LinearMove { direction :: DiagonalDirection }
-- type RankwiseMove = StraightMove { direction :: RankwiseDirection }
-- type FilewiseMove = StraightMove { direction :: FilewiseDirection }
-- data RankInvolMove = RankwiseMove | DiagonalMove deriving (Eq, Ord, Read, Show, LinearMove)
-- type UnitLinearMove = LinearMove { count :: Once }
-- type UnitStraightMove = UnitLinearMove { direction :: StraightDirection }
-- type UnitDiagonalMove = UnitLinearMove { direction :: DiagonalDirection }
-- type UnitRankwiseMove = UnitStraightMove { direction :: RankwiseDirection }
-- type UnitFilewiseMove = UnitStraightMove { direction :: FilewiseDirection }
-- newtype UnitRankInvolMove = UnitRankwiseMove | UnitDiagonalMove
--                           deriving (Eq, Ord, Read, Show, UnitLinearMove, RankInvolMove)
headLinear :: (LinearDirection a) => LinearVec a -> LinearVec a --UnitLinearVec
headLinear (LinearVec d _) = LinearVec d Once
tailFilewise :: LinearVec FilewiseDirection -> Maybe (LinearVec FilewiseDirection)
tailFilewise (LinearVec _ Once) = Nothing
tailFilewise (LinearVec d (OnceMore c)) = Just (LinearVec d c)
-- units :: LinearMove -> Either (Rank -> [UnitRankInvolMove]) [UnitLinearMove]
cons :: a -> ([a] -> [a])
cons a as = a:as
units :: (LinearDirection a) => LinearVec a -> Either (Rank -> [LinearVec a]) [LinearVec a]
units x = let
  {t = tailRankInvol x;
   h = headLinear x} in
    case t of
      Just (Right justTail) -> let ur = units justTail in case ur of
        Right justRestOfUnits -> Right $ h:justRestOfUnits
        _ -> undefined
      Just (Left tailByRank) ->
        Left (\rankArg ->
                let ul = units $ tailByRank rankArg in case ul of
                  Right right -> h:right
                  Left restByRank -> cons h $ restByRank rankArg)
      Nothing -> Right []
-- unitsInvolRank :: LinearMove -> Rank -> [UnitLinearMove]
unitsInvolRank :: (LinearDirection a) => LinearVec a -> Rank -> [LinearVec a]
unitsInvolRank x = either id const $ units x
tailInvolRank :: (LinearDirection a) => LinearVec a -> Maybe (Rank -> LinearVec a)
-- tailInvolRank x = do { f <- tailRankInvol x; return $ either id const f }
tailInvolRank x = either id const <$> tailRankInvol x
-- fromToVecsByFig :: FigType -> Pos -> Pos -> [Vec a]
-- fromToVecsByFig Queen a b = (fromToVecs Rook a b) ++ (fromToVecs Bishop a b)
-- fromToVecsByFig Rook
-- fromToVecsByFig Bishop
rankOnceWards :: RankwiseDirection -> Rank -> Maybe Rank
rankOnceWards Inwards = Just . inw
rankOnceWards Outwards = out
fromToRanks :: (Rank, Rank) -> Maybe (LinearVec RankwiseDirection)
fromToRanks (a,b) = case compare a b of
  EQ -> Nothing
  co -> Just $ let { d = case co of LT -> Inwards; GT -> Outwards } in
                 case do { row <- rankOnceWards d a;
                           curry fromToRanks row b;} of
                   Nothing -> LinearVec d Once
                   Just (LinearVec d om) -> LinearVec d (OnceMore om)
fromToRankwise :: Pos -> Pos -> [LinearVec RankwiseDirection]
fromToRankwise (a, b) (c, d)
  | b == d = maybeToList (fromToRanks (a,c))
  | opposite b == d = maybeToList $ do { t <- (case a of
                                                MostInner -> Just $ LinearVec Inwards Once
                                                a -> fromToRanks (a,MostInner));
                                         o <- fromToRanks (MostInner,c);
                                         return $ LinearVec Inwards (addCount (count t) (count o)) }
  | otherwise = []
fromToFilesWards :: FilewiseDirection -> File -> File -> Maybe Count
fromToFilesWards w a b | a==b = Nothing
  | otherwise = let wf = filewiseInc w in
  let c = wf a in
    if c==b then Just Once
    else OnceMore <$> fromToFilesWards w c b
fromToFiles :: (File, File) -> Maybe (LinearVec FilewiseDirection, LinearVec FilewiseDirection)
fromToFiles (a,b) = do { p <- fromToFilesWards Pluswards a b;
                         m <- fromToFilesWards Minuswards a b;
                         return $ let { pv = LinearVec Pluswards p;
                                        mv = LinearVec Minuswards m } in
                                    if m<p then (mv,pv) else (pv,mv) }
fromToFilewise :: Pos -> Pos -> [LinearVec FilewiseDirection]
fromToFilewise (a, b) (c, d)
  | a == c = fromMaybe [] $ do { f <- fromToFiles (b,d);
                                 return [fst f, snd f] }
  | otherwise = []
-- type StraightVecsOfKinds = ([LinearVec RankwiseDirection], [LinearVec FilewiseDirection])
-- type LinearVecsOfKinds = (StraightVecsOfKinds, [LinearVec DiagonalDirection])
-- fromToStraight :: Pos -> Pos -> StraightVecsOfKinds
fromToStraight :: Pos -> Pos -> [StraightVecEBC]
fromToStraight a b = (map MkRankwiseVecEBC (fromToRankwise a b)) ++ (map MkFilewiseVecEBC (fromToFilewise a b))
-- fromToDiagWards :: DiagonalDirection -> Pos -> Pos -> Maybe Count
-- fromToDiagWards (DiagonalDirection Outwards _) (MostOuter, _) _ = Nothing
-- fromToDiagWards (DiagonalDirection Inwards w) (MostInner, a) (MostInner, b)
--   | (let f = filewiseInc w in
--        a == ((f.f.f.f.f . f.f.f.f.f) b)) = Just Once
--   | otherwise = Nothing
bothMaybe :: (Maybe a, Maybe a) -> Maybe (a, a)
bothMaybe (m, n) = do { m <- m; n <- n; return (m,n); }
mapHomoTuple2 :: (a -> b) -> (a, a) -> (b, b)
mapHomoTuple2 f (a,b) = (f a, f b)
sumCountPair :: (Count, Count) -> Count
sumCountPair = uncurry addCount
addMaybeCount :: Maybe Count -> Maybe Count -> Maybe Count
addMaybeCount Nothing a = a
addMaybeCount a Nothing = a
addMaybeCount (Just a) (Just b) = Just $ addCount a b
sumMaybeCountPair :: (Maybe Count, Maybe Count) -> Maybe Count
sumMaybeCountPair = uncurry addMaybeCount
filewiseToShortDiagonal :: LinearVec FilewiseDirection -> RankwiseDirection -> LinearVec DiagonalDirection
filewiseToShortDiagonal (LinearVec f c) r = LinearVec (DiagonalDirection r f) c
maybeIf :: (a -> Bool) -> Maybe a -> Maybe a
maybeIf f (Just v) = if f v then Just v else Nothing
maybeIf _ Nothing = Nothing
fromToFilesShort :: (File, File) -> Maybe (LinearVec FilewiseDirection)
fromToFilesShort = fmap fst . fromToFiles
fromToShortDiagonal :: Pos -> Pos -> Maybe (LinearVec DiagonalDirection)
fromToShortDiagonal a b = do
  fileDiff <- fromToFilesShort (file a, file b)
  fmap (filewiseToShortDiagonal fileDiff . direction)
    (maybeIf
      ((count fileDiff ==).count)
      (fromToRanks (rank a, rank b)))
filewiseToLongDiagonal :: LinearVec FilewiseDirection -> LinearVec DiagonalDirection
filewiseToLongDiagonal (LinearVec f fileCount) =
  LinearVec (DiagonalDirection Inwards (rever f)) (positiveSubstractCount (fromJust $ countFromPositiveInteger (5+5+1)) fileCount)
fileDistance :: (File,File) -> Maybe Count
fileDistance = fmap count . fromToFilesShort
fileCoorDistance :: (Pos,Pos) -> Maybe Count
fileCoorDistance = fileDistance . mapHomoTuple2 file
fromToCoorFilesShort :: (Pos,Pos) -> Maybe (LinearVec FilewiseDirection)
fromToCoorFilesShort = fromToFilesShort . mapHomoTuple2 file
fromToCoorRanks :: (Pos,Pos) -> Maybe (LinearVec RankwiseDirection)
fromToCoorRanks = fromToRanks. mapHomoTuple2 rank
rankDistance :: (Rank, Rank) -> Maybe Count
rankDistance = fmap count . fromToRanks
rankDistanceFromMostOuter :: Rank -> Maybe Count
rankDistanceFromMostOuter = fmap count . curry fromToRanks MostOuter
sumOfRankDistancesFromMostOuter :: (Rank, Rank) -> Maybe Count
sumOfRankDistancesFromMostOuter =
  sumMaybeCountPair . mapHomoTuple2 rankDistanceFromMostOuter
sumOfRankCoorDistancesFromMostOuter :: (Pos,Pos) -> Maybe Count
sumOfRankCoorDistancesFromMostOuter =
  sumMaybeCountPair . mapHomoTuple2 (rankDistanceFromMostOuter.rank)
isFilewiseDistanceSameAsSumOfRanksDistancesFromMostOuter :: (Pos,Pos) -> Bool
isFilewiseDistanceSameAsSumOfRanksDistancesFromMostOuter x =
  maybe False (uncurry (==)) $ bothMaybe (fileCoorDistance x, sumOfRankCoorDistancesFromMostOuter x)
fromToLongDiagonal :: Pos -> Pos -> Maybe (LinearVec DiagonalDirection)
-- fromToLongDiagonal a b = do
--   fileDiff <- fromToFilesShort (file a) (file b)
--   rankSum <- sumCountPair (mapHomoTuple2 ((fmap count).(fromToRank MostOuter).rank) (a,b))
--   if (rankSum == (count fileDiff)) then (filewiseToLongDiagonal fileDiff) else Nothing
fromToLongDiagonal a b
  | isFilewiseDistanceSameAsSumOfRanksDistancesFromMostOuter (a,b)
    = fmap filewiseToLongDiagonal (fromToCoorFilesShort (a,b))
  | otherwise = Nothing
fromToDiagonals :: Pos -> Pos -> (Maybe (LinearVec DiagonalDirection), Maybe (LinearVec DiagonalDirection))
fromToDiagonals a b = (fromToShortDiagonal a b, fromToLongDiagonal a b)
fromToDiagonal :: Pos -> Pos -> [LinearVec DiagonalDirection]
fromToDiagonal a b = let s = fromToDiagonals a b in uncurry (++) (mapHomoTuple2 maybeToList s)
fromToLinear :: Pos -> Pos -> [LinearVecEBC]
fromToLinear a b = fmap MkStraightVecEBC (fromToStraight a b) ++
                   fmap MkDiagonalVecEBC (fromToDiagonal a b)

data ShortOrLong = Short | Long
data CanIDiagonal = CanDiagonalBut ShortOrLong FilewiseDirection | CanDiagonalBoth FilewiseDirection | CannotDiagonal
