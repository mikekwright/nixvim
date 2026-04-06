export interface Testing {
  start(): Promise<void>;
}

class Tester implements Testing {
  async start(): Promise<void> {
    console.log("hello from the typescript sample")
  }
}

async function main(): Promise<void> {
  const tester = new Tester()
  await tester.start()
}

void main()
