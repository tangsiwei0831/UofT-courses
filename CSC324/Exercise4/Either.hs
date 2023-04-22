

let s = Left "foo" :: Either String Int
let n = Right 3 :: Either String Int

:t s
:t n

either length (*2) s
-- 3
either length (*2) n