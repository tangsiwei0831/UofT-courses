
class JSON a where
  toJSON :: a -> String

instance JSON Bool where
  toJSON True = "true" 
  toJSON False = "false"

instance JSON Integer where
  toJSON = show

instance JSON String where
  toJSON = show

instance JSON Char where
  toJSON = show

-- List a
instance {-# OVERLAPPABLE #-} JSON a => JSON [a] where
  toJSON l = "Hi" ++ (concat (map toJSON l)) ++ "HI"

toJSON "CSC324"
