import { scan } from './bluetooth';

// make it wait as long as possible once the promise completes we'll turn it off.
// const timer = setTimeout(() => {}, 2147483647);
scan(process.argv[0], (temperature: number, humidity: number, datetime: Date) => {
    console.log({
      deviceName: 'test',
      temperature,
      humidity,
      datetime,
    });
    // clearTimeout(timer);
    process.exit(0);
});
