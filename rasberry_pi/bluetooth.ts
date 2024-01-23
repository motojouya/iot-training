import { Peripheral, Advertisement } from 'noble'

// const MAC_ADDRESS = 'B0:7E:11:EE:5A:08'
// const DEVICE_NAME = 'IBS-TH1'
// const INTERVAL = 1000 * 60 * 30
const noble = require('@abandonware/noble')

type Send = (temperature: number, humidity: number, datetime: Date) => void;

export const scan = (macAddress: string, send: Send) => {
  noble.on('scanStart', () => { console.log('scanStart'); });
  noble.on('scanStop', () => { console.log('scanStop'); });
  noble.on('stateChange', (state: string) => {
      console.log(`state: ${state}`)
      if (state === 'poweredOn') {
          noble.startScanning([], true);
      } else {
          noble.stopScanning();
      }
  });
  noble.on('discover', async (peripheral: Peripheral) => {
      const address = peripheral.address
      console.log(`address: ${address}`)

      const advertisement: Advertisement = peripheral.advertisement
      const manufacturerData: Buffer = advertisement.manufacturerData

      if (macAddress.toLowerCase() == address.toLowerCase() && manufacturerData !== undefined) {
          const temperature = manufacturerData.readInt16LE(0) / 100;
          const humidity = manufacturerData.readInt16LE(2) / 100;
          const battery = manufacturerData[7];
          const datetime = new Date();
          console.log(`temperature: ${temperature}, humidity: ${humidity}, battery: ${battery}, datetime: ${datetime.toISOString()}`)

          try {
              await send(temperature, humidity, datetime);
          } catch (error) {
              console.log(error)
          }
          noble.stopScanning()
      }
  })
  // setInterval(() => {
  //     noble.startScanning([], true)
  // }, INTERVAL)
};

