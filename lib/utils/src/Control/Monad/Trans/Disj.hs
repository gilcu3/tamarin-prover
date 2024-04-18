{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances #-}
-- |
-- Copyright   : (c) 2011 Simon Meier
-- License     : GPL v3 (see LICENSE)
--
-- Portability : unknown
--
-- A monad transformer to enable other *commutative* monads to represent
-- logical disjunctions.
module Control.Monad.Trans.Disj (
  -- * The 'DisjT' monad transformer
    DisjT(..)
  , disjT
  , runDisjT
  ) where

import Control.Monad
import Control.Monad.Disj.Class
import Control.Monad.Reader
import ListT


------------------------------------------------------------------------------
-- The 'DisjT' monad transformer
------------------------------------------------------------------------------

-- | A disjunction of atoms of type a.
newtype DisjT m a = DisjT { unDisjT :: ListT m a }
  deriving (Functor, Applicative, MonadTrans )

-- | Construct a 'DisjT' action.
disjT :: (Monad m, Foldable m) => m a -> DisjT m a
disjT = DisjT . fromFoldable

-- | Run a 'DisjT' action.
runDisjT :: Monad m => DisjT m a -> m [a]
runDisjT = toList . unDisjT




-- Instances
------------

instance Monad m => Monad (DisjT m) where
    {-# INLINE (>>=) #-}
    m >>= f = DisjT $ (unDisjT . f) =<< unDisjT m

instance MonadFail m => MonadFail (DisjT m) where
    -- Ensure that contradictions are not reported via fail!
    fail = error

instance Monad m => MonadDisj (DisjT m) where
    contradictoryBecause _ = DisjT mzero
    disjunction m1 m2      = DisjT $ unDisjT m1 `mplus` unDisjT m2


instance MonadReader r m => MonadReader r (DisjT m) where
    ask       = lift ask
    local f m = DisjT $ local f $ unDisjT m

