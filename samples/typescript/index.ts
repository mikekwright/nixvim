export interface Testing {
  start(): Promise<void>;
}

class Tester implements Testing {
}
