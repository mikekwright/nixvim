main :: IO ()
main = do
    putStrLn "Enter a number:"
    input <- getLine
    let number = read input :: Int
    printHello number

printHello :: Int -> IO ()
printHello n
    | n <= 0    = return ()
    | otherwise = do
        putStrLn "hello"
        printHello (n - 1)
