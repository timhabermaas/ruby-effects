m :: Maybe Int
m = do
  a <- return 12
  b <- return 12
  c <- return $ a + b
  return $ c * 2

main :: IO ()
main = putStrLn $ show m
