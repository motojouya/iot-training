import { Peripheral, Advertisement } from 'noble'
import Amplify from 'aws-amplify'
import API, { graphqlOperation, GraphQLResult } from '@aws-amplify/api'
import * as Types from './API'
import { createSensor } from './graphql/mutations'
import { listSensors } from './graphql/queries'

import awsconfig from './aws-exports'
Amplify.configure(awsconfig)

const MAC_ADDRESS = 'B0:7E:11:EE:5A:08'
const DEVICE_NAME = 'IBS-TH1'
const INTERVAL = 1000 * 60 * 30
const noble = require('@abandonware/noble')

noble.on('stateChange', (state: string) => {
    console.log(`state: ${state}`)
    if (state === 'poweredOn') {
        noble.startScanning([], true)
    } else {
        noble.stopScanning()
    }
})

noble.on('scanStart', () => { console.log('scanStart') })

noble.on('scanStop', () => { console.log('scanStop') })

noble.on('discover', async (peripheral: Peripheral) => {
    const address = peripheral.address
    console.log(`address: ${address}`)

    const advertisement: Advertisement = peripheral.advertisement
    const manufacturerData: Buffer = advertisement.manufacturerData

    if (MAC_ADDRESS.toLowerCase() == address.toLowerCase() && manufacturerData !== undefined) {
        const temperature = manufacturerData.readInt16LE(0) / 100
        const humidity = manufacturerData.readInt16LE(2) / 100
        const battery = manufacturerData[7]
        const datetime = new Date().toISOString()
        console.log(`temperature: ${temperature}, humidity: ${humidity}, battery: ${battery}, datetime: ${datetime}`)

        try {
            // センサーで取得したデータをミューテーションで保存
            await mutation(MAC_ADDRESS, DEVICE_NAME, temperature, humidity, battery, datetime)
        } catch (error) {
            console.log(error)
        }
        noble.stopScanning()
    }
})

setInterval(() => {
    noble.startScanning([], true)
}, INTERVAL)

async function mutation(id: string, name: string, temperature: number, humidity: number, battery: number, datetime: string) {
    const input = {
        id: id,
        name: name,
        temperature: temperature,
        humidity: humidity,
        battery: battery,
        datetime: datetime,
    }
    const result = await API.graphql(graphqlOperation(createSensor, {input: input}))
    console.log(result)
}
