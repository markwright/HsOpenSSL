{- -*- haskell -*- -}

{-# OPTIONS_HADDOCK prune #-}

-- |An interface to X.509 certificate store.

module OpenSSL.X509.Store
    ( X509Store
    , X509_STORE -- private

    , newX509Store

    , wrapX509Store -- private
    , withX509StorePtr -- private

    , addCertToStore
    , addCRLToStore

    , X509StoreCtx
    , X509_STORE_CTX -- private

    , withX509StoreCtxPtr -- private
    , wrapX509StoreCtx -- private
    )
    where

import Control.Applicative ((<$>))
import Foreign
import Foreign.C
import Foreign.Concurrent as FC
import OpenSSL.X509
import OpenSSL.X509.Revocation
import OpenSSL.Utils

-- |@'X509Store'@ is an opaque object that represents X.509
-- certificate store. The certificate store is usually used for chain
-- verification.
newtype X509Store  = X509Store (ForeignPtr X509_STORE)
data    X509_STORE


foreign import ccall unsafe "X509_STORE_new"
        _new :: IO (Ptr X509_STORE)

foreign import ccall unsafe "X509_STORE_free"
        _free :: Ptr X509_STORE -> IO ()

foreign import ccall unsafe "X509_STORE_add_cert"
        _add_cert :: Ptr X509_STORE -> Ptr X509_ -> IO CInt

foreign import ccall unsafe "X509_STORE_add_crl"
        _add_crl :: Ptr X509_STORE -> Ptr X509_CRL -> IO CInt

-- |@'newX509Store'@ creates an empty X.509 certificate store.
newX509Store :: IO X509Store
newX509Store = _new
               >>= failIfNull
               >>= \ ptr -> wrapX509Store (_free ptr) ptr

wrapX509Store :: IO () -> Ptr X509_STORE -> IO X509Store
wrapX509Store finaliser ptr
    = do fp <- newForeignPtr_ ptr
         FC.addForeignPtrFinalizer fp finaliser
         return $ X509Store fp

withX509StorePtr :: X509Store -> (Ptr X509_STORE -> IO a) -> IO a
withX509StorePtr (X509Store store)
    = withForeignPtr store

-- |@'addCertToStore' store cert@ adds a certificate to store.
addCertToStore :: X509Store -> X509 -> IO ()
addCertToStore store cert
    = withX509StorePtr store $ \ storePtr ->
      withX509Ptr cert       $ \ certPtr  ->
      _add_cert storePtr certPtr
           >>= failIf (/= 1)
           >>  return ()

-- |@'addCRLToStore' store crl@ adds a revocation list to store.
addCRLToStore :: X509Store -> CRL -> IO ()
addCRLToStore store crl
    = withX509StorePtr store $ \ storePtr ->
      withCRLPtr crl         $ \ crlPtr   ->
      _add_crl storePtr crlPtr
           >>= failIf (/= 1)
           >>  return ()

data    X509_STORE_CTX
newtype X509StoreCtx = X509StoreCtx (ForeignPtr X509_STORE_CTX)

withX509StoreCtxPtr :: X509StoreCtx -> (Ptr X509_STORE_CTX -> IO a) -> IO a
withX509StoreCtxPtr (X509StoreCtx fp) = withForeignPtr fp

wrapX509StoreCtx :: IO () -> Ptr X509_STORE_CTX -> IO X509StoreCtx
wrapX509StoreCtx finaliser ptr =
  X509StoreCtx <$> FC.newForeignPtr ptr finaliser

